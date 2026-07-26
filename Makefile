BINARY := concordd
PKG := ./cmd/concordd
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS := -X main.version=$(VERSION)

.PHONY: build test lint proto devnet clean

build: ## Build the concordd binary
	go build -ldflags "$(LDFLAGS)" -o bin/$(BINARY) $(PKG)

test: ## Run all tests
	go test ./...

lint: ## Vet and format-check
	go vet ./...
	gofmt -l .

proto: ## Generate code from .proto files (added in Phase 1)
	@echo "proto generation lands in Phase 1"

devnet: ## Start the local 4-node devnet (added in Phase 6)
	@echo "devnet lands in Phase 6"

clean: ## Remove build artifacts
	rm -rf bin/
