# Phase Plan — Module 01: ERC-20 + EIP-2612 Permit

> Versión en español: [`FASES-ES.md`](FASES-ES.md)

> **Approval protocol:** Each phase must be reviewed and explicitly approved before starting the next one. No progress is made without confirmation from the project owner.

---

## Phase Summary

| Phase | Name | Deliverables | Status |
|-------|------|--------------|--------|
| 0 | Project bootstrap | Foundry init, dependencies, base structure | ✅ Approved |
| 1 | Interfaces and errors | `IERC20`, `IERC20Permit`, custom errors, events | ✅ Approved |
| 2 | ERC-20 core | Transfer, approve, transferFrom, balanceOf, totalSupply | ✅ Approved |
| 3 | EIP-2612 Permit | Domain separator, nonces, `permit()` with ecrecover | ✅ Approved |
| 4 | Gas optimization | immutables, unchecked, constant, layout | ✅ Approved |
| 5 | Unit tests | Standard ERC-20 coverage with `vm.expectRevert` | ✅ Approved |
| 6 | Fuzz & permit tests | Fuzzing with `bound()`, EIP-2612 cases with `vm.sign()` | ✅ Approved |
| 7 | Final review | Gas report, complete NatSpec, security checklist | ✅ Approved |
| 8 | SWC audit | SWC-100–136 matrix, contract verification, tests | ✅ Approved |

> **Module 01 closed** — All phases (0–8) approved on 2026-08-23.

---

## Phase 0 — Project Bootstrap

**Goal:** Prepare the Foundry environment and the module folder structure.

### Tasks

1. Run `forge init` (or a manual equivalent that respects the existing `.gitignore`).
2. Configure `foundry.toml`:
   - Pinned Solidity `0.8.24` (no floating pragma).
   - Fuzz runs ≥ 1000.
   - Optimizer enabled.
3. Install dependencies if applicable (OpenZeppelin v5, Solmate) via `forge install`.
4. Create the directory structure:
   ```
   src/
     interfaces/
     ERC20PermitToken.sol
   test/
     ERC20PermitToken.t.sol
   script/
     Deploy.s.sol
   ```
5. Verify an empty build (`forge build`).

### Acceptance Criteria

- [x] Project compiles without errors.
- [x] `foundry.toml` aligned with the monorepo rules.
- [x] Working `.gitignore` (cache/, out/, lib/, .env).

### Result

- Foundry 1.4.3 initialized with `forge init --no-git --force`.
- Dependencies: `forge-std`, `openzeppelin-contracts@v5.0.2`, `solmate`.
- Base structure created with placeholder contract, test and script.
- `forge build` and `forge test` ran successfully.

### Approval

✅ **Approved** — 2026-08-23

> Reply when you want to start **Phase 1**.

---

## Phase 1 — Interfaces and Errors

**Goal:** Define interface contracts and custom errors before the implementation (TDD).

### Tasks

1. Create `src/interfaces/IERC20.sol` with the standard ERC-20 functions.
2. Create `src/interfaces/IERC20Permit.sol` with `permit`, `nonces`, `DOMAIN_SEPARATOR`.
3. Define custom errors in the main contract:
   - `InsufficientBalance()`
   - `InsufficientAllowance()`
   - `ZeroAddress()`
   - `InvalidSignature()`
   - `PermitExpired()`
4. Declare the `Transfer` and `Approval` events.
5. NatSpec on every interface function.

### Acceptance Criteria

- [x] Interfaces compile independently.
- [x] No `require` with strings — only documented custom errors.
- [x] Layout: Interfaces → Errors → Events.

### Result

- `src/interfaces/IERC20.sol` — 7 ERC-20 functions with NatSpec.
- `src/interfaces/IERC20Permit.sol` — `permit`, `nonces`, `DOMAIN_SEPARATOR` with NatSpec.
- `src/ERC20PermitToken.sol` — 5 custom errors + `Transfer` and `Approval` events.
- Interface inheritance deferred to Phase 2 (core implementation).

### Approval

✅ **Approved** — 2026-08-23

> Reply when you want to start **Phase 2**.

---

## Phase 2 — ERC-20 Core

**Goal:** Implement the standard ERC-20 logic with the CEI pattern and zero-address guards.

### Tasks

1. Implement state variables: `_balances`, `_allowances`, `_totalSupply`, `name`, `symbol`, `decimals`.
2. Constructor: mint `initialSupply` to the deployer.
3. Public functions: `transfer`, `approve`, `transferFrom`, `balanceOf`, `allowance`, `totalSupply`.
4. Internal functions: `_transfer`, `_approve`, `_mint` with strict CEI.
5. Revert on `address(0)` in transfer, approve and mint.

### Acceptance Criteria

