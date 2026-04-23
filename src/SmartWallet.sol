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

    /* State variables */
    IEntryPoint private immutable i_entryPoint;

    /* Modifiers */
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert SmartWallet__NotFromEntryPoint();
            _;
        }
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert SmartWallet__NotFromEntryPointOrOwner();
            _;
        }
    }

    /* Constructor */
    constructor(IEntryPoint _entryPoint) Ownable(msg.sender) {
        i_entryPoint = _entryPoint;
    }
}
