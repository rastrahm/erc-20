# Class Diagram — ERC-20 Token with EIP-2612 Permit

> Versión en español: [`diagrama-de-clases-ES.md`](diagrama-de-clases-ES.md)

Model of contracts, interfaces, state and relationships of module 01 (final implementation).

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
        -bytes32 _NAME_HASH immutable
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
        -_spendAllowance(address, address, uint256) internal
        -_domainSeparator() internal view
        -_buildDomainSeparator(uint256) internal view
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

## Component Description

### Interfaces

| Interface | Responsibility |
|-----------|----------------|
| `IERC20` | Standard ERC-20 contract: balances, transfers and approvals |
| `IERC20Permit` | EIP-2612 extension: `permit()`, nonces and domain separator |

### Main State

| Variable | Type | Visibility | Notes |
|----------|------|------------|-------|
| `_balances` | `mapping(address => uint256)` | private | Balance per account |
| `_allowances` | `mapping(address => mapping(address => uint256))` | private | Delegated approvals |
| `_nonces` | `mapping(address => uint256)` | private | EIP-2612 nonces per owner |
| `_totalSupply` | `uint256` | private | Total supply in circulation |
| `_NAME_HASH` | `bytes32` | private immutable | Name hash for EIP-712 |
| `decimals` | `uint8` | immutable | Token decimals |
| `INITIAL_CHAIN_ID` | `uint256` | immutable | Chain ID at deploy time (fork safety) |
| `INITIAL_DOMAIN_SEPARATOR` | `bytes32` | immutable | Separator precomputed at deploy time |
| `PERMIT_TYPEHASH` | `bytes32` | public constant | Hash of the Permit struct |

### Key Internal Functions

| Function | Role |
|----------|------|
| `_transfer` | Core transfer logic with CEI guards |
| `_approve` | Sets allowance with zero-address guard |
| `_mint` | Initial mint in the constructor (supply to the deployer) |
| `_spendAllowance` | Consumes allowance; supports `type(uint256).max` |
| `_domainSeparator` | Returns the immutable separator or recomputes it on a fork |
| `_buildDomainSeparator` | Builds the EIP-712 domain separator |
| `_hashTypedDataV4` | Builds the EIP-712 digest for `ecrecover` |

### Relationship with Tests (Foundry)

```mermaid
classDiagram
    direction LR

    class ERC20PermitTokenTest {
        <<test contract>>
        +setUp()
        +testFuzz_Transfer()
        +testFuzz_ApproveTransferFrom()
        +testFuzz_Permit_ValidSignature()
        +test_Permit_WrongSigner()
        +26 tests total
    }

    ERC20PermitTokenTest ..> ERC20PermitToken : deploys & exercises
```