- [x] Meets basic functional ERC-20.
- [x] CEI applied in every state-changing function.
- [x] Complete NatSpec on public/external functions.

### Result

- `ERC20PermitToken is IERC20` with state, constructor and core functions.
- Internal `_transfer`, `_approve`, `_mint`, `_spendAllowance` with guards and safe `unchecked`.
- Smoke tests: deploy, transfer, approve + transferFrom.
- `forge build` and `forge test` green.

### Approval

✅ **Approved** — 2026-08-23

> Reply when you want to start **Phase 3**.

---

## Phase 3 — EIP-2612 Permit

**Goal:** Add gasless approvals via off-chain signatures.

### Tasks

1. State: `_nonces`, `INITIAL_CHAIN_ID`, `INITIAL_DOMAIN_SEPARATOR`, `PERMIT_TYPEHASH`.
2. Implement `nonces(address)` and `DOMAIN_SEPARATOR()` with fork-safe logic.
3. Implement `permit(owner, spender, value, deadline, v, r, s)`:
   - Validate the deadline.
   - Build the EIP-712 digest.
   - Recover the signer with `ecrecover`.
   - Increment the nonce (unchecked after validation).
   - Set the allowance via `_approve`.
4. Optional Assembly/Yul for EIP-712 encoding if it brings measurable gas savings.

### Acceptance Criteria

- [x] A valid signature sets the allowance correctly.
- [x] The domain separator changes if `block.chainid != INITIAL_CHAIN_ID`.
- [x] The nonce is incremented exactly once per successful permit.

### Result

- `ERC20PermitToken is IERC20, IERC20Permit` with `_nonces`, `PERMIT_TYPEHASH`, fork-safe immutables.
- `permit()` validates the deadline, anti-malleability (EIP-2), `ecrecover`, increments the nonce and calls `_approve`.
- Tests: valid signature, expired deadline, invalid nonce, domain separator on fork.
- `forge test` — 8 green tests.

### Approval

✅ **Approved** — 2026-08-23

> Reply when you want to start **Phase 4**.

---

## Phase 4 — Gas Optimization

**Goal:** Apply documented optimizations without compromising security.

### Tasks

1. Mark `decimals`, `INITIAL_CHAIN_ID`, `INITIAL_DOMAIN_SEPARATOR` as `immutable`.
2. `PERMIT_TYPEHASH` as `constant`.
3. `unchecked` blocks for balance and nonce adjustments where bounds are validated.
4. Prefer `external` over `public` where applicable.
5. Document gas tradeoffs in `@dev` comments.

### Acceptance Criteria

- [x] `forge test --gas-report` generated and reviewed.
- [x] No functional regressions compared to phases 2–3.

### Result

Optimizations applied and documented with `@dev`:

| Optimization | Tradeoff |
|---|---|
| `_DOMAIN_TYPEHASH`, `_VERSION_HASH` constants | Fewer keccak calls on forks; +2 bytecode slots |
| `_NAME_HASH` immutable | Avoids re-reading `string storage` when recomputing the domain separator |
| Unified `_buildDomainSeparator(chainId)` | Constructor and forks share the same logic |
| `type(uint256).max` allowance without decrement | ~5k less gas per `transferFrom`; standard DeFi pattern |
| `unchecked` on balances/nonces/allowance | No redundant overflow checks after explicit validation |
| Immutables (`decimals`, chain ID, domain separator) | Already present; reads ~100 gas vs ~2100 SLOAD |

Gas report (`gas-report.txt`, gitignored): 9 green tests. Deploy ~756k gas.

### Approval

✅ **Approved** — 2026-08-23

> Reply when you want to start **Phase 5**.

---

## Phase 5 — Unit Tests

**Goal:** Full coverage of explicit ERC-20 paths.

### Tasks

1. `setUp()`: deploy the token with a known initial supply.
2. Positive tests: transfer, approve, transferFrom.
3. Revert tests: insufficient balance, insufficient allowance, zero-address.
4. Use `vm.expectRevert()` with custom error selectors.
5. Goal: 100% branch coverage of the ERC-20 logic.

### Acceptance Criteria

- [x] `forge test` passes 100%.
- [x] Every revert path covered (ERC-20 public API).

### Result

**21 tests** in `ERC20PermitToken.t.sol`:

| Category | Tests |
|----------|-------|
| ERC-20 positive | transfer, approve, transferFrom, events, zero amount, infinite allowance |
| ERC-20 reverts | `InsufficientBalance`, `InsufficientAllowance`, `ZeroAddress` (to/spender) |

Coverage (`forge coverage`):
- **Lines:** 100% in `ERC20PermitToken.sol`
- **Functions:** 100%
- **Branches:** 63.64% overall (internal guards `from==0` / `owner==0` and permit paths pending for Phase 6)

