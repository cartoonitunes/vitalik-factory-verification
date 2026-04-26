# Vitalik Moose Factory Verification

Byte-for-byte bytecode verification for `0x42dd263af905666eff278d9c9602478407351457`.

| Field | Value |
|---|---|
| Contract | `0x42dd263af905666eff278d9c9602478407351457` |
| Network | Ethereum Mainnet |
| Block | 2,284,575 |
| Deployed | September 19, 2016 |
| Deployer | `0x1db3439a222c519ab44bb1144fc28167b4fa6ee6` (Vitalik Buterin dev address) |
| Compiler | Serpent 2.0.7 (`serpent-compiler` / `ethereum_serpent-2.0.7`) |
| Optimizer | N/A |
| Runtime match | ✅ EXACT (293 bytes, after stripping 4 trailing dead bytes) |

## Verification

```bash
# Requires Docker with the serpent-compiler (Serpent 2.0.7) image built locally
./verify.sh
```

## Note on Trailing Dead Bytes

Serpent 2.0.7 appends 4 dead bytes (`5b6000f3` = JUMPDEST, PUSH1 0, RETURN) to every compiled output. The deployer stripped these before deploying, a common practice to save gas. The verify script accounts for this: `compiled_runtime[:-4]` matches on-chain exactly.

## Building the Compiler

```bash
git clone https://github.com/ethereum/serpent
cd serpent
git checkout v2.0.7
pip install .
# Or build via Docker with the serpent-compiler Dockerfile
```

## What This Contract Does

A CREATE factory contract that tests EVM CREATE mechanics and pre-computed deployment addresses.

1. Computes the pre-deployment address of a child contract using `RLP([self, 0])` (pre-Spurious Dragon address derivation)
2. Checks the predicted address currently has no code (`extcodesize == 0`)
3. Deploys a child contract (`moose.se`) via `create()`
4. Calls `moose()` on the deployed child to verify it works
5. Validates both conditions with `invalid()` on failure
6. Emits a `Lol` event logging the extcodesize result and `moose()` return value

The child `moose.se` returns `extcodesize(self) * codesize()` — the product of its own runtime size and init code size — serving as a deployment sanity check.

This was Vitalik's exploration of factory patterns, pre-computed CREATE addresses, and external call verification in September 2016.

## Source Files

- **`factory.se`**: The outer factory contract (compiled with Serpent 2.0.7)
- **`moose.se`**: The child contract (embedded as inline init code within factory.se)
