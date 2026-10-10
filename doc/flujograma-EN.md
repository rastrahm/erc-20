# Flowchart — ERC-20 Token with EIP-2612 Permit

> Versión en español: [`flujograma-ES.md`](flujograma-ES.md)

Overview of the token lifecycle and the main operations supported by the contract.

```mermaid
flowchart TD
    A([Start: Contract deploy]) --> B[Constructor: mint initial supply to the deployer]
    B --> C[Token active state]

    C --> D{Requested operation}

    D -->|transfer| E{Does from have enough balance?}
    E -->|No| E1([Revert: InsufficientBalance])
    E -->|Yes| E2{"to != zero address?"}
    E2 -->|No| E3([Revert: ZeroAddress])
    E2 -->|Yes| E4[Update balances CEI]
    E4 --> E5[Emit Transfer]
    E5 --> C

    D -->|approve| F{"spender != zero address?"}
    F -->|No| F1([Revert: ZeroAddress])
    F -->|Yes| F2[Set allowance]
    F2 --> F3[Emit Approval]
    F3 --> C

    D -->|transferFrom| G{Enough allowance?}
    G -->|No| G1([Revert: InsufficientAllowance])
    G -->|Yes| G2{Does from have balance?}
    G2 -->|No| G3([Revert: InsufficientBalance])
    G2 -->|Yes| G4[Decrement allowance and balances]
    G4 --> G5[Emit Transfer]
    G5 --> C

    D -->|permit| H{block.timestamp <= deadline?}
    H -->|No| H1([Revert: PermitExpired])
    H -->|Yes| H2[Read owner's nonce]
    H2 --> H3[Build EIP-712 digest]
    H3 --> H4[ecrecover signature]
    H4 --> H5{signer == owner?}
    H5 -->|No| H6([Revert: InvalidSignature])
    H5 -->|Yes| H7[Increment nonce]
    H7 --> H8[Set allowance]
    H8 --> H9[Emit Approval]
    H9 --> C

    D -->|query| I[balanceOf / allowance / nonces / DOMAIN_SEPARATOR]
    I --> C
```

## Legend

| Symbol | Meaning |
|--------|---------|
| Rectangle | Process / action |
| Diamond | Decision / validation |
| Stadium | Start or end point |
| CEI | Checks-Effects-Interactions (security pattern) |
