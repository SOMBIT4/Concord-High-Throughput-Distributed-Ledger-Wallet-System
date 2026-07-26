# Concord

A high-throughput, permissioned distributed ledger for wallet-to-wallet value
transfer. Nodes validate transactions, order them through BFT consensus, and
maintain consistent wallet balances to prevent double-spending.

## Documentation

- **[CONTEXT.md](./CONTEXT.md)** — domain glossary
- **[docs/architecture.md](./docs/architecture.md)** — stack, components, package layout
- **[docs/roadmap.md](./docs/roadmap.md)** — phased build plan
- **[docs/adr/](./docs/adr/)** — architecture decision records

## Stack

Go · CometBFT (ABCI 2.0) · IAVL over PebbleDB · gRPC · Ed25519 · Protobuf.
See [docs/architecture.md](./docs/architecture.md) for the full rationale.

## Build

```sh
make build     # produces bin/concordd
make test      # run tests
./bin/concordd version
```

## Status

Under active construction. Progress is tracked as GitHub issues, one per
roadmap phase — see the [roadmap tracking issue](../../issues/10).
