package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(rw http.ResponseWriter, r *http.Request) { io.WriteString(rw, "Hello, World!") })
	mux.HandleFunc("/health", func(rw http.ResponseWriter, r *http.Request) { io.WriteString(rw, "I'm healthy") })
	err := http.ListenAndServe(fmt.Sprintf(":%s", os.Getenv("PORT")), mux)
	log.Fatal(err)
}
