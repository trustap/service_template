// Copyright 2024 Trustap. All rights reserved.
// Use of this source code is governed by an MIT
// licence that can be found in the LICENCE file.

package main

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// NOTE `config` and its substructures must not be exported. Endpoints that
// require values from it should have those values injected through
// request-local context objects.
type config struct {
	Greeting struct {
		Message string  `json:"message"`
		Extra   *string `json:"extra"`
	} `json:"greeting"`
}

func readConfig(path string) (*config, error) {
	rawConfig, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("couldn't read file: %w", err)
	}

	config := &config{}
	err = yaml.Unmarshal(rawConfig, config)
	if err != nil {
		return nil, fmt.Errorf("couldn't parse YAML: %w", err)
	}

	return config, nil
}
