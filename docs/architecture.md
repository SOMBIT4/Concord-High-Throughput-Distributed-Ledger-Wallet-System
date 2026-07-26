# Concord — Architecture

How Concord is built. This document records the concrete technology stack and component structure that implement the domain decisions in `CONTEXT.md` and `docs/adr/`. Where a choice was load-bearing it has its own ADR; the smaller library picks are recorded here.

## Stack at a glance

| Concern | Choice | Rationale / ADR |
| --- | --- | --- |
| Language | **Go** | ADR-0009 |
| Consensus engine | **CometBFT** via **ABCI 2.0** | ADR-0001, 0002, 0009 |
| Application model | **Custom ABCI app** (no full Cosmos SDK) | ADR-0010 |
| Block execution | `FinalizeBlock` + `PrepareProposal`/`ProcessProposal` | ADR-0002, 0004 |
| State tree | **`cosmos/iavl`** (versioned) | ADR-0006 |
| KV backend | **PebbleDB** (pure Go) | IAVL nodes + CometBFT block store |
| API transport | **gRPC** + **gRPC-gateway** + server-streaming | ADR-0008 |
| Encoding | **Protobuf (proto3)**, deterministic marshal | ADR-0005 (deterministic bytes) |
| Signatures | stdlib `crypto/ed25519` | ADR-0005 |
| Address hashing | `x/crypto/blake2b` / `crypto/sha256` | ADR-0005 |
| Observability | `slog` + Prometheus + health check | on CometBFT's registry |
| Testing | stdlib `testing` + `testify`, 3 layers | unit / ABCI / multi-node e2e |
| Build & devnet | Makefile + Docker + compose 4-node | minimum `n = 3f+1`, `f=1` |

## Component structure

```
                          ┌─────────────────────────────────────────┐
   wallet clients         │              concordd (node)             │
   ┌───────────┐  gRPC    │  ┌────────────┐        ┌──────────────┐  │
   │  wallet   │◄────────►│  │  API layer │        │  CometBFT     │  │
   │  / CLI    │  REST    │  │ gRPC +     │        │  consensus,   │  │
   └───────────┘  (gw)    │  │ gateway +  │        │  P2P, mempool │  │
                          │  │ streaming  │        └──────┬───────┘  │
                          │  └─────┬──────┘   ABCI 2.0    │          │
                          │        │        (FinalizeBlock,│         │
                          │        │   Prepare/ProcessProposal)      │
                          │        ▼               ▼                 │
                          │  ┌──────────────────────────────────┐    │
                          │  │        ABCI application (app/)    │    │
                          │  │  ┌────────────┐  ┌─────────────┐  │    │
                          │  │  │ x/wallet   │  │ x/validator │  │    │
                          │  │  │ balances,  │  │ set gov,    │  │    │
                          │  │  │ nonces,fee │  │ epochs      │  │    │
                          │  │  └─────┬──────┘  └──────┬──────┘  │    │
                          │  │        └────────┬───────┘         │    │
                          │  │            store/ (IAVL)          │    │
                          │  └────────────────┬─────────────────┘    │
                          │                   ▼                      │
                          │            PebbleDB (KV)                 │
                          └─────────────────────────────────────────┘
```

CometBFT owns consensus, networking, and the base mempool. The ABCI app owns the state machine. IAVL sits over PebbleDB; the API layer is a domain-shaped front door, not raw CometBFT RPC.

## Package layout (single Go module)

```
/
├── cmd/
│   └── concordd/              # node daemon entrypoint, wiring, config
├── proto/                     # .proto definitions (tx, query, api); source of truth
├── app/                       # ABCI 2.0 application: FinalizeBlock, Prepare/ProcessProposal
├── x/
│   ├── wallet/                # account model: balances, strict sequential nonce, flat fee
│   └── validator/             # permissioned dynamic set, on-chain vote, epoch activation
├── store/                     # IAVL wiring, state root, Merkle proofs, pruning
├── crypto/                    # Ed25519 sign/verify, BLAKE2/SHA-256 address derivation
├── api/                       # gRPC services, gateway, finality subscription stream
├── client/                    # thin Go client SDK
├── genesis/                   # fixed-supply genesis allocation + validator set
├── test/                      # multi-node e2e harness
├── Makefile
├── Dockerfile
└── docker-compose.yml         # 4-validator local devnet
```

Package boundaries mirror the ADRs: `x/wallet` = ADR-0004/0007, `x/validator` = ADR-0003, `store` = ADR-0006, `crypto` = ADR-0005, `api` = ADR-0008.

## Transaction lifecycle

1. **Submit** — client signs a tx (Ed25519, deterministic Protobuf bytes) and sends it via gRPC to a node's API layer, which hands it to the CometBFT mempool.
2. **Mempool** — CheckTx validates signature, sender balance ≥ fee, and nonce = `last_applied + 1`; future-nonce txs are held (TTL + per-sender cap), not rejected (ADR-0004).
3. **Propose** — the proposer builds a block via `PrepareProposal`, ordering eligible txs round-robin across senders (nonce order preserved within a sender), suppressing empty blocks (ADR-0002/0004). Other validators check it in `ProcessProposal`.
4. **Commit** — on `2f + 1` votes CometBFT commits; the block carries the concatenated Ed25519 commit certificate (ADR-0005). Finality is immediate (ADR-0002).
5. **Apply** — `FinalizeBlock` runs each tx against the state machine: debit sender (amount + fee), credit recipient, credit proposer the fee, bump nonce. The new IAVL **state root** goes in the block header (ADR-0006).
6. **Notify** — the API layer pushes finality to subscribed clients; balance/nonce queries return values with a Merkle proof against the state root (ADR-0008).

## Validator-set changes

Validator add/remove is an on-chain tx requiring a `2f + 1` vote (ADR-0003). The tally lives in `x/validator`; when a vote passes, the change is recorded but **activated only at the next epoch boundary** — surfaced to CometBFT as a validator update at that boundary, so `n`/`f`/quorum never shift mid-round.

## Determinism (a first-class constraint)

All validators must derive byte-identical signed bytes and an identical state root from the same inputs, or consensus halts. Enforced by: deterministic Protobuf marshaling (ADR-0005), a sorted IAVL tree with an insertion-order-independent root (ADR-0006), and deterministic tx ordering fixed at `PrepareProposal`. Determinism has dedicated tests (see below).

## Observability

`slog` structured logs; Prometheus metrics registered alongside CometBFT's native metrics (tx throughput, mempool depth, finality latency, epoch transitions); an HTTP health/readiness endpoint. OpenTelemetry tracing is deferred until a distributed-debugging need appears.

## Testing layers

1. **Unit** — state machine (`x/wallet`, `x/validator`), `crypto`, `store` proofs.
2. **ABCI** — drive the app through `FinalizeBlock`/`PrepareProposal` deterministically, no networking; includes state-root determinism assertions.
3. **Multi-node e2e** — the docker-compose 4-node devnet exercises real BFT consensus, epoch validator changes, and finality.
