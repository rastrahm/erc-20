# Diagrama de Clases — ERC-20 Token con EIP-2612 Permit

Modelo de contratos, interfaces, estado y relaciones del módulo 01.

```mermaid
classDiagram
    direction TB

    class IERC20 {
        <<interface>>
        +totalSupply() uint256
        +balanceOf(address) uint256
        +transfer(address, uint256) bool
        +allowance(address, address) uint256
        +approve(address, uint256) bool
        +transferFrom(address, address, uint256) bool
    }

    class IERC20Permit {
        <<interface>>
        +PERMIT_TYPEHASH() bytes32
        +DOMAIN_SEPARATOR() bytes32
        +nonces(address) uint256
        +permit(address, address, uint256, uint256, uint8, bytes32, bytes32) void
    }

    class ERC20PermitToken {
        <<contract>>
        -mapping _balances
        -mapping _allowances
        -mapping _nonces
        -uint256 _totalSupply
        +string name
        +string symbol
        +uint8 decimals immutable
        +uint256 INITIAL_CHAIN_ID immutable
        +bytes32 INITIAL_DOMAIN_SEPARATOR immutable
        +bytes32 PERMIT_TYPEHASH constant
        +constructor(name, symbol, decimals, initialSupply)
        +totalSupply() uint256
        +balanceOf(address) uint256
        +transfer(address, uint256) bool
        +approve(address, uint256) bool
        +transferFrom(address, address, uint256) bool
        +allowance(address, address) uint256
        +permit(...) void
        +nonces(address) uint256
        +DOMAIN_SEPARATOR() bytes32
        -_transfer(address, address, uint256) internal
        -_approve(address, address, uint256) internal
        -_mint(address, uint256) internal
        -_computeDomainSeparator() internal view
        -_hashTypedDataV4(bytes32) internal view
    }

    class Errors {
        <<errors>>
        InsufficientBalance()
        InsufficientAllowance()
        ZeroAddress()
        InvalidSignature()
        PermitExpired()
    }

    class Events {
        <<events>>
        Transfer(from, to, value)
        Approval(owner, spender, value)
    }

    IERC20 <|.. ERC20PermitToken : implements
    IERC20Permit <|.. ERC20PermitToken : implements
    ERC20PermitToken ..> Errors : uses
    ERC20PermitToken ..> Events : emits
```

## Descripción de componentes

### Interfaces

| Interface | Responsabilidad |
|-----------|-----------------|
| `IERC20` | Contrato estándar ERC-20: balances, transferencias y aprobaciones |
| `IERC20Permit` | Extensión EIP-2612: `permit()`, nonces y domain separator |

### Estado principal

| Variable | Tipo | Visibilidad | Notas |
|----------|------|-------------|-------|
| `_balances` | `mapping(address => uint256)` | private | Saldos por cuenta |
| `_allowances` | `mapping(address => mapping(address => uint256))` | private | Aprobaciones delegadas |
| `_nonces` | `mapping(address => uint256)` | private | Nonces EIP-2612 por owner |
| `_totalSupply` | `uint256` | private | Supply total en circulación |
| `decimals` | `uint8` | immutable | Decimales del token |
| `INITIAL_CHAIN_ID` | `uint256` | immutable | Chain ID al deploy (fork safety) |
| `INITIAL_DOMAIN_SEPARATOR` | `bytes32` | immutable | Separator precalculado al deploy |
| `PERMIT_TYPEHASH` | `bytes32` | constant | Hash del struct Permit |

### Funciones internas clave

| Función | Rol |
|---------|-----|
| `_transfer` | Lógica central de transferencia con guards CEI |
| `_approve` | Establece allowance con guard de zero-address |
| `_mint` | Mint inicial en constructor (supply al deployer) |
| `_computeDomainSeparator` | Recalcula separator si cambia `chainid` |
| `_hashTypedDataV4` | Construye digest EIP-712 para `ecrecover` |

### Relación con tests (Foundry)

```mermaid
classDiagram
    direction LR

    class ERC20PermitTokenTest {
        <<test contract>>
        +setUp()
        +test_Transfer()
        +test_Approve()
        +test_TransferFrom()
        +test_Permit_ValidSignature()
        +test_Permit_ExpiredDeadline()
        +test_Permit_InvalidNonce()
        +testFuzz_Transfer(uint256, address)
    }

    ERC20PermitTokenTest ..> ERC20PermitToken : deploys & exercises
```
