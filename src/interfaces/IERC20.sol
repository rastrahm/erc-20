// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title IERC20
/// @notice Interface estándar ERC-20 según EIP-20.
/// @dev Define las funciones mínimas para transferencias y aprobaciones on-chain.
interface IERC20 {
    /// @notice Devuelve el supply total de tokens en circulación.
    /// @return El supply total del token.
    function totalSupply() external view returns (uint256);

    /// @notice Devuelve el balance de tokens de una cuenta.
    /// @param account Dirección del titular consultado.
    /// @return Cantidad de tokens que posee `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfiere tokens desde el caller hacia `to`.
    /// @param to Dirección destinataria de la transferencia.
    /// @param amount Cantidad de tokens a transferir.
    /// @return `true` si la operación fue exitosa.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Devuelve la allowance restante que `spender` puede gastar en nombre de `owner`.
    /// @param owner Titular de los tokens.
    /// @param spender Dirección autorizada para gastar.
    /// @return Cantidad de tokens aún permitidos.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Aprueba a `spender` para gastar hasta `amount` tokens del caller.
    /// @param spender Dirección autorizada.
    /// @param amount Límite de tokens aprobados.
    /// @return `true` si la operación fue exitosa.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfiere tokens de `from` hacia `to` usando la allowance del caller.
    /// @param from Titular origen de los tokens.
    /// @param to Destinatario de la transferencia.
    /// @param amount Cantidad de tokens a mover.
    /// @return `true` si la operación fue exitosa.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
