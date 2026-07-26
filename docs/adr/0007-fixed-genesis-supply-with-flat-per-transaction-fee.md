# Fixed genesis supply with a flat per-transaction fee

The entire token supply is minted at genesis into initial wallets; there is no minting afterward. This is the simplest monetary model — no inflation logic and no mint-authority attack surface — and all later activity merely moves existing tokens. Each transaction pays a flat fee, deducted from the sender's balance and paid to the block proposer, which serves as anti-spam and a validator incentive while redistributing (never creating) tokens.

## Considered Options

- **Governance-minted supply** — rejected; even though validator governance exists (see ADR-0003), minting adds an inflation and abuse surface Concord does not need.
- **Mint-authority key** — rejected as a single point of trust and failure.
- **Gas-metered fees** — rejected as overkill for pure value transfer with no programmable execution.
