# RPC with finality subscription; pruned validators plus archive nodes

Clients interact with any node over RPC: submit a signed transaction, query balance and nonce with a Merkle proof against the state root, and subscribe for a push notification when their transaction is committed. Given single-block deterministic finality (see ADR-0002), a subscription delivers finality in one event rather than forcing clients to poll. To keep validator storage bounded under high throughput, validators prune old blocks — retaining current IAVL state plus a recent window — while dedicated archive nodes retain full block history for audit and replay.

## Consequences

- Reads are verifiable end-to-end via Merkle proofs, so a client need not trust the responding node.
- Audit and historical replay depend on archive nodes; a deployment with no archive node keeps state but loses full history.
