# Auditoría SWC — ERC20PermitToken

Verificación del contrato `ERC20PermitToken` contra el [SWC Registry](https://swcregistry.io/) (EIP-1470).

> **Nota:** El SWC Registry no se mantiene activamente desde ~2020. Para guías actualizadas ver también [SCSVS](https://github.com/ComposableSecurity/SCSVS) y [EEA EthTrust](https://entethalliance.org/specs/ethtrust/).

**Contrato auditado:** `src/ERC20PermitToken.sol`  
**Fecha:** 2026-08-23  
**Referencia tests:** `test/ERC20PermitToken.t.sol`

---

## Resumen ejecutivo

| Estado | Cantidad |
|--------|----------|
| ✅ Mitigado / No aplicable | 34 |
| ⚠️ Informativo (riesgo de diseño ERC-20/permit) | 2 |
| ❌ Vulnerable | 0 |

**Conclusión:** El contrato no presenta vulnerabilidades SWC explotables en su alcance (token ERC-20 + EIP-2612). Los dos ítems informativos son limitaciones conocidas del estándar, no bugs de implementación.

---

## Matriz completa SWC-100 — SWC-136

| ID | Título | Aplica | Estado | Evidencia en `ERC20PermitToken` |
|----|--------|--------|--------|----------------------------------|
| SWC-100 | Function Default Visibility | Sí | ✅ | Todas las funciones declaran `external` explícitamente |
| SWC-101 | Integer Overflow and Underflow | Sí | ✅ | Solidity 0.8.24; checks antes de `unchecked`; `_totalSupply` acota balances |
| SWC-102 | Outdated Compiler Version | Sí | ✅ | `pragma solidity 0.8.24` + `foundry.toml` fijo |
| SWC-103 | Floating Pragma | Sí | ✅ | Pragma exacto `0.8.24` (sin `^`) |
| SWC-104 | Unchecked Call Return Value | No | N/A | Sin llamadas externas a contratos no confiables |
| SWC-105 | Unprotected Ether Withdrawal | No | N/A | Token ERC-20; no maneja ETH |
| SWC-106 | Unprotected SELFDESTRUCT | No | N/A | Sin `selfdestruct` |
| SWC-107 | Reentrancy | Parcial | ✅ | CEI estricto; sin external calls antes de cerrar effects; sin callbacks |
| SWC-108 | State Variable Default Visibility | Sí | ✅ | State `private`; getters vía funciones `external` |
| SWC-109 | Uninitialized Storage Pointer | No | N/A | Sin punteros a storage |
| SWC-110 | Assert Violation | No | N/A | Sin `assert` en producción |
| SWC-111 | Deprecated Solidity Functions | Sí | ✅ | Sin `suicide`, `throw`, `tx.origin`, etc. |
| SWC-112 | Delegatecall to Untrusted Callee | No | N/A | Sin `delegatecall` |
| SWC-113 | DoS with Failed Call | No | N/A | Sin propagación de fallos en calls externos |
| SWC-114 | Transaction Order Dependence | Sí | ⚠️ | Ver [Riesgos informativos](#riesgos-informativos) — front-running de `approve` |
| SWC-115 | Authorization through tx.origin | No | N/A | No se usa `tx.origin` |
| SWC-116 | Block values as a proxy for time | Sí | ✅ | `block.timestamp` solo para deadline de `permit` (uso aceptado) |
| SWC-117 | Signature Malleability | Sí | ✅ | Rechazo `s > secp256k1_half_order` (EIP-2); test `test_Permit_RevertMalleableSignature` |
| SWC-118 | Incorrect Constructor Name | No | N/A | Constructor Solidity 0.8+ (`constructor`) |
| SWC-119 | Shadowing State Variables | Sí | ✅ | Sin shadowing entre interfaces y contrato |
| SWC-120 | Weak Sources of Randomness | No | N/A | Sin aleatoriedad on-chain |
| SWC-121 | Missing Protection against Signature Replay | Sí | ✅ | `_nonces`, `PERMIT_TYPEHASH`, `DOMAIN_SEPARATOR` con `chainId` |
| SWC-122 | Lack of Proper Signature Verification | Sí | ✅ | `ecrecover` + comparación `recovered == owner` + `owner != address(0)` |
| SWC-123 | Requirement Violation | Sí | ✅ | Cumple ERC-20 e EIP-2612; tests de conformidad |
| SWC-124 | Write to Arbitrary Storage Location | No | N/A | Sin assembly que escriba storage arbitrario |
| SWC-125 | Incorrect Inheritance Order | Parcial | ✅ | Herencia simple `IERC20, IERC20Permit`; sin linearización compleja |
| SWC-126 | Insufficient Gas Griefing | No | N/A | Sin relayers con gas stipend |
| SWC-127 | Arbitrary Jump with Function Type Variable | No | N/A | Sin function types dinámicos |
| SWC-128 | DoS With Block Gas Limit | Parcial | ✅ | Operaciones O(1); sin loops sobre inputs de usuario |
| SWC-129 | Typographical Error | Sí | ✅ | Revisión manual + `forge build` |
| SWC-130 | Right-To-Left-Override control character | No | N/A | Strings ASCII en deploy/tests |
| SWC-131 | Presence of unused variables | Sí | ✅ | Sin variables muertas |
| SWC-132 | Unexpected Ether balance | No | N/A | Contrato no recibe ETH (`payable` ausente) |
| SWC-133 | Hash Collisions With Multiple Variable Length Arguments | Parcial | ✅ | `abi.encode` en struct hash EIP-712 (no `encodePacked` con dinámicos) |
| SWC-134 | Message call with hardcoded gas amount | No | N/A | Sin `.call{gas: ...}` |
| SWC-135 | Code With No Effects | No | N/A | Sin statements sin efecto |
| SWC-136 | Unencrypted Private Data On-Chain | Parcial | ✅ | Balances/allowances son públicos por diseño ERC-20; no hay secretos |

---

## Riesgos informativos

### SWC-114 — Front-running de `approve`

**Descripción:** Un tercero puede observar un `approve(spender, newAmount)` en el mempool y hacer `transferFrom` con la allowance anterior antes de que se confirme la nueva.

**Estado:** ⚠️ Inherente al estándar ERC-20 (documentado en EIP-20).

**Mitigaciones en este proyecto:**
- Usar `permit` (EIP-2612) para approvals gasless en un solo paso cuando sea posible.
- Patrón recomendado: aprobar `0` antes de cambiar allowance (responsabilidad del integrador off-chain).
- Tests de `approve` + `transferFrom` validan consistencia post-tx.

### Front-running de `permit` (relacionado SWC-114 / EIP-2612)

**Descripción:** Cualquier relayer puede enviar una firma `permit` válida al contrato; el owner no controla quién paga el gas.

**Estado:** ⚠️ By design en EIP-2612; no es vulnerabilidad si la firma solo expresa allowance.

**Mitigación:** Documentar en integraciones que el firmante debe asumir ejecución pública de la firma.

---

## Mapeo SWC → tests

| SWC | Test(s) relacionado(s) |
|-----|------------------------|
| SWC-101 | Fuzz tests + `test_Transfer_RevertInsufficientBalance` |
| SWC-103 | Compilador fijo (build) |
| SWC-107 | CEI verificado en checklist Fase 7 |
| SWC-117 | `test_Permit_RevertMalleableSignature` |
| SWC-121 | `test_Permit_InvalidNonce`, `test_DomainSeparator_ChangesOnFork` |
| SWC-122 | `test_Permit_ValidSignature`, `test_Permit_WrongSigner` |
| SWC-116 | `test_Permit_ExpiredDeadline` |

---

## Referencias

- [SWC Registry](https://swcregistry.io/)
- [EIP-1470](https://eips.ethereum.org/EIPS/eip-1470)
- [EIP-2612 Permit](https://eips.ethereum.org/EIPS/eip-2612)
- [EIP-712 Typed Data](https://eips.ethereum.org/EIPS/eip-712)
