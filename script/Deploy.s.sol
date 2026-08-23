// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20PermitToken} from "../src/ERC20PermitToken.sol";

/// @title Deploy
/// @notice Script de despliegue de ERC20PermitToken.
/// @dev Variables de entorno opcionales:
///      - `TOKEN_NAME` (default: "ERC20 Permit Token")
///      - `TOKEN_SYMBOL` (default: "EPT")
///      - `TOKEN_DECIMALS` (default: 18)
///      - `TOKEN_INITIAL_SUPPLY` (default: 1_000_000 ether, en unidades base)
contract Deploy is Script {
    /// @notice Despliega el token y acuña el supply inicial al broadcaster.
    /// @return token Instancia desplegada de ERC20PermitToken.
    function run() external returns (ERC20PermitToken token) {
        string memory tokenName = vm.envOr("TOKEN_NAME", string("ERC20 Permit Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("EPT"));
        uint8 tokenDecimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(18)));
        uint256 initialSupply = vm.envOr("TOKEN_INITIAL_SUPPLY", uint256(1_000_000 ether));

        vm.startBroadcast();
        token = new ERC20PermitToken(tokenName, tokenSymbol, tokenDecimals, initialSupply);
        vm.stopBroadcast();

        console2.log("ERC20PermitToken deployed at:", address(token));
        console2.log("Initial supply minted to:", msg.sender);
    }
}
