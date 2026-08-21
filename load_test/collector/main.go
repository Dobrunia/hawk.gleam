package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"sync/atomic"
	"time"
)

type stats struct {
	Received int64 `json:"received"`
	Bytes    int64 `json:"bytes"`
}

func main() {
	var received int64
	var nbytes int64
	var window int64

	go func() {
		elapsed := 0
		for range time.Tick(time.Second) {
			elapsed++
			rps := atomic.SwapInt64(&window, 0)
			log.Printf("t=%ds  received=%d  rps=%d  bytes=%d", elapsed, atomic.LoadInt64(&received), rps, atomic.LoadInt64(&nbytes))
		}
	}()

	http.HandleFunc("/stats", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("content-type", "application/json")
		_ = json.NewEncoder(w).Encode(stats{
			Received: atomic.LoadInt64(&received),
			Bytes:    atomic.LoadInt64(&nbytes),
		})
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.NotFound(w, r)
			return
		}

		n, _ := io.Copy(io.Discard, r.Body)
		_ = r.Body.Close()
		atomic.AddInt64(&received, 1)
		atomic.AddInt64(&window, 1)
		atomic.AddInt64(&nbytes, n)
		w.WriteHeader(http.StatusOK)
	})

	addr := "127.0.0.1:8787"
	log.Printf("collector listening on http://%s/", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
