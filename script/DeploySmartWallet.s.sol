// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/Helperconfig.s.sol";
import {SmartWallet} from "src/SmartWallet.sol";

contract DeploySmartWallet is Script {
    /* Instantiate contracts */
    HelperConfig helperConfig;
    SmartWallet smartWallet;

    /* State variables */
    HelperConfig.NetworkConfig private config;
    address entryPoint;
    address account;

    /* Run function */
    function run() external returns (HelperConfig, SmartWallet) {
        helperConfig = new HelperConfig();
        config = helperConfig.activeNetworkConfig();
        entryPoint = config.entryPoint;
        account = config.account;

        vm.startBroadcast();
        smartWallet = new SmartWallet(entryPoint);
        smartWallet.transferOwnership(account);
        vm.stopBroadcast();

        return (helperConfig, smartWallet);
    }
}
