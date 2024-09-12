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

	service_template_http "github.com/trustap/service_template/pkg/http"
)

func main() {
	setupLogger := log.New(os.Stdout, "default: ", log.Lshortfile)

	setupLogger.Print("starting")

	argv := os.Args
	if len(argv) != 3 {
		msg := "usage: %s <config-yaml> <listen-addr>"
		setupLogger.Printf(msg, argv[0])
		os.Exit(1)
	}
	configYamlPath := argv[1]
	listenAddr := argv[2]

	err := run(setupLogger, configYamlPath, listenAddr)
	if err != nil {
		setupLogger.Printf("command failed: %v", err)
		os.Exit(1)
	}
}

func run(
	setupLogger *log.Logger,
	configYamlPath string,
	listenAddr string,
) error {
	config, err := readConfig(configYamlPath)
	if err != nil {
		msg := "couldn't read configuration at '%s': %w"
		return fmt.Errorf(msg, configYamlPath, err)
	}

	globalCtx := newGlobalContext(config)

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
			body := map[string]any{
				"greeting": config.Greeting.Message,
			}

			extra, ok := globalCtx.GreetingExtra.Get()
			if ok {
				body["extra"] = extra
			}

			err := json.NewEncoder(w).Encode(body)
			if err != nil {
				log.Printf("couldn't send response: %v", err)
			}
		}),
	)

	server := &http.Server{Addr: listenAddr, Handler: mux}

	setupLogger.Printf("listening on '%s'", listenAddr)
	err = service_template_http.ListenAndServe(server, 3*time.Second)
	if err != nil {
		return fmt.Errorf("listening failed: %w", err)
	}
	setupLogger.Printf("shutdown finished gracefully")

	return nil
}
