# Account-based accounting with strict sequential nonces

Each wallet is an address with a running balance and nonce (account-based), rather than a set of unspent outputs (UTXO). Account-based gives simple balance queries and straightforward wallet UX for pure value transfer; UTXO's better parallelism was not worth its harder balance reads. Transaction ordering per sender is enforced by a strict sequential nonce (`nonce = last_applied + 1`), which prevents replay and makes ordering deterministic.

## Consequences

- A single sender has at most one applicable transaction at a time; a future-nonce transaction is held in the mempool until its gap fills rather than rejected, so clients avoid resubmission round-trips.
- Held transactions are bounded by a TTL and a per-sender cap to prevent a flood of never-appliable high-nonce transactions from exhausting mempool memory.
- Because nonce order within a sender is absolute, fees cannot reorder a sender's own transactions; cross-sender mempool ordering is round-robin, so the flat fee (see ADR-0006) is pure anti-spam, not a priority auction.
