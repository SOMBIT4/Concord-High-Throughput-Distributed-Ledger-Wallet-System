# Permissioned dynamic validator set with epoch-boundary changes

The validator set is permissioned but dynamic: validators join or leave via an on-chain vote requiring a `2f + 1` quorum of existing validators, keeping every membership change auditable on the ledger with no out-of-band admin key. A voted change commits in one block but activates only at the next epoch boundary, not the next block. Deferring to an epoch boundary gives every validator a single deterministic switchover point, so `n`, `f`, and the quorum threshold never shift mid-round and split BFT safety.

## Considered Options

- **Admin key** for set changes — rejected as a single point of failure and not auditable on-ledger.
- **Immediate (next-block) activation** — rejected because it races the quorum math against in-flight consensus rounds.
- **Stake-based join/slash** — rejected as it drags in token economics Concord does not otherwise need (supply is fixed, see ADR-0007).
