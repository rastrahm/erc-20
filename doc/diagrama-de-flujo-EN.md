# Flow Diagram — Critical Operations

> Versión en español: [`diagrama-de-flujo-ES.md`](diagrama-de-flujo-ES.md)

Detailed data and control flow for `transfer`, `transferFrom` and `permit`.

## 1. Direct transfer flow (`transfer`)

```mermaid
flowchart LR
    subgraph Input
        U[User: msg.sender]
        A[amount]
        B[recipient: to]
    end

    subgraph Validations
        V1[balanceOf msg.sender >= amount]
        V2[to != address 0]
    end

    subgraph Effects
        E1[_balances sender -= amount]
        E2[_balances to += amount]
    end

    subgraph Output
        EV[emit Transfer sender, to, amount]
        RET[return true]
    end

    U --> V1
    A --> V1
    B --> V2
    V1 --> V2
    V2 --> E1
    E1 --> E2
    E2 --> EV
    EV --> RET
```

## 2. Delegated transfer flow (`transferFrom`)

```mermaid
flowchart LR
    subgraph Input
        SP[spender: msg.sender]
        FR[from]
        TO[to]
        AM[amount]
    end

    subgraph Validations
        V1[allowance from, spender >= amount]
        V2[balanceOf from >= amount]
        V3[to != address 0]
    end

    subgraph Effects
        E1[_allowances from, spender -= amount]
        E2[_balances from -= amount]
        E3[_balances to += amount]
    end

    subgraph Output
        EV[emit Transfer]
        RET[return true]
    end

    SP --> V1
    FR --> V1
    AM --> V1
    V1 --> V2
    V2 --> V3
    V3 --> E1
    E1 --> E2
    E2 --> E3
    E3 --> EV
    EV --> RET
```

## 3. Off-chain approval flow (`permit` — EIP-2612)

```mermaid
flowchart TD
    subgraph OffChain["Off-chain (wallet / dApp)"]
        W1[User signs EIP-712 typed data]
        W2[Struct: Owner, Spender, Value, Nonce, Deadline]
    end

    subgraph OnChain["On-chain (contract)"]
        O1[permit owner, spender, value, deadline, v, r, s]
        O2{deadline >= block.timestamp?}
        O3[nonce = nonces owner]
        O4[digest = hashStruct + DOMAIN_SEPARATOR]
        O5[recovered = ecrecover digest, v, r, s]
        O6{recovered == owner?}
        O7[nonces owner++]
        O8[_allowances owner, spender = value]
        O9[emit Approval]
    end

    W1 --> W2
    W2 -.->|relayer or user sends tx| O1
    O1 --> O2
    O2 -->|No| R1([Revert: PermitExpired])
    O2 -->|Yes| O3
    O3 --> O4
    O4 --> O5
    O5 --> O6
    O6 -->|No| R2([Revert: InvalidSignature])
    O6 -->|Yes| O7
    O7 --> O8
    O8 --> O9
    O9 --> DONE([Allowance set without an approve tx])
```

## 4. Dynamic Domain Separator (fork safety)

```mermaid
flowchart TD
    Q[DOMAIN_SEPARATOR requested] --> C{block.chainid == INITIAL_CHAIN_ID?}
    C -->|Yes| I[Return immutable INITIAL_DOMAIN_SEPARATOR]
    C -->|No| R[Recompute with current chainId]
    R --> OUT[Return dynamic separator]
    I --> OUT
```
