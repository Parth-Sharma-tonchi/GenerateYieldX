## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Provided deploy scripts

This repo includes Solidity Forge scripts under `script/` that help deploy the contracts in `src/`.

Files:
- `script/DeployMockUSDC.s.sol` - deploys a local `MockUSDC` token (useful for local testing).
- `script/DeployStakedUSDC.s.sol` - deploys `StakedUSDC`. Respects `USDC_ADDRESS` (use existing token) and `ADMIN` / `MANAGER` env vars. If `USDC_ADDRESS` is not set it will deploy `MockUSDC` first.
- `script/DeployAaveAdapter.s.sol` - deploys `AaveV3Adapter`. Requires env vars: `STAKED_ADDRESS`, `AAVE_POOL`, `ATOKEN`, `ASSET`.
- `script/DeployCompoundAdapter.s.sol` - deploys `CompoundV3Adapter`. Requires env vars: `STAKED_ADDRESS`, `COMET`, `ASSET`.
- `script/DeployAll.s.sol` - convenience script that deploys `MockUSDC` (unless `USDC_ADDRESS` provided), `StakedUSDC`, and optionally the adapters when their env vars are set.

How to run (examples):

1) Deploy MockUSDC locally (uses PRIVATE_KEY env var):

```bash
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY
forge script script/DeployMockUSDC.s.sol:DeployMockUSDC --rpc-url http://localhost:8545 --broadcast
```

2) Deploy StakedUSDC (deploys MockUSDC if you don't supply USDC_ADDRESS):

```bash
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY
forge script script/DeployStakedUSDC.s.sol:DeployStakedUSDC --rpc-url http://localhost:8545 --broadcast
```

3) Deploy everything (if you have Aave/Comet addresses set in env, adapters will also be deployed):

```bash
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY
# Optionally set USDC_ADDRESS, AAVE_POOL, ATOKEN, COMET, ASSET, STAKED_ADDRESS, ADMIN, MANAGER
forge script script/DeployAll.s.sol:DeployAll --rpc-url http://localhost:8545 --broadcast
```

Notes:
- The scripts use `forge-std/Script.sol` and expect `PRIVATE_KEY` as an env var. They derive the deployer address from this key.
- Adapter scripts require protocol addresses (Aave pool, aToken, Comet contract) to be provided via env vars when deploying against real networks. For local testing you can deploy local/mocked protocol contracts and provide their addresses.
- After deploying adapters, call `staked.addAdapter(adapterAddress)` from the admin account to register them with the vault.


### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
