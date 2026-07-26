# Concord — Build Roadmap

A phased plan to build Concord from an empty repo to a hardened multi-node ledger. Each phase is independently demonstrable and builds on the last. Phase ordering follows the dependency graph in the ADRs, not feature priority.

## Phase 0 — Scaffolding

- Initialize the single Go module and the package layout from `docs/architecture.md`.
- Makefile targets: `build`, `test`, `proto`, `lint`, `devnet`.
- Multi-stage Dockerfile producing a small `concordd` image.
- CI: build + unit tests on every push.

**Done when:** `make build` produces a `concordd` binary that starts and exits cleanly.

## Phase 1 — Protobuf & crypto foundation

- Define `proto/`: transaction, query, and API messages. Wire deterministic marshaling.
- `crypto/`: Ed25519 sign/verify; address = BLAKE2/SHA-256 of the public key (ADR-0005).
- Unit tests for signing, verification, and address derivation.

**Done when:** a transaction can be constructed, signed, serialized deterministically, and verified.

## Phase 2 — State machine & IAVL store

- `store/`: `cosmos/iavl` over PebbleDB; state root, Merkle proofs, versioned pruning (ADR-0006).
- `x/wallet/`: account model — balances, strict sequential nonce, flat-fee deduction, transfer (ADR-0004, 0007).
- `genesis/`: fixed-supply allocation into initial wallets (ADR-0007).
- Unit + determinism tests: same txs → same state root; nonce/replay edge cases.

**Done when:** applying a batch of transfers to genesis state yields a deterministic, provable state root.

## Phase 3 — ABCI application on CometBFT

- `app/`: implement ABCI 2.0 — `CheckTx` (signature, balance, nonce, mempool hold rules), `FinalizeBlock` (apply txs, credit proposer, commit root), `PrepareProposal`/`ProcessProposal` (round-robin ordering, empty-block suppression) (ADR-0002, 0004, 0009).
- Wire `cmd/concordd` to run a single-node CometBFT with this app.
- ABCI-level tests driving blocks without networking.

**Done when:** a single node produces blocks, applies transfers, and reaches single-block finality.

## Phase 4 — Validator-set governance & epochs

- `x/validator/`: on-chain add/remove vote, `2f+1` tally, epoch-boundary activation surfaced as CometBFT validator updates (ADR-0003).
- Tests for deferred activation and quorum-math safety across an epoch boundary.

**Done when:** a validator can be voted in/out and the change takes effect exactly at the next epoch, with no mid-round quorum shift.

## Phase 5 — Client API

- `api/`: gRPC services (submit tx, query balance/nonce with Merkle proof) + gRPC-gateway REST shim + server-streaming finality subscription (ADR-0008).
- `client/`: thin Go SDK.
- Integration tests: submit → finality push → proven query round-trip.

**Done when:** an external client can submit a transfer and observe its finality plus a proof-backed balance change.

## Phase 6 — Multi-node devnet & consensus validation

- `docker-compose.yml`: 4-validator devnet (`n=3f+1`, `f=1`).
- `test/`: multi-node e2e — real BFT consensus, epoch validator changes, finality under load, one-node-fault tolerance.

**Done when:** the 4-node network commits transfers, survives one faulty validator, and rotates its set across an epoch.

## Phase 7 — Storage tiers & operations

- Validator pruning (state + recent window) vs archive node (full history) modes (ADR-0008).
- Observability: `slog`, Prometheus metrics, health/readiness endpoint.
- State sync / snapshot for a new node joining from current state.

**Done when:** a pruned validator and an archive node run side by side, and a new node can join and catch up.

## Phase 8 — Hardening

- Adversarial/property tests: double-spend attempts, nonce races, malformed txs, mempool DoS (TTL + per-sender cap), equivocating validator.
- Load testing toward the high-throughput target; profile the Ed25519 verify hot path (revisit batch verify only if it dominates).
- Security review of the crypto, signing, and determinism paths.

**Done when:** the system withstands the adversarial suite and meets its throughput target with headroom.

## Dependency summary

```
P0 ─► P1 ─► P2 ─► P3 ─► P4 ─┐
                     └─► P5 ─┴─► P6 ─► P7 ─► P8
```

P5 (API) needs the app (P3) but not epochs (P4); P6 needs both. Everything after P2 depends on a deterministic state machine — the single most important correctness property (see `docs/architecture.md` § Determinism).
