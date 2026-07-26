# Ed25519 signatures everywhere with concatenated commit certificates

All signatures — user transactions and validator consensus votes — use Ed25519, chosen for fast (batchable) verification, deterministic 64-byte signatures, and consistency with the address scheme (a wallet address is the BLAKE2/SHA-256 hash of its Ed25519 public key). BLS was considered specifically to aggregate validator votes into one signature but rejected to keep a single curve and avoid slower single-signature verification. Because Ed25519 is not aggregatable, a committed block carries its proof of `2f + 1` approval as a commit certificate: the concatenated set of individual signatures plus validator IDs.

## Consequences

- Commit certificates are `O(n)` in the validator-set size; acceptable because the set is permissioned and bounded (see ADR-0003).
- Public keys are revealed only on a wallet's first spend, since the address commits to the key hash.
