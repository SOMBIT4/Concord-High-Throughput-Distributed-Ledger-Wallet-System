# Go with CometBFT and ABCI 2.0 as the platform

Concord is built in Go as a custom ABCI 2.0 application driven by CometBFT, rather than a bespoke consensus engine or another language. Every consensus decision we made — BFT with `3f + 1`, a `2f + 1` commit quorum, single-block deterministic finality, and validator-set changes at block boundaries (ADR-0001, 0002, 0003) — is exactly the model CometBFT implements, so we adopt it via ABCI and write only the application state machine. Go is chosen because it is CometBFT's native language and gives the whole supporting ecosystem (IAVL, deterministic Protobuf, Ed25519) with the least reinvention.

We use **ABCI 2.0** (CometBFT v0.38+): block execution is a single `FinalizeBlock`, and `PrepareProposal`/`ProcessProposal` give the proposer control over block contents — the hook we need to enforce round-robin-across-senders mempool ordering and empty-block suppression (ADR-0002, 0004) instead of CometBFT's default ordering.

## Considered Options

- **Custom BFT engine (HotStuff/PBFT) in Go** — rejected: months of consensus-correctness and audit risk to reproduce what CometBFT already provides.
- **Rust or C++** — rejected: more to rebuild (consensus, tree, plumbing) for no clear gain over adopting CometBFT.
- **Legacy ABCI (`BeginBlock`/`DeliverTx`/`EndBlock`)** — rejected: deprecated and lacks the proposal hooks our ordering rules need.

## Consequences

- CometBFT owns consensus, P2P networking, and the base mempool; we own the state machine behind ABCI.
- Validator keys are Ed25519 in CometBFT, aligning with our address/signature scheme (ADR-0005) for free.
- The node binary is `concordd` (daemon convention); the ABCI app is the "Concord node."
