# SmartWallet — ERC-4337 Account Abstraction

A minimal ERC-4337 compliant smart contract wallet on Ethereum. Instead of signing regular transactions, users submit signed UserOperations to the EntryPoint contract which validates signatures and executes arbitrary calls on their behalf. Includes a PackedUserOperation signing script and a Foundry test suite covering signature validation, execution access control, and fuzz testing.

---

## What It Does

- Implements the ERC-4337 `IAccount` interface — the standard interface every smart contract wallet must implement to work with the EntryPoint
- Validates ECDSA signatures on UserOperations and returns a success or failure magic value to the EntryPoint
- Executes arbitrary calls to any contract on behalf of the owner, callable by either the EntryPoint or the owner directly
- Pays gas prefunds to the EntryPoint from its own ETH balance so the wallet covers its own execution costs
- Restricts all sensitive operations behind access control modifiers — only the EntryPoint can call `validateUserOp` and only the EntryPoint or owner can call `execute`
- Includes a `SendPackedUserOp` script that generates, signs, and returns a fully assembled `PackedUserOperation` ready for submission to `handleOps`

---

## Project Structure

```
.
├── src/
│   └── SmartWallet.sol                 # ERC-4337 smart contract wallet
├── script/
│   ├── DeploySmartWallet.s.sol         # Deploys SmartWallet and transfers ownership
│   ├── HelperConfig.s.sol              # Network configuration for Anvil and Sepolia
│   └── SendPackedUserOp.s.sol          # Generates and signs PackedUserOperations
└── test/
    └── unit/
        └── SmartWalletTest.t.sol       # Unit and fuzz tests
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- [account-abstraction](https://github.com/eth-infinitism/account-abstraction) library installed

### Install dependencies and build

```bash
forge install
forge build
```

### Run all tests

```bash
forge test
```

### Run tests with verbose output

```bash
forge test -vvvv
```

### Deploy to a local Anvil chain

In one terminal, start Anvil:

```bash
anvil
```

In another terminal:

```bash
forge script script/DeploySmartWallet.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast
```

### Deploy to Sepolia

```bash
forge script script/DeploySmartWallet.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## Contract Overview

### SmartWallet

Implements `IAccount` from the ERC-4337 account-abstraction library and `Ownable` from OpenZeppelin.

| Variable       | Type          | Description                                              |
| -------------- | ------------- | -------------------------------------------------------- |
| `i_entryPoint` | `IEntryPoint` | The ERC-4337 EntryPoint contract for the current network |

| Function                                                | Visibility | Description                                                                      |
| ------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------- |
| `validateUserOp(PackedUserOperation, bytes32, uint256)` | `external` | Validates the UserOperation signature and pays the gas prefund. EntryPoint only. |
| `execute(address, uint256, bytes)`                      | `external` | Executes an arbitrary call on any contract. EntryPoint or owner only.            |

| Modifier                       | Description                                                   |
| ------------------------------ | ------------------------------------------------------------- |
| `requireFromEntryPoint`        | Reverts if the caller is not the EntryPoint                   |
| `requireFromEntryPointOrOwner` | Reverts if the caller is neither the EntryPoint nor the owner |

| Error                                     | When It Triggers                                |
| ----------------------------------------- | ----------------------------------------------- |
| `SmartWallet__NotFromEntryPoint()`        | A non-EntryPoint address calls `validateUserOp` |
| `SmartWallet__NotFromEntryPointOrOwner()` | An unauthorised address calls `execute`         |
| `SmartWallet__ExecutionFailed()`          | The low-level call in `execute` reverts         |

---

## ERC-4337 Execution Flow

