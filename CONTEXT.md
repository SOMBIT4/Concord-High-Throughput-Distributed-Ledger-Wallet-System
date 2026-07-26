# Concord

A high-throughput, permissioned distributed ledger for wallet-to-wallet value transfer. Nodes validate transactions, order them through BFT consensus, and maintain consistent wallet balances to prevent double-spending.

## Language

### Ledger & Consensus

**Validator**:
A node that participates in BFT consensus — validates transactions, votes on block order, and signs commits. The validator set is permissioned and dynamic.
_Avoid_: Node (use only for non-validating participants), miner, peer.

**Validator Set**:
The current collection of validators eligible to vote in a consensus round. Membership changes only at an epoch boundary.
_Avoid_: Committee, quorum (quorum is a threshold, not the set).

**Quorum**:
The `2f + 1` signature threshold required to commit a block, where the set tolerates up to `f` Byzantine validators out of `n ≥ 3f + 1`.
_Avoid_: Majority, supermajority.

**Epoch**:
The interval between validator-set changes. Admitted or evicted validators take effect only at the next epoch boundary, giving all validators a deterministic switchover point.
_Avoid_: Era, period, term.

**Commit Certificate**:
The proof of block finality: the concatenated set of `2f + 1` Ed25519 validator signatures plus their validator IDs, stored in the block.
_Avoid_: Proof, seal, quorum certificate (abbreviated QC).

**Finality**:
The property that a committed block is irreversible. Concord has single-block deterministic finality — commit means final, with no reorganizations.
_Avoid_: Confirmation, settlement.

### Wallets & Transactions

**Wallet**:
An account holding a balance and a nonce, addressed by the hash of its Ed25519 public key. The unit of ownership on the ledger.
_Avoid_: Account (reserve for the accounting model), address (that's the identifier, not the wallet), user.

**Address**:
A wallet's identifier: the BLAKE2/SHA-256 hash of its Ed25519 public key. The public key is revealed only when the wallet first spends.
_Avoid_: Account number, wallet ID, public key (the address is derived from it).

**Balance**:
The quantity of tokens a wallet currently holds. Tracked directly per wallet under the account-based model.
_Avoid_: Funds, amount.

**Nonce**:
A strictly sequential per-wallet counter. A transaction is valid only when its nonce equals the wallet's last applied nonce plus one; this prevents replay and fixes per-sender ordering.
_Avoid_: Sequence number, counter, index.

**Transaction**:
A signed instruction to transfer tokens from one wallet to another, carrying a nonce and a flat fee.
_Avoid_: Transfer (that's the effect), payment, tx in prose (fine in code).

**Fee**:
A flat per-transaction charge deducted from the sender's balance and paid to the block proposer. Serves as anti-spam and validator incentive.
_Avoid_: Gas, cost, charge.

**Mempool**:
The pending-transaction buffer on each node before inclusion in a block. Future-nonce transactions are held here until their gap fills; entries are evicted by TTL and a per-sender cap.
_Avoid_: Queue, pool, transaction pool.

**Proposer**:
The validator that produces a given block and receives that block's transaction fees.
_Avoid_: Leader, primary, block producer.

### State & Storage

**State Tree**:
The IAVL (balanced, sorted, versioned) Merkle tree holding all wallet balances and nonces, keyed by address.
_Avoid_: Trie, database, store.

**State Root**:
The Merkle root hash of the state tree, committed in each block header. Lets any node prove a wallet's balance and lets validators agree on post-block state via a single hash.
_Avoid_: State hash, root hash.

**Archive Node**:
A node that retains full block history for audit and replay. Validators prune old blocks and keep only current state plus a recent window.
_Avoid_: Full node, history node.
