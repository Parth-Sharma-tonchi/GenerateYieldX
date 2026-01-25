# StakedUSDC - Protocol & Test Guide

This small guide explains the simplified `StakedUSDC` vault in `src/` and how to run the unit tests.

## What the vault does (simplified)

- Implements an ERC4626 wrapper around a USDC-like token.
- Allows users to deposit and receive shares.
- Withdrawals can either be paid immediately if the vault has `totalAvailableForWithdrawals`, or queued as a withdrawal request when funds are not available.
- A mandatory withdrawal period must pass before a queued withdrawal can be claimed.
- The manager account is responsible for marking available funds (via internal matching / rebalance flows) and managing adapters.

Note: The implementation is an assignment-level simplified contract and may contain issues; tests assume the interface exists and exercise deposit/withdraw/claim flows.

## tests

Commands to run tests:

```bash
# from repo root
forge test -vv
```

### note
If compilation fails because environment is missing library remappings or dependencies, ensure the `lib/` folder contains the expected packages (OpenZeppelin, aave, comet, etc.) or adjust `foundry.toml` remappings.

