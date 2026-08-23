# Plan de Fases — Módulo 01: ERC-20 + EIP-2612 Permit

> **Protocolo de aprobación:** Cada fase debe ser revisada y aprobada explícitamente antes de iniciar la siguiente. No se avanza sin confirmación del responsable del proyecto.

---

## Resumen de fases

| Fase | Nombre | Entregables | Estado |
|------|--------|-------------|--------|
| 0 | Bootstrap del proyecto | Foundry init, dependencias, estructura base | ✅ Completada — pendiente tu aprobación |
| 1 | Interfaces y errores | `IERC20`, `IERC20Permit`, custom errors, events | ⏳ Siguiente fase |
| 2 | ERC-20 core | Transfer, approve, transferFrom, balanceOf, totalSupply | ⏸️ Bloqueada |
| 3 | EIP-2612 Permit | Domain separator, nonces, `permit()` con ecrecover | ⏸️ Bloqueada |
| 4 | Optimización de gas | immutables, unchecked, constant, layout | ⏸️ Bloqueada |
| 5 | Tests unitarios | Cobertura ERC-20 estándar con `vm.expectRevert` | ⏸️ Bloqueada |
| 6 | Tests fuzz & permit | Fuzzing con `bound()`, casos EIP-2612 con `vm.sign()` | ⏸️ Bloqueada |
| 7 | Revisión final | Gas report, NatSpec completo, checklist de seguridad | ⏸️ Bloqueada |

---

## Fase 0 — Bootstrap del proyecto

**Objetivo:** Preparar el entorno Foundry y la estructura de carpetas del módulo.

### Tareas

1. Ejecutar `forge init` (o equivalente manual respetando `.gitignore` existente).
2. Configurar `foundry.toml`:
   - Solidity `0.8.24` fijo (sin pragma flotante).
   - Fuzz runs ≥ 1000.
   - Optimizador activado.
3. Instalar dependencias si aplica (OpenZeppelin v5, Solmate) vía `forge install`.
4. Crear estructura de directorios:
   ```
   src/
     interfaces/
     ERC20PermitToken.sol
   test/
     ERC20PermitToken.t.sol
   script/
     Deploy.s.sol
   ```
5. Verificar compilación vacía (`forge build`).

### Criterios de aceptación

- [x] Proyecto compila sin errores.
- [x] `foundry.toml` alineado con reglas del monorepo.
- [x] `.gitignore` operativo (cache/, out/, lib/, .env).

### Resultado

- Foundry 1.4.3 inicializado con `forge init --no-git --force`.
- Dependencias: `forge-std`, `openzeppelin-contracts@v5.0.2`, `solmate`.
- Estructura base creada con contrato, test y script placeholder.
- `forge build` y `forge test` ejecutados con éxito.

### Aprobación requerida

> Responde **"Aprobado Fase 0"** (o indica cambios) para continuar a la Fase 1.

---

## Fase 1 — Interfaces y errores

**Objetivo:** Definir contratos de interfaz y errores personalizados antes de la implementación (TDD).

### Tareas

1. Crear `src/interfaces/IERC20.sol` con funciones estándar ERC-20.
2. Crear `src/interfaces/IERC20Permit.sol` con `permit`, `nonces`, `DOMAIN_SEPARATOR`.
3. Definir custom errors en el contrato principal:
   - `InsufficientBalance()`
   - `InsufficientAllowance()`
   - `ZeroAddress()`
   - `InvalidSignature()`
   - `PermitExpired()`
4. Declarar events `Transfer` y `Approval`.
5. NatSpec en todas las funciones de interfaz.

### Criterios de aceptación

- [ ] Interfaces compilan de forma independiente.
- [ ] Sin `require` con strings — solo custom errors documentados.
- [ ] Layout: Interfaces → Errors → Events.

### Aprobación requerida

> Responde **"Aprobado Fase 1"** para continuar.

---

## Fase 2 — ERC-20 core

**Objetivo:** Implementar la lógica estándar ERC-20 con patrón CEI y guards de zero-address.

### Tareas

1. Implementar state variables: `_balances`, `_allowances`, `_totalSupply`, `name`, `symbol`, `decimals`.
2. Constructor: mint del `initialSupply` al deployer.
3. Funciones públicas: `transfer`, `approve`, `transferFrom`, `balanceOf`, `allowance`, `totalSupply`.
4. Internas: `_transfer`, `_approve`, `_mint` con CEI estricto.
5. Revertir en `address(0)` en transfer, approve y mint.

### Criterios de aceptación

