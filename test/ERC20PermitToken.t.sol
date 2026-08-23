// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20PermitToken} from "../src/ERC20PermitToken.sol";

/// @title ERC20PermitTokenTest
/// @notice Test suite for ERC20PermitToken.
contract ERC20PermitTokenTest is Test {
    ERC20PermitToken internal token;

    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        token = new ERC20PermitToken("Test Token", "TST", 18, INITIAL_SUPPLY);
    }

    function test_Deploy() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY);
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TST");
        assertEq(token.decimals(), 18);
    }

    function test_Transfer() public {
        address recipient = makeAddr("recipient");

        assertTrue(token.transfer(recipient, 100 ether));
        assertEq(token.balanceOf(recipient), 100 ether);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - 100 ether);
    }

    function test_ApproveAndTransferFrom() public {
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");

        token.approve(spender, 250 ether);

        vm.prank(spender);
        assertTrue(token.transferFrom(address(this), recipient, 250 ether));

        assertEq(token.balanceOf(recipient), 250 ether);
        assertEq(token.allowance(address(this), spender), 0);
    }
}
