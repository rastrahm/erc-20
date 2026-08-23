// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20PermitToken} from "../src/ERC20PermitToken.sol";

/// @title ERC20PermitTokenTest
/// @notice Suite de tests para ERC20PermitToken.
contract ERC20PermitTokenTest is Test {
    ERC20PermitToken internal token;

    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 internal constant OWNER_PRIVATE_KEY = 0xA11CE;

    address internal owner;
    address internal spender;
    address internal alice;
    address internal recipient;

    function setUp() public {
        token = new ERC20PermitToken("Test Token", "TST", 18, INITIAL_SUPPLY);
        owner = vm.addr(OWNER_PRIVATE_KEY);
        spender = makeAddr("spender");
        alice = makeAddr("alice");
        recipient = makeAddr("recipient");
    }

    // ============ Deploy ============

    function test_Deploy() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY);
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TST");
        assertEq(token.decimals(), 18);
        assertEq(token.allowance(address(this), spender), 0);
    }

    // ============ ERC-20 positivos (Fase 5) ============

    function test_Transfer_UpdatesBalances() public {
        assertTrue(token.transfer(recipient, 100 ether));
        assertEq(token.balanceOf(recipient), 100 ether);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - 100 ether);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_Transfer_EmitsTransfer() public {
        vm.expectEmit(true, true, false, true);
        emit ERC20PermitToken.Transfer(address(this), recipient, 100 ether);
        token.transfer(recipient, 100 ether);
    }

    function test_Transfer_ZeroAmount() public {
        assertTrue(token.transfer(recipient, 0));
        assertEq(token.balanceOf(recipient), 0);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY);
    }

    function test_Approve_SetsAllowance() public {
        assertTrue(token.approve(spender, 300 ether));
        assertEq(token.allowance(address(this), spender), 300 ether);
    }

    function test_Approve_EmitsApproval() public {
        vm.expectEmit(true, true, false, true);
        emit ERC20PermitToken.Approval(address(this), spender, 300 ether);
        token.approve(spender, 300 ether);
    }

    function test_Approve_OverwriteAllowance() public {
        token.approve(spender, 100 ether);
        token.approve(spender, 200 ether);
        assertEq(token.allowance(address(this), spender), 200 ether);
    }

    function test_TransferFrom_SpendAllowance() public {
        token.approve(spender, 250 ether);

        vm.prank(spender);
        assertTrue(token.transferFrom(address(this), recipient, 250 ether));

        assertEq(token.balanceOf(recipient), 250 ether);
        assertEq(token.allowance(address(this), spender), 0);
    }

    function test_TransferFrom_EmitsTransfer() public {
        token.approve(spender, 50 ether);

        vm.prank(spender);
        vm.expectEmit(true, true, false, true);
        emit ERC20PermitToken.Transfer(address(this), recipient, 50 ether);
        token.transferFrom(address(this), recipient, 50 ether);
    }

    function test_TransferFrom_InfiniteAllowance() public {
        token.approve(spender, type(uint256).max);

        vm.prank(spender);
        token.transferFrom(address(this), recipient, 100 ether);

        assertEq(token.balanceOf(recipient), 100 ether);
        assertEq(token.allowance(address(this), spender), type(uint256).max);
    }

    // ============ ERC-20 reverts (Fase 5) ============

    function test_Transfer_RevertInsufficientBalance() public {
        vm.expectRevert(ERC20PermitToken.InsufficientBalance.selector);
        token.transfer(recipient, INITIAL_SUPPLY + 1);
    }

    function test_Transfer_RevertZeroAddressRecipient() public {
        vm.expectRevert(ERC20PermitToken.ZeroAddress.selector);
        token.transfer(address(0), 1 ether);
    }

    function test_Approve_RevertZeroAddressSpender() public {
        vm.expectRevert(ERC20PermitToken.ZeroAddress.selector);
        token.approve(address(0), 1 ether);
    }

    function test_TransferFrom_RevertInsufficientAllowance() public {
        token.approve(spender, 50 ether);

        vm.prank(spender);
        vm.expectRevert(ERC20PermitToken.InsufficientAllowance.selector);
        token.transferFrom(address(this), recipient, 100 ether);
    }

    function test_TransferFrom_RevertInsufficientBalance() public {
        token.transfer(alice, 100 ether);

        vm.prank(alice);
        token.approve(spender, 200 ether);

        vm.prank(spender);
        vm.expectRevert(ERC20PermitToken.InsufficientBalance.selector);
        token.transferFrom(alice, recipient, 200 ether);
    }

    function test_TransferFrom_RevertZeroAddressRecipient() public {
        token.approve(spender, 100 ether);

        vm.prank(spender);
        vm.expectRevert(ERC20PermitToken.ZeroAddress.selector);
        token.transferFrom(address(this), address(0), 1 ether);
    }

    // ============ EIP-2612 (Fase 3 — cubierto antes de Fase 6 fuzz) ============

    function test_Permit_ValidSignature() public {
        uint256 value = 500 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, nonce, deadline);

        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), nonce + 1);
    }

    function test_Permit_ExpiredDeadline() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp - 1;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, nonce, deadline);

        vm.expectRevert(ERC20PermitToken.PermitExpired.selector);
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    function test_Permit_InvalidNonce() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 wrongNonce = token.nonces(owner) + 1;

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, wrongNonce, deadline);

        vm.expectRevert(ERC20PermitToken.InvalidSignature.selector);
        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.nonces(owner), 0);
    }

    function test_DomainSeparator_ForkSafe() public view {
        assertEq(token.DOMAIN_SEPARATOR(), token.INITIAL_DOMAIN_SEPARATOR());
    }

    function test_DomainSeparator_ChangesOnFork() public {
        bytes32 initialSeparator = token.DOMAIN_SEPARATOR();

        vm.chainId(token.INITIAL_CHAIN_ID() + 1);
        bytes32 forkedSeparator = token.DOMAIN_SEPARATOR();

        assertTrue(initialSeparator != forkedSeparator);
    }

    // ============ Helpers ============

    function _signPermit(
        address permitOwner,
        address permitSpender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash =
            keccak256(abi.encode(token.PERMIT_TYPEHASH(), permitOwner, permitSpender, value, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        return vm.sign(OWNER_PRIVATE_KEY, digest);
    }
}
