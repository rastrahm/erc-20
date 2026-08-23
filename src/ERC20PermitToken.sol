// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";

/// @title ERC20PermitToken
/// @notice Token ERC-20 con soporte EIP-2612 permit para aprobaciones gasless.
/// @dev Fase 4: optimizaciones de gas documentadas sin comprometer seguridad.
contract ERC20PermitToken is IERC20, IERC20Permit {
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

    // ============ Constants ============

    /// @dev Typehash EIP-712 del struct Permit según EIP-2612.
    /// @dev Inlined en compile-time; evita recalcular el keccak256 en runtime.
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @dev Typehash del domain EIP-712 precalculado para `_computeDomainSeparator`.
    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @dev Hash de la versión "1" del domain; constante para ahorrar keccak en forks.
    bytes32 private constant _VERSION_HASH = keccak256("1");

    /// @dev Mitad del orden secp256k1 para rechazar firmas malleables (EIP-2).
    uint256 private constant _SECP256K1_HALF_ORDER =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    // ============ State Variables ============

    mapping(address account => uint256 balance) private _balances;
    mapping(address owner => mapping(address spender => uint256 allowance)) private _allowances;
    mapping(address owner => uint256 nonce) private _nonces;

    uint256 private _totalSupply;

    /// @notice Nombre legible del token.
    string public name;

    /// @notice Símbolo abreviado del token.
    string public symbol;

    /// @notice Decimales del token; `immutable` evita SLOAD en cada lectura (~2100 gas vs ~100).
    uint8 public immutable decimals;

    /// @notice Chain ID de deploy; `immutable` permite comparación barata en `DOMAIN_SEPARATOR`.
    uint256 public immutable INITIAL_CHAIN_ID;

    /// @notice Domain separator precalculado; evita recomputar keccak256 en la chain de deploy.
    bytes32 public immutable INITIAL_DOMAIN_SEPARATOR;

    /// @notice Hash keccak256 del nombre; `immutable` evita releer `string storage` en forks.
    bytes32 private immutable _NAME_HASH;

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
        _NAME_HASH = keccak256(bytes(name_));
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _buildDomainSeparator(block.chainid);
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

    /// @inheritdoc IERC20Permit
    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    /// @inheritdoc IERC20Permit
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
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

    /// @inheritdoc IERC20Permit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) revert PermitExpired();
        if (uint256(s) > _SECP256K1_HALF_ORDER) revert InvalidSignature();

        uint256 nonce = _nonces[owner];

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered != owner || recovered == address(0)) revert InvalidSignature();

        unchecked {
            _nonces[owner] = nonce + 1;
        }

        _approve(owner, spender, value);
    }

    // ============ Internal Functions ============

    /// @dev Transfiere tokens con CEI; `unchecked` en balances tras validar underflow explícito.
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
            // Safe: suma acotada por _totalSupply; no overflow uint256.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /// @dev Acuña tokens; `unchecked` seguro porque `_totalSupply` acota balances agregados.
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

    /// @dev Establece allowance con guards de zero-address.
    /// @param owner Titular de los tokens.
    /// @param spender Dirección autorizada.
    /// @param amount Nuevo límite de allowance.
    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev Consume allowance; omite decremento si allowance == type(uint256).max (~5000 gas ahorrados).
    /// @param owner Titular de los tokens.
    /// @param spender Dirección que gasta la allowance.
    /// @param amount Cantidad a descontar de la allowance.
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance == type(uint256).max) return;

        if (currentAllowance < amount) revert InsufficientAllowance();

        unchecked {
            _allowances[owner][spender] = currentAllowance - amount;
        }
    }

    /// @dev Retorna separator inmutable en chain de deploy; recomputa solo en forks (ruta fría).
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _buildDomainSeparator(block.chainid);
    }

    /// @dev Construye domain separator con `_NAME_HASH` immutable y typehashes constantes.
    /// @param chainId Chain ID activo para el encoding EIP-712.
    function _buildDomainSeparator(uint256 chainId) internal view returns (bytes32) {
        return keccak256(
            abi.encode(_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, chainId, address(this))
        );
    }

    /// @dev Digest EIP-712 `\x19\x01`; `encodePacked` es más barato que `encode` para prefijo fijo.
    /// @param structHash Hash del struct Permit codificado.
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), structHash));
    }
}
