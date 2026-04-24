// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SmartWallet} from "src/SmartWallet.sol";
import {DeploySmartWallet} from "script/DeploySmartWallet.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SmartWalletTest is Test {
    /* Library usage */
    using MessageHashUtils for bytes32;

    /* Instantiate contracts */
    HelperConfig helperConfig;
    SmartWallet smartWallet;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    /* State variables */
    uint256 private constant AMOUNT = 1e18;
    address user = makeAddr("user");

    /* Set up function */
    function setUp() external {
        DeploySmartWallet deployer = new DeploySmartWallet();
        (helperConfig, smartWallet) = deployer.run();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }
}