```
1. User signs a UserOperation off-chain with their private key

2. Bundler submits the UserOperation to EntryPoint.handleOps()

3. EntryPoint calls SmartWallet.validateUserOp()
   - Recovers the signer from the EIP-191 signed message hash
   - Returns SIG_VALIDATION_SUCCESS or SIG_VALIDATION_FAILED
   - Pays the gas prefund from the wallet's ETH balance

4. EntryPoint calls SmartWallet.execute()
   - Executes the intended call on the destination contract
   - Reverts with SmartWallet__ExecutionFailed if the call fails
```

---

## PackedUserOperation Structure

ERC-4337 uses a `PackedUserOperation` struct that packs gas parameters into `bytes32` fields to reduce calldata costs.

| Field                | Description                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------------- |
| `sender`             | The smart wallet address submitting the operation                                           |
| `nonce`              | The ERC-4337 nonce managed by the EntryPoint (separate from the Ethereum transaction nonce) |
| `initCode`           | Bytecode to deploy the wallet if it does not exist yet (empty for existing wallets)         |
| `callData`           | The encoded function call to execute                                                        |
| `accountGasLimits`   | `verificationGasLimit` and `callGasLimit` packed into a single `bytes32`                    |
| `preVerificationGas` | Gas overhead for bundler pre-verification                                                   |
| `gasFees`            | `maxPriorityFeePerGas` and `maxFeePerGas` packed into a single `bytes32`                    |
| `paymasterAndData`   | Paymaster address and data (empty if the wallet pays its own gas)                           |
| `signature`          | ECDSA signature over the UserOperation hash                                                 |

---

## SendPackedUserOp Script

A Foundry script that generates a fully signed `PackedUserOperation` ready for submission.

```
1. Reads the current ERC-4337 nonce from the EntryPoint
2. Assembles an unsigned PackedUserOperation with the provided calldata
3. Gets the UserOperation hash from the EntryPoint
4. Signs the EIP-191 hash of the UserOperation hash
5. Returns the complete signed PackedUserOperation
```

On Anvil it signs with the default Anvil private key. On Sepolia it signs with the configured account key.

---

## Supported Networks

| Network       | Chain ID | EntryPoint                                 |
| ------------- | -------- | ------------------------------------------ |
| Anvil (local) | 31337    | Deployed fresh via mock                    |
| Sepolia       | 11155111 | 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789 |

---

## Tests

| Test                                                | What It Checks                                                                                                    |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `testOwnerCanExecute`                               | Owner can call execute() directly to mint tokens                                                                  |
| `testNonOwnerCannotExecute`                         | Non-owner calling execute() reverts with the correct error                                                        |
| `testEntryPointCanExecuteViaHandleOps`              | Full end-to-end flow through EntryPoint.handleOps() executes correctly                                            |
| `testWalletCanReceive`                              | Wallet can receive ETH via the receive function                                                                   |
| `testValidateUserOpReturnsSuccessForValidSignature` | validateUserOp returns SIG_VALIDATION_SUCCESS for a correctly signed operation                                    |
| `testValidateUserOpRevertsIfCallerIsNotEntryPoint`  | validateUserOp reverts when called by a non-EntryPoint address                                                    |
| `testFuzz_ValidateUserOpWithRandomKey`              | Signature validation returns success only for the owner's key and failure for all other keys across random inputs |

---

## Security Properties

- Only the EntryPoint can call `validateUserOp` — enforced by `requireFromEntryPoint` modifier
- Only the EntryPoint or the owner can call `execute` — enforced by `requireFromEntryPointOrOwner` modifier
- Signature validation uses EIP-191 signed message hashing to prevent signature reuse across different contexts
- The wallet can receive ETH via `receive` and `fallback` to maintain a prefund balance for gas payments
- Ownership is transferred to the configured account immediately after deployment — the deployer retains no control

---

## Dependencies

- [eth-infinitism/account-abstraction](https://github.com/eth-infinitism/account-abstraction) — IAccount, IEntryPoint, PackedUserOperation, EntryPoint, Helpers
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) — Ownable, ECDSA, MessageHashUtils

---

## License

MIT