### Approval

✅ **Approved** — 2026-08-23

> Reply when you want to start **Phase 6**.

---

## Phase 6 — Fuzz & Permit Tests

**Goal:** Property-based validation and EIP-2612 cases.

### Tasks

1. Fuzz `transfer`: amount bounded with `bound()`, random recipient (excluding zero-address).
2. Fuzz `approve` + `transferFrom` with variable allowances.
3. Permit with a valid signature via `vm.sign()`.
4. Permit with an expired deadline → `PermitExpired`.
5. Permit with a wrong nonce → `InvalidSignature`.
6. Permit signed by another owner → `InvalidSignature`.

### Acceptance Criteria

- [x] Fuzz runs ≥ 1000 without failures.
- [x] Every EIP-2612 scenario from `.cursorrules` covered.

### Result

**26 tests** — fuzz with `--fuzz-runs 1000`:

| Test | Description |
|------|-------------|
| `testFuzz_Transfer` | `bound(amount)` + recipient ≠ zero-address |
| `testFuzz_ApproveTransferFrom` | variable allowances and amounts |
| `testFuzz_Permit_ValidSignature` | valid permit with fuzzed value/deadline |
| `test_Permit_WrongSigner` | signature from another owner → `InvalidSignature` |
| `test_Permit_*` (previous) | valid, expired deadline, invalid nonce |
| `test_Permit_RevertZeroAddressSpender` | zero spender after a valid signature |

Helper `_signPermitWithKey` for signatures with arbitrary keys via `vm.sign()`.

### Approval

✅ **Approved** — 2026-08-23

> Reply when you want to start **Phase 7**.

---

## Phase 7 — Final Review

**Goal:** Close the module with production-ready quality.

### Tasks

1. NatSpec review across all public/external code.
2. Security checklist: CEI, zero-address, reentrancy (N/A for a pure token), custom errors.
3. Deploy script (`script/Deploy.s.sol`).
4. Update the diagrams in `doc/` if the implementation differs from the design.
5. Run the full suite: `forge test -vvv` + gas report.

### Acceptance Criteria

- [x] Full suite green.
- [x] Documentation aligned with the final code.
- [x] Ready for monorepo integration.

### Result

#### Security Checklist

| Item | Status |
|------|--------|
| CEI in `_transfer`, `_approve`, `_mint`, `permit` | ✅ |
| `ZeroAddress` guards in transfer/approve/mint | ✅ |
| Custom errors (no `require` strings) | ✅ |
| Reentrancy | N/A — pure token without external calls |
| EIP-2 anti-malleability in `permit` | ✅ |
| Fork-safe domain separator | ✅ |
| Infinite allowance (`type(uint256).max`) | ✅ |

#### Deliverables

- NatSpec in interfaces, contract and deploy script
- `script/Deploy.s.sol` with env vars + `.env.example`
- `doc/diagrama-de-clases-EN.md` aligned with the final implementation
- `forge test -vvv` — **27 green tests**
- `forge test --gas-report` — deploy ~756k gas

### Approval

✅ **Approved** — 2026-08-23

---

## Phase 8 — SWC Registry Audit

**Goal:** Verify `ERC20PermitToken` against the [SWC Registry](https://swcregistry.io/) (EIP-1470) — a catalog of known weaknesses in Solidity contracts.

### Tasks

1. Map SWC-100 to SWC-136 indicating: applies / N/A / mitigated.
2. Document evidence in code and tests for every relevant SWC.
3. Identify informational risks (ERC-20/permit front-running).
4. Add the missing SWC-117 test (signature malleability) if it does not exist.
5. Publish the report in `doc/SWC-AUDIT-EN.md`.

### Acceptance Criteria

- [x] Complete SWC matrix (37 entries).
- [x] Zero exploitable SWC vulnerabilities within the token scope.
- [x] Informational risks documented with mitigations.
- [x] Tests linked to critical SWCs (117, 121, 122).

### Result

- Report: [`doc/SWC-AUDIT-EN.md`](SWC-AUDIT-EN.md)
- **34** SWCs mitigated or N/A · **2** informational (SWC-114 / permit front-run) · **0** vulnerable
- Test added: `test_Permit_RevertMalleableSignature` (SWC-117)
- `forge test` green

### Approval

✅ **Approved** — 2026-08-23

---

## Module Closure

**Status:** ✅ **Closed** — 2026-08-23

Module **01-erc20** (ERC-20 + EIP-2612 Permit) completed phases 0–8. Ready for monorepo integration or deployment via `script/Deploy.s.sol`.

Attack campaigns (post-closure): [`doc/ATAQUES-EN.md`](ATAQUES-EN.md).
