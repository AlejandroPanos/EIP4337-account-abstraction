// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract SmartWallet is IAccount, Ownable {
    /* Errors */
    error SmartWallet__NotFromEntryPoint();
    error SmartWallet__NotFromEntryPointOrOwner();
    error SmartWallet__ExecutionFailed();

    /* State variables */
    IEntryPoint private immutable i_entryPoint;

    /* Modifiers */
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert SmartWallet__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert SmartWallet__NotFromEntryPointOrOwner();
        }
        _;
    }

    /* Constructor */
    constructor(IEntryPoint _entryPoint) Ownable(msg.sender) {
        i_entryPoint = _entryPoint;
    }

    receive() external payable {}
    fallback() external payable {}

    /* Functions */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    function execute(address dest, uint256 value, bytes calldata functionData) external requireFromEntryPointOrOwner {
        (bool success, ) = dest.call{value: value}(functionData);
        if (!success) {
            revert SmartWallet__ExecutionFailed();
        }
    }

    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        } else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }
}
