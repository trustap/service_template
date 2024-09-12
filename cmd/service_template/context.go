// Copyright 2024 Trustap. All rights reserved.
// Use of this source code is governed by an MIT
// licence that can be found in the LICENCE file.

package main

import (
	"4d63.com/optional"
)

func newGlobalContext(config *config) *globalContext {
	greetingExtra := optional.Empty[string]()
	if e := config.Greeting.Extra; e != nil && *e != "" {
		greetingExtra = optional.OfPtr(e)
	}

	return &globalContext{
		GreetingMessage: config.Greeting.Message,
		GreetingExtra:   greetingExtra,
	}
}

type globalContext struct {
	GreetingMessage string
	GreetingExtra   optional.Optional[string]
}
