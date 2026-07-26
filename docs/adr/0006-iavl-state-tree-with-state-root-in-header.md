# IAVL state tree with state root in each block header

Wallet state (balances and nonces) is stored in an IAVL tree — balanced, sorted by address, and versioned — with its Merkle root committed in every block header. A balanced sorted tree yields a deterministic root independent of insertion order (so all validators derive the same root from the same state) and supports range proofs and versioned snapshots that pair naturally with epochs and single-block finality. Merkle-Patricia was rejected as insertion-path-dependent and heavier; a plain key-value store was rejected because it offers no cryptographic state proofs.

## Consequences

- Any node can prove a wallet's balance against the header's state root, enabling light-client Merkle-proof reads over RPC (see ADR-0008).
- Validators agree on post-block state by comparing a single root hash rather than replaying and trusting full state.
- Versioned snapshots let validators prune old block history and keep only current state plus a recent window, offloading full history to archive nodes.
