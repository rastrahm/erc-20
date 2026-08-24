# Campañas de ataque — ERC20PermitToken

> **Protocolo:** Cada campaña se aprueba antes de implementar.  
> **Formato de implementación:** tests Foundry defensivos (`vm.expectRevert` / invariantes). El éxito del “ataque” es que **falle** contra el contrato.  
> **Fuera de alcance:** scripts de exploit, payloads, o procedimientos para extraer fondos.

Contrato: `src/ERC20PermitToken.sol`  
Auditoría previa: [`SWC-AUDIT.md`](SWC-AUDIT.md)

---

## Resumen

| Campaña | Nombre | SWC / tema | Estado |
|---------|--------|------------|--------|
| A | Integridad ERC-20 | SWC-101, zero-address, allowance | ✅ Aprobada |
| B | Firmas EIP-2612 | SWC-117, 121, 122 | ✅ Aprobada |
| C | Orden de transacciones | SWC-114 (diseño ERC-20) | ✅ Aprobada |
| D | Aritmética `unchecked` | SWC-101 | ✅ Aprobada |
| E | Superficie vacía / N/A | SWC-105, 106, 107, 112 | ✅ Aprobada |

> **Campañas A–E cerradas** — 2026-08-24. Tests defensivos en `test/ERC20PermitToken.t.sol` (`test_Attack*`).

---

## Campaña A — Integridad ERC-20

**Hipótesis:** un atacante no puede mover tokens sin balance o allowance, ni forzar `address(0)`.

| # | Escenario | Resultado esperado | Ya cubierto |
|---|-----------|--------------------|-------------|
| A1 | `transfer` con amount > balance | `InsufficientBalance` | Sí |
| A2 | `transfer` hacia `address(0)` | `ZeroAddress` | Sí |
| A3 | `transferFrom` sin allowance | `InsufficientAllowance` | Sí |
| A4 | `transferFrom` con allowance > balance | `InsufficientBalance` | Sí |
| A5 | `approve` de spender `address(0)` | `ZeroAddress` | Sí |
| A6 | `transferFrom` hacia `address(0)` | `ZeroAddress` | Sí |
| A7 | Gastar allowance parcial y reintentar el resto + 1 | `InsufficientAllowance` | ✅ `test_AttackA7_PartialAllowanceThenOverspend` |
| A8 | `transfer` a sí mismo no infla supply | `totalSupply` invariante | ✅ `test_AttackA8_SelfTransferDoesNotInflateSupply` |

### Resultado

- A1–A6 ya cubiertos por tests ERC-20 de Fase 5.
- A7–A8 implementados en `test/ERC20PermitToken.t.sol`.
- `forge test` en verde.

### Aprobación

✅ **Aprobada** — 2026-08-24

---

## Campaña B — Firmas EIP-2612

**Hipótesis:** no hay approval gasless sin firma válida, nonce actual y deadline vigente.

| # | Escenario | Resultado esperado | Ya cubierto |
|---|-----------|--------------------|-------------|
| B1 | Firma válida | allowance + nonce +1 | Sí |
| B2 | Deadline expirado | `PermitExpired` | Sí |
| B3 | Nonce incorrecto | `InvalidSignature` | Sí |
| B4 | Firmante distinto al `owner` | `InvalidSignature` | Sí |
| B5 | `s` malleable (EIP-2) | `InvalidSignature` | Sí |
| B6 | Spender `address(0)` | `ZeroAddress` | Sí |
| B7 | Reusar la misma firma tras un permit exitoso | `InvalidSignature` | ✅ `test_AttackB7_ReplaySameSignatureAfterSuccess` |
| B8 | Domain separator distinto tras cambio de `chainId` | digest inválido | ✅ `test_AttackB8_PermitInvalidAfterChainIdChange` |
| B9 | `ecrecover` → `address(0)` (`v` inválido) | `InvalidSignature` | ✅ `test_AttackB9_InvalidVYieldsZeroRecovered` |

### Resultado

- B1–B6 ya cubiertos por tests Permit previos.
- B7–B9 implementados en `test/ERC20PermitToken.t.sol`.
- `forge test --match-test test_AttackB` en verde.

