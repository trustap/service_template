// Copyright 2024 Trustap. All rights reserved.
// Use of this source code is governed by an MIT
// licence that can be found in the LICENCE file.

package main

import (
	"fmt"
	"log"
	"os"

	"4d63.com/optional"
)

func main() {
	setupLogger := log.New(os.Stdout, "default: ", log.Lshortfile)

	setupLogger.Print("starting")

	argv := os.Args
	if len(argv) != 1 {
		setupLogger.Printf("usage: %s", argv[0])
	}

	err := run(setupLogger, optional.Empty[string]())
	if err != nil {
		setupLogger.Printf("command failed: %v", err)
		os.Exit(1)
	}
}

func run(setupLogger *log.Logger, configPath optional.Optional[string]) error {
	setupLogger.Print("hello, world!")

	if configPath.IsPresent() {
		return fmt.Errorf("config path isn't supported at present")
	}

	return nil
}
