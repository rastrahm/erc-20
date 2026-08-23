// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";

/// @title ERC20PermitToken
/// @notice Token ERC-20 con soporte EIP-2612 permit para aprobaciones gasless.
/// @dev Fase 2: implementación ERC-20 core. EIP-2612 en Fase 3.
contract ERC20PermitToken is IERC20 {
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

    // ============ State Variables ============

    mapping(address account => uint256 balance) private _balances;
    mapping(address owner => mapping(address spender => uint256 allowance)) private _allowances;

    uint256 private _totalSupply;

    /// @notice Nombre legible del token.
    string public name;

    /// @notice Símbolo abreviado del token.
    string public symbol;

    /// @notice Decimales de precisión del token.
    uint8 public immutable decimals;

    // ============ Constructor ============

    /// @notice Despliega el token y acuña el supply inicial al deployer.
    /// @param name_ Nombre del token.
    /// @param symbol_ Símbolo del token.
    /// @param decimals_ Cantidad de decimales.
    /// @param initialSupply_ Supply inicial acuñado a `msg.sender`.
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _mint(msg.sender, initialSupply_);
    }

    // ============ External View Functions ============

    /// @inheritdoc IERC20
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    // ============ External Functions ============

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // ============ Internal Functions ============

    /// @dev Transfiere `amount` tokens de `from` a `to` aplicando patrón CEI.
    /// @param from Titular origen.
    /// @param to Destinatario.
    /// @param amount Cantidad a transferir.
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) revert InsufficientBalance();

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /// @dev Acuña `amount` tokens hacia `to` e incrementa `_totalSupply`.
    /// @param to Cuenta receptora del mint.
    /// @param amount Cantidad a acuñar.
    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();

        unchecked {
            _totalSupply += amount;
            _balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    /// @dev Establece la allowance de `spender` sobre los tokens de `owner`.
    /// @param owner Titular de los tokens.
    /// @param spender Dirección autorizada.
    /// @param amount Nuevo límite de allowance.
    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev Consume allowance de `spender` sobre los tokens de `owner`.
    /// @param owner Titular de los tokens.
    /// @param spender Dirección que gasta la allowance.
    /// @param amount Cantidad a descontar de la allowance.
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance < amount) revert InsufficientAllowance();

        unchecked {
            _allowances[owner][spender] = currentAllowance - amount;
        }
    }
}