### Aprobación

✅ **Aprobada** — 2026-08-24

---

## Campaña C — Orden de transacciones (SWC-114)

**Hipótesis:** el contrato no puede impedir el race de `approve` (limitación del estándar). Documentamos el comportamiento, no lo “parcheamos” rompiendo ERC-20.

| # | Escenario | Clasificación | Acción |
|---|-----------|---------------|--------|
| C1 | Cambiar allowance de N a M sin pasar por 0 | Riesgo de diseño ERC-20 | ✅ `test_AttackC1_ApproveOverwriteWithoutZeroing` |
| C2 | Un tercero envía un `permit` ya firmado | By design EIP-2612 | ✅ `test_AttackC2_RelayerCanSubmitSignedPermit` |

No hay fix on-chain sin salir del estándar. Mitigación de producto: `permit` en un solo paso, o `approve(0)` antes de cambiar allowance.

### Resultado

- Tests documentales: ambas operaciones son **válidas** según el estándar.
- `forge test --match-test test_AttackC` en verde.

### Aprobación

✅ **Aprobada** — 2026-08-24

---

## Campaña D — Aritmética `unchecked`

**Hipótesis:** los `unchecked` de balances/nonces/allowance no underflow/overflow porque hay check previo.

| # | Escenario | Resultado esperado | Ya cubierto |
|---|-----------|--------------------|-------------|
| D1 | Transfer exacto del balance completo | OK, sender queda en 0 | ✅ `test_AttackD1_ExactBalanceDrainKeepsSupply` |
| D2 | `transferFrom` con allowance `type(uint256).max` no decrementa | allowance intacta | Sí (`test_TransferFrom_InfiniteAllowance`) |
| D3 | Permit incrementa nonce una sola vez | nonce +1, segundo uso falla | Sí (`test_AttackB7_ReplaySameSignatureAfterSuccess`) |

### Resultado

- D1 implementado: vaciado exacto + invariante de `totalSupply`.
- D2–D3 reutilizan tests existentes.
- `forge test --match-test test_AttackD` en verde.

### Aprobación

✅ **Aprobada** — 2026-08-24

---

## Campaña E — Superficie vacía

El contrato **no** expone estos vectores. Checklist explícito; sin tests de exploit.

| SWC | Título (resumen) | Por qué no aplica | Evidencia |
|-----|------------------|-------------------|-----------|
| 105 | Unprotected Ether Withdrawal | No hay ETH ni `payable` | Sin funciones que reciban/envíen ETH |
| 132 | Unexpected Ether balance | Idem | Contrato no depende de `address(this).balance` |
| 106 | Unprotected SELFDESTRUCT | No hay `selfdestruct` | Código sin opcode de destrucción |
| 107 | Reentrancy | Sin calls externos ni callbacks | CEI; token puro |
| 112 | Delegatecall to Untrusted Callee | Sin `delegatecall` | Sin low-level call a callee externo |
| 120 | Weak Sources of Randomness | Sin aleatoriedad | Sin `blockhash` / `block.timestamp` como RNG |

### Resultado

- Superficie de ataque vacía para estos SWC: **N/A confirmado** por revisión de `ERC20PermitToken.sol`.
- No se añaden tests ofensivos (fuera de alcance del protocolo de campañas).

### Aprobación

✅ **Aprobada** — 2026-08-24

---

## Cierre de campañas

**Estado:** ✅ **Cerrado** — 2026-08-24

| Campaña | Tests nuevos | Naturaleza |
|---------|--------------|------------|
| A | A7, A8 | Defensivo (`expectRevert` / invariante) |
| B | B7, B8, B9 | Defensivo (firmas inválidas fallan) |
| C | C1, C2 | Documental (comportamiento estándar) |
| D | D1 | Defensivo (unchecked seguro) |
| E | — | Checklist N/A |

Ejecutar todos los tests de ataque:

```bash
forge test --match-test test_Attack
```

Referencia SWC: [`SWC-AUDIT.md`](SWC-AUDIT.md).