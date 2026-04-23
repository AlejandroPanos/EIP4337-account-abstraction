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
            return getSepoliaConfig();
        } else {
            return getOrCreateAnvilConfig();
        }
    }

    /* Functions */
    function getSepoliaConfig() public returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({entryPoint: SEPOLIA_ENTRY_POINT, sender: BURNER});

        return config;
    }
}
