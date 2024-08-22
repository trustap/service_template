// Copyright 2024 Trustap. All rights reserved.
// Use of this source code is governed by an MIT
// licence that can be found in the LICENCE file.

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"4d63.com/optional"
	template_http "github.com/trustap/template/pkg/http"
)

func main() {
	setupLogger := log.New(os.Stdout, "default: ", log.Lshortfile)

	setupLogger.Print("starting")

	argv := os.Args
	if len(argv) != 2 {
		msg := "usage: %s <listen-addr>"
		setupLogger.Printf(msg, argv[0])
		os.Exit(1)
	}
	listenAddr := argv[1]

	err := run(setupLogger, optional.Empty[string](), listenAddr)
	if err != nil {
		setupLogger.Printf("command failed: %v", err)
		os.Exit(1)
	}
}

func run(
	setupLogger *log.Logger,
	configPath optional.Optional[string],
	listenAddr string,
) error {
	if configPath.IsPresent() {
		return fmt.Errorf("config path isn't supported at present")
	}

	mux := http.NewServeMux()

	mux.Handle(
		"/api/heartbeat",
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusNoContent)
		}),
	)

	mux.Handle(
		"/api/hello",
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			err := json.NewEncoder(w).Encode(map[string]any{
				"greeting": "Hello, world!",
			})
			if err != nil {
				log.Printf("couldn't send response: %v", err)
			}
		}),
	)

	server := &http.Server{Addr: listenAddr, Handler: mux}

	setupLogger.Printf("listening on '%s'", listenAddr)
	err := template_http.ListenAndServe(server, 3 * time.Second)
	if err != nil {
		return fmt.Errorf("listening failed: %w", err)
	}
	setupLogger.Printf("shutdown finished gracefully")

	return nil
}
