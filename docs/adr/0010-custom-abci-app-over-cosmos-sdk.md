# Custom ABCI app instead of the full Cosmos SDK

Concord is a lean custom ABCI application on bare CometBFT, borrowing Cosmos *libraries* à la carte (IAVL, crypto, Protobuf) rather than adopting the full Cosmos SDK. Our domain is deliberately narrow — wallet-to-wallet transfers with account+nonce, a flat fee, and a fixed genesis supply, with no smart contracts, no gas metering, and no staking token economics (ADR-0004, 0007). The full SDK brings modules we explicitly rejected and a large surface area that works against our high-throughput goal, whereas a custom state machine keeps us in exact control of block execution.

## Considered Options

- **Full Cosmos SDK** — rejected: batteries (staking, governance-as-minting, gas) we do not want, plus heavy coupling.
- **Stripped Cosmos SDK (bank-like module only)** — rejected: still SDK-coupled and versioned to the SDK's release cadence for little benefit at our scope.

## Consequences

- We implement accounts, nonces, fees, and validator-set governance ourselves as domain packages (`x/wallet`, `x/validator`).
- We depend on `cosmos/iavl` directly (ADR-0006) without the surrounding SDK store framework.
- If Concord later grows programmable transactions, this decision should be revisited — reintroducing the SDK (or a VM) would be the natural path.
