# Diagrama de Flujo — Operaciones críticas

> English version: [`diagrama-de-flujo-EN.md`](diagrama-de-flujo-EN.md)

Detalle del flujo de datos y control para `transfer`, `transferFrom` y `permit`.

## 1. Flujo de transferencia directa (`transfer`)

```mermaid
flowchart LR
    subgraph Entrada
        U[Usuario: msg.sender]
        A[monto: amount]
        B[destino: to]
    end

    subgraph Validaciones
        V1[balanceOf msg.sender >= amount]
        V2[to != address 0]
    end

    subgraph Efectos
        E1[_balances sender -= amount]
        E2[_balances to += amount]
    end

    subgraph Salida
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

## 2. Flujo de transferencia delegada (`transferFrom`)

```mermaid
flowchart LR
    subgraph Entrada
        SP[spender: msg.sender]
        FR[from]
        TO[to]
        AM[amount]
    end

    subgraph Validaciones
        V1[allowance from, spender >= amount]
        V2[balanceOf from >= amount]
        V3[to != address 0]
    end

    subgraph Efectos
        E1[_allowances from, spender -= amount]
        E2[_balances from -= amount]
        E3[_balances to += amount]
    end

    subgraph Salida
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

## 3. Flujo de aprobación off-chain (`permit` — EIP-2612)

```mermaid
flowchart TD
    subgraph OffChain["Off-chain (wallet / dApp)"]
        W1[Usuario firma typed data EIP-712]
        W2[Struct: Owner, Spender, Value, Nonce, Deadline]
    end

    subgraph OnChain["On-chain (contrato)"]
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
    W2 -.->|relayer o usuario envía tx| O1
    O1 --> O2
    O2 -->|No| R1([Revert: PermitExpired])
    O2 -->|Sí| O3
    O3 --> O4
    O4 --> O5
    O5 --> O6
    O6 -->|No| R2([Revert: InvalidSignature])
    O6 -->|Sí| O7
    O7 --> O8
    O8 --> O9
    O9 --> DONE([Allowance establecida sin tx approve])
```

## 4. Domain Separator dinámico (fork safety)

```mermaid
flowchart TD
    Q[DOMAIN_SEPARATOR consultado] --> C{block.chainid == INITIAL_CHAIN_ID?}
    C -->|Sí| I[Retornar INITIAL_DOMAIN_SEPARATOR immutable]
    C -->|No| R[Recalcular con chainId actual]
    R --> OUT[Retornar separator dinámico]
    I --> OUT
```
