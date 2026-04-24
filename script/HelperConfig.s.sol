// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    /* State variables */
    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 public constant SEPOLIA_ID = 11155111;
    uint256 public constant LOCAL_ID = 31337;
    address public constant BURNER = 0x4E80efD8E18250aCD4B14C8e9F873985c3eD6b41;
    address public constant ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant SEPOLIA_ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    NetworkConfig public activeNetworkConfig;

    /* Constructor */
    constructor() {
        if (block.chainid == SEPOLIA_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    /* Functions */
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({entryPoint: SEPOLIA_ENTRY_POINT, account: BURNER});

        return config;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.entryPoint != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        activeNetworkConfig = NetworkConfig({entryPoint: address(entryPoint), account: ANVIL_ADDRESS});

        return activeNetworkConfig;
    }

    function getConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
