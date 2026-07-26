# Single-block deterministic finality

Once a block reaches its `2f + 1` quorum it is committed and irreversible — there are no confirmations to wait for and no forks to reorganize. This is the primary advantage of BFT over probabilistic-finality chains and is what lets clients treat a committed transfer as settled immediately. Blocks are produced on a hybrid trigger — a fixed time interval OR a maximum transaction count, whichever fires first — with empty blocks suppressed so idle periods do not churn consensus.

## Consequences

- Clients need no N-block confirmation logic; the RPC finality subscription (see ADR-0008) fires once per committed block.
- Because commit is final, the validator set must never change mid-round — hence deferred, epoch-boundary set changes (see ADR-0003).
