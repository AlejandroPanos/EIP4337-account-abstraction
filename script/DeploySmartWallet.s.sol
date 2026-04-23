// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {SmartWallet} from "src/SmartWallet.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract DeploySmartWallet is Script {
    /* Instantiate contracts */
    HelperConfig helperConfig;
    SmartWallet smartWallet;

    /* State variables */
    address entryPoint;
    address account;

    /* Run function */
    function run() external returns (HelperConfig, SmartWallet) {
        helperConfig = new HelperConfig();
        (entryPoint, account) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        smartWallet = new SmartWallet(IEntryPoint(entryPoint));
        smartWallet.transferOwnership(account);
        vm.stopBroadcast();

        return (helperConfig, smartWallet);
    }
}
