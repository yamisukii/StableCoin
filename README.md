# Decentralized Stablecoin System

## Overview
This project introduces a decentralized stablecoin system, designed with simplicity and stability in mind. Our stablecoin aims to maintain a constant value of 1 token equivalent to $1. It shares similarities with DAI but with distinct features like no governance, no fees, and collateral backing exclusively in WETH and WBTC.

### Key Features
- **Exogenously Collateralized:** The stablecoin is backed by external assets.
- **Dollar Pegged:** Each token is equivalent to one US dollar.
- **Algorithmically Stable:** The system employs algorithms to maintain its dollar peg.
- **Minimalist Design:** Strives for simplicity in its implementation and operation.

### Core Contract
The core contract of this stablecoin system is pivotal in handling all critical functionalities:
- **Minting & Redeeming DSC:** Managing the issuance and redemption of stablecoins.
- **Collateral Handling:** Facilitating the deposit and withdrawal of collateral assets.
- **Inspiration:** The contract draws from the MakerDAO DSS system, with tailored modifications.

## Development Environment

### Requirements
- **Git:** Verify installation with `git --version`.
- **Foundry:** Ensure you have Foundry installed by running `forge --version`. Expected response is similar to `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`.

### Quickstart
To get started with this project, follow these steps:

1. Clone the repository:
```shell
$ git clone https://github.com/yamisukii/StableCoin
```


3. Navigate to the project directory:
```shell
$ cd StableCoin
```


4. Build the project using Foundry:
```shell
$ forge build
```
## Deployment to a Testnet or Mainnet

### Setting Up Environment Variables
Before deploying, you need to set up environment variables. These should be added to a `.env` file, similar to the provided `.env.example`.

- **`PRIVATE_KEY`**: This is your account's private key (e.g., from MetaMask). *Important:* For development, use a key that does not have any real funds associated with it.
- **`SEPOLIA_RPC_URL`**: This is the URL of the Sepolia testnet node you're using. You can get set up with one for free from Alchemy.

Optionally, you can add your `ETHERSCAN_API_KEY` if you want to verify your contract on Etherscan.

### Getting Testnet ETH
1. Visit [faucets.chain.link](https://faucets.chain.link) to obtain some testnet ETH.
2. Follow the instructions to receive ETH in your MetaMask wallet.

### Deployment Process
To deploy the contract, use the following command:

```shell
$make deploy ARGS="--network sepolia"
```
Ensure you have the necessary tools and dependencies installed before running this command. The deployment script will interact with the network specified in your .env file using the provided arguments.


## About Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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
