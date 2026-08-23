// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {ERC20PermitToken} from "../src/ERC20PermitToken.sol";

/// @title Deploy
/// @notice Foundry deployment script for ERC20PermitToken.
/// @dev Placeholder script for Phase 0 bootstrap.
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        new ERC20PermitToken();
        vm.stopBroadcast();
    }
}
