# Attack Campaigns — ERC20PermitToken

> Versión en español: [`ATAQUES-ES.md`](ATAQUES-ES.md)

> **Protocol:** Each campaign is approved before implementation.  
> **Implementation format:** defensive Foundry tests (`vm.expectRevert` / invariants). The "attack" succeeds when it **fails** against the contract.  
> **Out of scope:** exploit scripts, payloads, or procedures to extract funds.

Contract: `src/ERC20PermitToken.sol`  
Previous audit: [`SWC-AUDIT-EN.md`](SWC-AUDIT-EN.md)

---

## Summary

| Campaign | Name | SWC / topic | Status |
|----------|------|-------------|--------|
| A | ERC-20 integrity | SWC-101, zero-address, allowance | ✅ Approved |
| B | EIP-2612 signatures | SWC-117, 121, 122 | ✅ Approved |
| C | Transaction ordering | SWC-114 (ERC-20 design) | ✅ Approved |
| D | `unchecked` arithmetic | SWC-101 | ✅ Approved |
| E | Empty surface / N/A | SWC-105, 106, 107, 112 | ✅ Approved |

> **Campaigns A–E closed** — 2026-08-24. Defensive tests in `test/ERC20PermitToken.t.sol` (`test_Attack*`).

---

## Campaign A — ERC-20 Integrity

**Hypothesis:** an attacker cannot move tokens without balance or allowance, nor force `address(0)`.

| # | Scenario | Expected result | Already covered |
|---|----------|-----------------|-----------------|
| A1 | `transfer` with amount > balance | `InsufficientBalance` | Yes |
| A2 | `transfer` to `address(0)` | `ZeroAddress` | Yes |
| A3 | `transferFrom` without allowance | `InsufficientAllowance` | Yes |
| A4 | `transferFrom` with allowance > balance | `InsufficientBalance` | Yes |
| A5 | `approve` with spender `address(0)` | `ZeroAddress` | Yes |
| A6 | `transferFrom` to `address(0)` | `ZeroAddress` | Yes |
| A7 | Spend a partial allowance and retry the remainder + 1 | `InsufficientAllowance` | ✅ `test_AttackA7_PartialAllowanceThenOverspend` |
| A8 | `transfer` to self does not inflate supply | `totalSupply` invariant | ✅ `test_AttackA8_SelfTransferDoesNotInflateSupply` |

### Result

- A1–A6 already covered by the ERC-20 tests from Phase 5.
- A7–A8 implemented in `test/ERC20PermitToken.t.sol`.
- `forge test` green.

### Approval

✅ **Approved** — 2026-08-24

---

## Campaign B — EIP-2612 Signatures

**Hypothesis:** there is no gasless approval without a valid signature, the current nonce and a non-expired deadline.

| # | Scenario | Expected result | Already covered |
|---|----------|-----------------|-----------------|
| B1 | Valid signature | allowance + nonce +1 | Yes |
| B2 | Expired deadline | `PermitExpired` | Yes |
| B3 | Wrong nonce | `InvalidSignature` | Yes |
| B4 | Signer different from `owner` | `InvalidSignature` | Yes |
| B5 | Malleable `s` (EIP-2) | `InvalidSignature` | Yes |
| B6 | Spender `address(0)` | `ZeroAddress` | Yes |
| B7 | Reuse the same signature after a successful permit | `InvalidSignature` | ✅ `test_AttackB7_ReplaySameSignatureAfterSuccess` |
| B8 | Different domain separator after a `chainId` change | invalid digest | ✅ `test_AttackB8_PermitInvalidAfterChainIdChange` |
| B9 | `ecrecover` → `address(0)` (invalid `v`) | `InvalidSignature` | ✅ `test_AttackB9_InvalidVYieldsZeroRecovered` |

### Result

- B1–B6 already covered by previous Permit tests.
- B7–B9 implemented in `test/ERC20PermitToken.t.sol`.
- `forge test --match-test test_AttackB` green.

### Approval

✅ **Approved** — 2026-08-24

---

## Campaign C — Transaction Ordering (SWC-114)

**Hypothesis:** the contract cannot prevent the `approve` race (a limitation of the standard). We document the behavior instead of "patching" it by breaking ERC-20.

| # | Scenario | Classification | Action |
|---|----------|----------------|--------|
| C1 | Change allowance from N to M without going through 0 | ERC-20 design risk | ✅ `test_AttackC1_ApproveOverwriteWithoutZeroing` |
| C2 | A third party submits an already signed `permit` | By design in EIP-2612 | ✅ `test_AttackC2_RelayerCanSubmitSignedPermit` |

There is no on-chain fix without leaving the standard. Product-level mitigation: single-step `permit`, or `approve(0)` before changing an allowance.

### Result

- Documentary tests: both operations are **valid** according to the standard.
- `forge test --match-test test_AttackC` green.

### Approval

✅ **Approved** — 2026-08-24

---

## Campaign D — `unchecked` Arithmetic

**Hypothesis:** the `unchecked` blocks on balances/nonces/allowance cannot underflow/overflow because there is a prior check.

| # | Scenario | Expected result | Already covered |
|---|----------|-----------------|-----------------|
| D1 | Transfer of the exact full balance | OK, sender ends at 0 | ✅ `test_AttackD1_ExactBalanceDrainKeepsSupply` |
| D2 | `transferFrom` with `type(uint256).max` allowance does not decrement | allowance unchanged | Yes (`test_TransferFrom_InfiniteAllowance`) |
| D3 | Permit increments the nonce exactly once | nonce +1, second use fails | Yes (`test_AttackB7_ReplaySameSignatureAfterSuccess`) |

### Result

- D1 implemented: exact drain + `totalSupply` invariant.
- D2–D3 reuse existing tests.
- `forge test --match-test test_AttackD` green.

### Approval

✅ **Approved** — 2026-08-24

---

## Campaign E — Empty Surface

The contract does **not** expose these vectors. Explicit checklist; no exploit tests.

| SWC | Title (summary) | Why it does not apply | Evidence |
|-----|-----------------|-----------------------|----------|
| 105 | Unprotected Ether Withdrawal | No ETH and no `payable` | No functions that receive/send ETH |
| 132 | Unexpected Ether balance | Same as above | Contract does not depend on `address(this).balance` |
| 106 | Unprotected SELFDESTRUCT | No `selfdestruct` | No destruction opcode in the code |
| 107 | Reentrancy | No external calls or callbacks | CEI; pure token |
| 112 | Delegatecall to Untrusted Callee | No `delegatecall` | No low-level call to an external callee |
| 120 | Weak Sources of Randomness | No randomness | No `blockhash` / `block.timestamp` used as RNG |

### Result

- Empty attack surface for these SWCs: **N/A confirmed** by reviewing `ERC20PermitToken.sol`.
- No offensive tests added (out of scope of the campaign protocol).

### Approval

✅ **Approved** — 2026-08-24

---

## Campaign Closure

**Status:** ✅ **Closed** — 2026-08-24

| Campaign | New tests | Nature |
|----------|-----------|--------|
| A | A7, A8 | Defensive (`expectRevert` / invariant) |
| B | B7, B8, B9 | Defensive (invalid signatures fail) |
| C | C1, C2 | Documentary (standard behavior) |
| D | D1 | Defensive (safe unchecked) |
| E | — | N/A checklist |

Run all attack tests:

```bash
forge test --match-test test_Attack
```

SWC reference: [`SWC-AUDIT-EN.md`](SWC-AUDIT-EN.md).
