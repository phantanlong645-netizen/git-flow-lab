package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

var version = "dev"

func newMux() *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		hostname, _ := os.Hostname()
		fmt.Fprintf(w, "git-flow-lab version=%s pod=%s\n", version, hostname)
	})

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	return mux
}

func main() {
	log.Println("server listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", newMux()))
}
