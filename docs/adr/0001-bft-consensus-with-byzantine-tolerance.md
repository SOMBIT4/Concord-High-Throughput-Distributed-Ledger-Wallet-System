# BFT consensus with Byzantine fault tolerance

Concord targets high throughput with deterministic finality over a permissioned validator set, so we use BFT consensus rather than Nakamoto-style PoW or open PoS. Because the ledger holds value and any validator could be adversarial, we assume the Byzantine model `n ≥ 3f + 1` with a `2f + 1` commit quorum — crash-only tolerance (`2f + 1`) was rejected as it cannot stop a compromised validator forging state.

## Consequences

- Throughput and finality scale with a known, bounded validator set — this is why the set is permissioned (see ADR-0003).
- Adding validators raises `n` and the quorum size; commit certificates grow `O(n)` (see ADR-0005).
