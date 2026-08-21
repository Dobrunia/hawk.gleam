package main

import (
	"encoding/json"
	"io"
	"log"
	"math"
	"math/rand/v2"
	"net/http"
	"os"
	"sort"
	"strconv"
	"sync"
	"sync/atomic"
	"time"
)

// Same shape as github.com/codex-team/hawk.collector pkg/server/errorshandler.
type CatcherMessage struct {
	Token       string          `json:"token"`
	Payload     json.RawMessage `json:"payload"`
	CatcherType string          `json:"catcherType"`
}

type ResponseMessage struct {
	Code    int    `json:"code"`
	Error   bool   `json:"error"`
	Message string `json:"message"`
}

const maxErrorCatcherMessageSize = 25000

// Default fake k1 RTT: median in 40–80ms, fat tail p99=200ms.
const defaultRttP50Ms = 60.0
const defaultRttP99Ms = 200.0
const rttZ99 = 2.3263478740408408
const rttMinMs = 1.0
const rttMaxMs = 2000.0

type stats struct {
	Received     int64 `json:"received"`
	Bytes        int64 `json:"bytes"`
	LatencyP50Us int64 `json:"latency_p50_us"`
	LatencyP95Us int64 `json:"latency_p95_us"`
	LatencyP99Us int64 `json:"latency_p99_us"`
}

type payloadLatency struct {
	Context struct {
		EnqueuedAtUs int64 `json:"enqueued_at_us"`
	} `json:"context"`
}

func percentile(sorted []int64, quantile float64) int64 {
	if len(sorted) == 0 {
		return 0
	}

	index := int(math.Ceil(quantile*float64(len(sorted)))) - 1
	if index < 0 {
		index = 0
	}
	return sorted[index]
}

func process(body []byte) ResponseMessage {
	message := CatcherMessage{}
	if err := json.Unmarshal(body, &message); err != nil {
		return ResponseMessage{400, true, "Invalid JSON format"}
	}
	if len(message.Payload) == 0 {
		return ResponseMessage{400, true, "Payload is empty"}
	}
	if message.Token == "" {
		return ResponseMessage{400, true, "Token is empty"}
	}
	if message.CatcherType == "" {
		return ResponseMessage{400, true, "CatcherType is empty"}
	}
	if !json.Valid(message.Payload) {
		return ResponseMessage{400, true, "Invalid payload JSON format"}
	}

	return ResponseMessage{200, false, "OK"}
}

func sendAnswerHTTP(w http.ResponseWriter, r ResponseMessage) {
	w.Header().Set("Content-Type", "text/json; charset=utf8")
	if r.Message == "" {
		return
	}

	w.WriteHeader(r.Code)
	_ = json.NewEncoder(w).Encode(r)
}

type fakeRTT struct {
	enabled bool
	mu      float64
	sigma   float64
	p50Ms   float64
	p99Ms   float64
}

func loadFakeRTT() fakeRTT {
	if os.Getenv("FAKE_RTT") == "0" {
		return fakeRTT{}
	}

	p50 := envFloat("FAKE_RTT_P50_MS", defaultRttP50Ms)
	p99 := envFloat("FAKE_RTT_P99_MS", defaultRttP99Ms)
	if p50 <= 0 || p99 <= p50 {
		p50, p99 = defaultRttP50Ms, defaultRttP99Ms
	}

	return fakeRTT{
		enabled: true,
		mu:      math.Log(p50),
		sigma:   math.Log(p99/p50) / rttZ99,
		p50Ms:   p50,
		p99Ms:   p99,
	}
}

func envFloat(key string, fallback float64) float64 {
	raw := os.Getenv(key)
	if raw == "" {
		return fallback
	}
	value, err := strconv.ParseFloat(raw, 64)
	if err != nil {
		return fallback
	}
	return value
}

func (rtt fakeRTT) sleep() {
	if !rtt.enabled {
		return
	}

	ms := math.Exp(rtt.mu + rtt.sigma*rand.NormFloat64())
	if ms < rttMinMs {
		ms = rttMinMs
	}
	if ms > rttMaxMs {
		ms = rttMaxMs
	}
	time.Sleep(time.Duration(ms * float64(time.Millisecond)))
}

func sampleLatency(body []byte) int64 {
	var message CatcherMessage
	if json.Unmarshal(body, &message) != nil {
		return 0
	}

	var payload payloadLatency
	if json.Unmarshal(message.Payload, &payload) != nil || payload.Context.EnqueuedAtUs <= 0 {
		return 0
	}

	latency := time.Now().UnixMicro() - payload.Context.EnqueuedAtUs
	if latency < 0 {
		return 0
	}

	return latency
}

func main() {
	rtt := loadFakeRTT()
	var received int64
	var nbytes int64
	var window int64
	var latencyMu sync.RWMutex
	latencies := make([]int64, 0, 10_000)

	go func() {
		elapsed := 0
		for range time.Tick(time.Second) {
			elapsed++
			rps := atomic.SwapInt64(&window, 0)
			log.Printf("t=%ds  received=%d  rps=%d  bytes=%d", elapsed, atomic.LoadInt64(&received), rps, atomic.LoadInt64(&nbytes))
		}
	}()

	mux := http.NewServeMux()

	mux.HandleFunc("/stats", func(w http.ResponseWriter, _ *http.Request) {
		latencyMu.RLock()
		samples := append([]int64(nil), latencies...)
		latencyMu.RUnlock()
		sort.Slice(samples, func(i, j int) bool { return samples[i] < samples[j] })

		w.Header().Set("content-type", "application/json")
		_ = json.NewEncoder(w).Encode(stats{
			Received:     atomic.LoadInt64(&received),
			Bytes:        atomic.LoadInt64(&nbytes),
			LatencyP50Us: percentile(samples, 0.50),
			LatencyP95Us: percentile(samples, 0.95),
			LatencyP99Us: percentile(samples, 0.99),
		})
	})

	mux.HandleFunc("/reset", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.NotFound(w, r)
			return
		}

		atomic.StoreInt64(&received, 0)
		atomic.StoreInt64(&nbytes, 0)
		atomic.StoreInt64(&window, 0)
		latencyMu.Lock()
		latencies = latencies[:0]
		latencyMu.Unlock()
		w.WriteHeader(http.StatusNoContent)
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}

		if r.ContentLength > maxErrorCatcherMessageSize {
			sendAnswerHTTP(w, ResponseMessage{400, true, "Request is too large"})
			return
		}

		r.Body = http.MaxBytesReader(w, r.Body, maxErrorCatcherMessageSize)
		body, err := io.ReadAll(r.Body)
		_ = r.Body.Close()
		if err != nil {
			sendAnswerHTTP(w, ResponseMessage{400, true, "Request is too large"})
			return
		}

		response := process(body)
		rtt.sleep()
		if response.Code == 200 {
			if latency := sampleLatency(body); latency > 0 {
				latencyMu.Lock()
				latencies = append(latencies, latency)
				latencyMu.Unlock()
			}

			atomic.AddInt64(&received, 1)
			atomic.AddInt64(&window, 1)
			atomic.AddInt64(&nbytes, int64(len(body)))
		}

		sendAnswerHTTP(w, response)
	})

	addr := "127.0.0.1:8787"
	if rtt.enabled {
		log.Printf("collector listening on http://%s/ (fake RTT lognormal p50=%.0fms p99=%.0fms)", addr, rtt.p50Ms, rtt.p99Ms)
	} else {
		log.Printf("collector listening on http://%s/ (fake RTT off)", addr)
	}
	log.Fatal(http.ListenAndServe(addr, mux))
}
