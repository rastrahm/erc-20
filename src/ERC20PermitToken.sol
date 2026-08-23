// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title ERC20PermitToken
/// @notice Token ERC-20 con soporte EIP-2612 permit para aprobaciones gasless.
/// @dev Fase 1: errores y eventos definidos. Implementación de interfaces en Fase 2+.
contract ERC20PermitToken {
    // ============ Errors ============

    /// @dev El balance del titular es insuficiente para la operación solicitada.
    error InsufficientBalance();

    /// @dev La allowance disponible es menor que la cantidad requerida.
    error InsufficientAllowance();

    /// @dev Se recibió la dirección cero donde está prohibida.
    error ZeroAddress();

    /// @dev La firma EIP-712 no corresponde al `owner` declarado.
    error InvalidSignature();

    /// @dev El deadline del permit ya expiró (`block.timestamp > deadline`).
    error PermitExpired();

    // ============ Events ============

    /// @dev Emitido cuando `value` tokens se mueven de `from` hacia `to`.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitido cuando se establece la allowance de `spender` sobre los tokens de `owner`.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
