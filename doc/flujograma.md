# Flujograma — ERC-20 Token con EIP-2612 Permit

Vista general del ciclo de vida del token y las operaciones principales soportadas por el contrato.

```mermaid
flowchart TD
    A([Inicio: Deploy del contrato]) --> B[Constructor: mint supply inicial al deployer]
    B --> C[Estado activo del token]

    C --> D{Operación solicitada}

    D -->|transfer| E{¿from tiene balance suficiente?}
    E -->|No| E1([Revert: InsufficientBalance])
    E -->|Sí| E2{"¿to != zero address?"}
    E2 -->|No| E3([Revert: ZeroAddress])
    E2 -->|Sí| E4[Actualizar balances CEI]
    E4 --> E5[Emit Transfer]
    E5 --> C

    D -->|approve| F{"¿spender != zero address?"}
    F -->|No| F1([Revert: ZeroAddress])
    F -->|Sí| F2[Establecer allowance]
    F2 --> F3[Emit Approval]
    F3 --> C

    D -->|transferFrom| G{¿allowance suficiente?}
    G -->|No| G1([Revert: InsufficientAllowance])
    G -->|Sí| G2{¿from tiene balance?}
    G2 -->|No| G3([Revert: InsufficientBalance])
    G2 -->|Sí| G4[Decrementar allowance y balances]
    G4 --> G5[Emit Transfer]
    G5 --> C

    D -->|permit| H{¿block.timestamp <= deadline?}
    H -->|No| H1([Revert: PermitExpired])
    H -->|Sí| H2[Recuperar nonce del owner]
    H2 --> H3[Construir digest EIP-712]
    H3 --> H4[ecrecover firma]
    H4 --> H5{¿signer == owner?}
    H5 -->|No| H6([Revert: InvalidSignature])
    H5 -->|Sí| H7[Incrementar nonce]
    H7 --> H8[Establecer allowance]
    H8 --> H9[Emit Approval]
    H9 --> C

    D -->|consulta| I[balanceOf / allowance / nonces / DOMAIN_SEPARATOR]
    I --> C
```

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| Rectángulo | Proceso / acción |
| Rombo | Decisión / validación |
| Estadio | Punto de inicio o fin |
| CEI | Checks-Effects-Interactions (patrón de seguridad) |