- [ ] Cumple ERC-20 funcional básico.
- [ ] CEI aplicado en todas las funciones con cambio de estado.
- [ ] NatSpec completo en funciones public/external.

### Aprobación requerida

> Responde **"Aprobado Fase 2"** para continuar.

---

## Fase 3 — EIP-2612 Permit

**Objetivo:** Añadir aprobaciones gasless via firma off-chain.

### Tareas

1. State: `_nonces`, `INITIAL_CHAIN_ID`, `INITIAL_DOMAIN_SEPARATOR`, `PERMIT_TYPEHASH`.
2. Implementar `nonces(address)` y `DOMAIN_SEPARATOR()` con lógica fork-safe.
3. Implementar `permit(owner, spender, value, deadline, v, r, s)`:
   - Validar deadline.
   - Construir digest EIP-712.
   - Recuperar firmante con `ecrecover`.
   - Incrementar nonce (unchecked tras validación).
   - Establecer allowance vía `_approve`.
4. Assembly/Yul opcional para encoding EIP-712 si aporta gas savings medible.

### Criterios de aceptación

- [ ] Firma válida establece allowance correctamente.
- [ ] Domain separator cambia si `block.chainid != INITIAL_CHAIN_ID`.
- [ ] Nonce se incrementa exactamente una vez por permit exitoso.

### Aprobación requerida

> Responde **"Aprobado Fase 3"** para continuar.

---

## Fase 4 — Optimización de gas

**Objetivo:** Aplicar optimizaciones documentadas sin comprometer seguridad.

### Tareas

1. Marcar `decimals`, `INITIAL_CHAIN_ID`, `INITIAL_DOMAIN_SEPARATOR` como `immutable`.
2. `PERMIT_TYPEHASH` como `constant`.
3. Bloques `unchecked` en ajustes de balance y nonces donde bounds estén validados.
4. Preferir `external` sobre `public` donde aplique.
5. Documentar tradeoffs de gas en comentarios `@dev`.

### Criterios de aceptación

- [ ] `forge test --gas-report` generado y revisado.
- [ ] Sin regresiones funcionales respecto a fases 2–3.

### Aprobación requerida

> Responde **"Aprobado Fase 4"** para continuar.

---

## Fase 5 — Tests unitarios

**Objetivo:** Cobertura completa de paths explícitos ERC-20.

### Tareas

1. `setUp()`: deploy token con supply inicial conocido.
2. Tests positivos: transfer, approve, transferFrom.
3. Tests de revert: balance insuficiente, allowance insuficiente, zero-address.
4. Usar `vm.expectRevert()` con custom errors selectors.
5. Objetivo: 100% branch coverage en lógica ERC-20.

### Criterios de aceptación

- [ ] `forge test` pasa al 100%.
- [ ] Todos los revert paths cubiertos.

### Aprobación requerida

> Responde **"Aprobado Fase 5"** para continuar.

---

## Fase 6 — Tests fuzz & permit

**Objetivo:** Validación property-based y casos EIP-2612.

### Tareas

1. Fuzz `transfer`: amount acotado con `bound()`, recipient aleatorio (excluir zero-address).
2. Fuzz `approve` + `transferFrom` con allowances variables.
3. Permit con firma válida via `vm.sign()`.
4. Permit con deadline expirado → `PermitExpired`.
5. Permit con nonce incorrecto → `InvalidSignature`.
6. Permit con firma de otro owner → `InvalidSignature`.

### Criterios de aceptación

- [ ] Fuzz runs ≥ 1000 sin fallos.
- [ ] Todos los escenarios EIP-2612 de `.cursorrules` cubiertos.

### Aprobación requerida

> Responde **"Aprobado Fase 6"** para continuar.

---

## Fase 7 — Revisión final

**Objetivo:** Cierre del módulo con calidad production-ready.

### Tareas

1. Revisión NatSpec en todo el código público/externo.
2. Checklist de seguridad: CEI, zero-address, reentrancy (N/A en token puro), custom errors.
3. Script de deploy (`script/Deploy.s.sol`).
4. Actualizar diagramas en `doc/` si la implementación difiere del diseño.
5. Ejecutar suite completa: `forge test -vvv` + gas report.

### Criterios de aceptación

- [ ] Suite completa verde.
- [ ] Documentación alineada con código final.
- [ ] Listo para integración en el monorepo.

### Aprobación requerida

> Responde **"Aprobado Fase 7"** para dar por cerrado el módulo.

---

## Próximo paso

**Fase 0 — Bootstrap del proyecto** está lista para iniciar.

Indica si apruebas esta fase tal como está descrita, o si deseas ajustar el alcance, dependencias o estructura de carpetas antes de comenzar.
