package main

import (
	"encoding/json"
	"io"
	"log"
	"math"
	"net/http"
	"sort"
	"sync"
	"sync/atomic"
	"time"
)

type stats struct {
	Received     int64 `json:"received"`
	Bytes        int64 `json:"bytes"`
	LatencyP50Us int64 `json:"latency_p50_us"`
	LatencyP95Us int64 `json:"latency_p95_us"`
	LatencyP99Us int64 `json:"latency_p99_us"`
}

type eventEnvelope struct {
	Payload struct {
		Context struct {
			EnqueuedAtUs int64 `json:"enqueued_at_us"`
		} `json:"context"`
	} `json:"payload"`
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

func main() {
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

	http.HandleFunc("/stats", func(w http.ResponseWriter, _ *http.Request) {
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

	http.HandleFunc("/reset", func(w http.ResponseWriter, r *http.Request) {
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

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.NotFound(w, r)
			return
		}

		body, _ := io.ReadAll(r.Body)
		_ = r.Body.Close()
		var envelope eventEnvelope
		if json.Unmarshal(body, &envelope) == nil && envelope.Payload.Context.EnqueuedAtUs > 0 {
			latency := time.Now().UnixMicro() - envelope.Payload.Context.EnqueuedAtUs
			if latency >= 0 {
				latencyMu.Lock()
				latencies = append(latencies, latency)
				latencyMu.Unlock()
			}
		}

		atomic.AddInt64(&received, 1)
		atomic.AddInt64(&window, 1)
		atomic.AddInt64(&nbytes, int64(len(body)))
		w.WriteHeader(http.StatusOK)
	})

	addr := "127.0.0.1:8787"
	log.Printf("collector listening on http://%s/", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
