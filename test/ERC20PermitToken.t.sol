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

    // ============ Campaña A — Integridad ERC-20 (ataques defensivos) ============
    // A1–A6: cubiertos arriba (InsufficientBalance / ZeroAddress / InsufficientAllowance).

    /// @dev A7: tras gastar allowance parcial, gastar resto+1 debe revertir.
    function test_AttackA7_PartialAllowanceThenOverspend() public {
        token.approve(spender, 100 ether);

        vm.prank(spender);
        assertTrue(token.transferFrom(address(this), recipient, 40 ether));
        assertEq(token.allowance(address(this), spender), 60 ether);

        vm.prank(spender);
        vm.expectRevert(ERC20PermitToken.InsufficientAllowance.selector);
        token.transferFrom(address(this), recipient, 61 ether);
    }

    /// @dev A8: transfer a sí mismo no infla totalSupply ni crea tokens.
    function test_AttackA8_SelfTransferDoesNotInflateSupply() public {
        uint256 beforeBalance = token.balanceOf(address(this));
        uint256 amount = 50 ether;

        assertTrue(token.transfer(address(this), amount));

        assertEq(token.balanceOf(address(this)), beforeBalance);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
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

    // ============ Fuzz ERC-20 (Fase 6) ============

    function testFuzz_Transfer(uint256 amount, address to) public {
        vm.assume(to != address(0));
        amount = bound(amount, 0, token.balanceOf(address(this)));

        uint256 senderBefore = token.balanceOf(address(this));
        uint256 recipientBefore = token.balanceOf(to);

        assertTrue(token.transfer(to, amount));

        assertEq(token.balanceOf(to), recipientBefore + amount);
        assertEq(token.balanceOf(address(this)), senderBefore - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testFuzz_ApproveTransferFrom(uint256 allowanceAmount, uint256 transferAmount, address to) public {
        vm.assume(to != address(0));
        allowanceAmount = bound(allowanceAmount, 0, INITIAL_SUPPLY);
        transferAmount = bound(transferAmount, 0, allowanceAmount);

        token.approve(spender, allowanceAmount);

        vm.prank(spender);
        assertTrue(token.transferFrom(address(this), to, transferAmount));

        assertEq(token.balanceOf(to), transferAmount);
        assertEq(token.allowance(address(this), spender), allowanceAmount - transferAmount);
    }

    // ============ EIP-2612 adicional (Fase 6) ============

    function test_Permit_WrongSigner() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        uint256 wrongPrivateKey = 0xDEADBEEF;
        vm.assume(wrongPrivateKey != OWNER_PRIVATE_KEY);
        vm.assume(vm.addr(wrongPrivateKey) != owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermitWithKey(wrongPrivateKey, owner, spender, value, nonce, deadline);

        vm.expectRevert(ERC20PermitToken.InvalidSignature.selector);
        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.nonces(owner), nonce);
        assertEq(token.allowance(owner, spender), 0);
    }

    function test_Permit_RevertZeroAddressSpender() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, address(0), value, nonce, deadline);

        vm.expectRevert(ERC20PermitToken.ZeroAddress.selector);
        token.permit(owner, address(0), value, deadline, v, r, s);
    }

    /// @dev SWC-117: rechaza componente s malleable (EIP-2).
    function test_Permit_RevertMalleableSignature() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r,) = _signPermit(owner, spender, value, nonce, deadline);
        bytes32 malleableS = bytes32(uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) + 1);

        vm.expectRevert(ERC20PermitToken.InvalidSignature.selector);
        token.permit(owner, spender, value, deadline, v, r, malleableS);
    }

    function testFuzz_Permit_ValidSignature(uint256 value, uint256 deadlineOffset) public {
        deadlineOffset = bound(deadlineOffset, 1, 365 days);
        uint256 deadline = block.timestamp + deadlineOffset;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, nonce, deadline);

        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), nonce + 1);
    }

    // ============ Campaña B — Firmas EIP-2612 (ataques defensivos) ============
    // B1–B6: cubiertos arriba (válida, expired, nonce, wrong signer, malleable, spender 0).

    /// @dev B7: reutilizar la misma firma tras un permit exitoso (replay) debe fallar.
    function test_AttackB7_ReplaySameSignatureAfterSuccess() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, nonce, deadline);

        token.permit(owner, spender, value, deadline, v, r, s);
        assertEq(token.nonces(owner), nonce + 1);

        vm.expectRevert(ERC20PermitToken.InvalidSignature.selector);
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    /// @dev B8: firma válida en chainId original es inválida tras fork (domain separator distinto).
    function test_AttackB8_PermitInvalidAfterChainIdChange() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, nonce, deadline);

        vm.chainId(token.INITIAL_CHAIN_ID() + 1);

        vm.expectRevert(ERC20PermitToken.InvalidSignature.selector);
        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.nonces(owner), nonce);
        assertEq(token.allowance(owner, spender), 0);
    }

    /// @dev B9: v inválido hace que ecrecover retorne address(0) → InvalidSignature.
    function test_AttackB9_InvalidVYieldsZeroRecovered() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        (, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, nonce, deadline);
        uint8 invalidV = 0;

        vm.expectRevert(ERC20PermitToken.InvalidSignature.selector);
        token.permit(owner, spender, value, deadline, invalidV, r, s);

        assertEq(token.nonces(owner), nonce);
        assertEq(token.allowance(owner, spender), 0);
    }

    // ============ Campaña C — Orden de transacciones (SWC-114, documental) ============
    // No son fallos del contrato: el estándar ERC-20 / EIP-2612 admite este comportamiento.

    /// @dev C1: cambiar allowance de N a M sin pasar por 0 es válido on-chain (riesgo de diseño ERC-20).
    function test_AttackC1_ApproveOverwriteWithoutZeroing() public {
        token.approve(spender, 100 ether);
        assertEq(token.allowance(address(this), spender), 100 ether);

        token.approve(spender, 20 ether);
        assertEq(token.allowance(address(this), spender), 20 ether);

        vm.prank(spender);
        assertTrue(token.transferFrom(address(this), recipient, 20 ether));
        assertEq(token.allowance(address(this), spender), 0);
    }

    /// @dev C2: un relayer distinto al owner puede enviar un permit ya firmado (by design EIP-2612).
    function test_AttackC2_RelayerCanSubmitSignedPermit() public {
        address relayer = makeAddr("relayer");
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, spender, value, nonce, deadline);

        vm.prank(relayer);
        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), nonce + 1);
        assertTrue(relayer != owner);
    }

    // ============ Campaña D — Aritmética unchecked (ataques defensivos) ============
    // D2: cubierto por test_TransferFrom_InfiniteAllowance.
    // D3: cubierto por test_AttackB7_ReplaySameSignatureAfterSuccess.

    /// @dev D1: transferir el balance exacto deja al sender en 0 y no altera totalSupply.
    function test_AttackD1_ExactBalanceDrainKeepsSupply() public {
        uint256 amount = 100 ether;
        assertTrue(token.transfer(alice, amount));
        assertEq(token.balanceOf(alice), amount);

        vm.prank(alice);
        assertTrue(token.transfer(recipient, amount));

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(recipient), amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    // ============ Helpers ============

    function _signPermit(address permitOwner, address permitSpender, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        return _signPermitWithKey(OWNER_PRIVATE_KEY, permitOwner, permitSpender, value, nonce, deadline);
    }

    function _signPermitWithKey(
        uint256 privateKey,
        address permitOwner,
        address permitSpender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(token.PERMIT_TYPEHASH(), permitOwner, permitSpender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        return vm.sign(privateKey, digest);
    }
}
