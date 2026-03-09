# Tax Token Solidity Smart Contract

A Solidity smart contract implementing an ERC-20–style token with configurable transfer taxes, a factory-controlled minting model, and an optional bonding-curve mode where taxes are disabled.

## Overview

The **PumpToken** contract (in `TakToken.sol`) is a token that:

- Supports **configurable transfer fees** (in basis points, 10000 = 100%) split across:
  - **Treasury**
  - **Uniswap marketing**
  - **Uniswap development**
  - **Creator**
- Uses a **factory pattern**: only the designated `factory` address can initialize the token and mint.
- Supports a **bonding-curve mode**: when `isBondingCurve` is `true`, transfers are **tax-free**; when `false`, the above fees apply on every transfer.

## Features

| Feature | Description |
|--------|-------------|
| **ERC-20–style API** | `transfer`, `transferFrom`, `approve`, `increaseAllowance`, `decreaseAllowance`, `balanceOf`, `allowance`, `totalSupply`, `name`, `symbol`, `decimals` |
| **Tax distribution** | Fees (when not on bonding curve) go to treasury, marketing, development, and creator wallets |
| **Supply cap** | `maxSupply` enforced; minting only via `mintFromFactory` |
| **Bonding curve toggle** | `setIsBondingCurve(bool)` (factory-only) switches tax on/off for transfers |
| **Single initialization** | `initialize(...)` can only be called once |

## Contract Details

- **Solidity:** `^0.8.28`
- **License:** MIT
- **Contract name:** `PumpToken` (in `TakToken.sol`)

### Key State

- **Addresses:** `factory`, `creator`, `treasury`, `uniswapMarketingWallet`, `uniswapDevelopmentWallet`
- **Fees (basis points):** `taxFeeToTreasury`, `uniswapMarketingTaxFee`, `uniswapDevelopmentTaxFee`, `uniswapCreatorTaxFee`
- **Config:** `isBondingCurve`, `maxSupply`, `initialized`

### Access Control

- **`onlyFactory`:** `setIsBondingCurve`, `mintFromFactory`; `initialize` uses `msg.sender` as `factory`.

## Usage

1. Deploy a **factory** that will call `initialize(...)` and `mintFromFactory(...)`.
2. Deploy or create the token instance and have the factory call `initialize` with name, symbol, creator, fee wallets, treasury, fee rates (basis points), and max supply.
3. Use `mintFromFactory(to, amount)` to mint (respects `maxSupply`).
4. Use `setIsBondingCurve(false)` when leaving the bonding curve so transfer taxes apply; keep `true` for tax-free transfers.

## Verification

- **Etherscan (verified):** [0x8F657dEDA396FF99644aa70cAD87B3Cd8BDddEf1](https://etherscan.io/address/0x8F657dEDA396FF99644aa70cAD87B3Cd8BDddEf1#code)
