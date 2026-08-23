// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title IERC20Permit
/// @notice Extensión EIP-2612 para aprobaciones gasless mediante firmas off-chain.
/// @dev Permite establecer allowances sin enviar una transacción `approve`.
interface IERC20Permit {
    /// @notice Establece la allowance de `spender` sobre los tokens de `owner` mediante firma EIP-712.
    /// @dev Emite un evento `Approval`. Incrementa el nonce de `owner` en cada llamada exitosa.
    /// @param owner Titular que firmó la autorización off-chain.
    /// @param spender Dirección autorizada para gastar.
    /// @param value Cantidad de tokens aprobados.
    /// @param deadline Timestamp Unix límite de validez de la firma.
    /// @param v Componente de recuperación de la firma secp256k1.
    /// @param r Componente r de la firma secp256k1.
    /// @param s Componente s de la firma secp256k1.
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /// @notice Devuelve el nonce actual de `owner` para firmas EIP-2612.
    /// @dev Debe incluirse en cada typed data firmado para prevenir replay.
    /// @param owner Dirección del titular consultado.
    /// @return Nonce actual antes de la próxima llamada exitosa a `permit`.
    function nonces(address owner) external view returns (uint256);

    /// @notice Devuelve el domain separator EIP-712 usado al codificar firmas de `permit`.
    /// @dev Debe recalcularse si `block.chainid` difiere del chain ID de deploy.
    /// @return Hash del domain separator EIP-712 del token.
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
