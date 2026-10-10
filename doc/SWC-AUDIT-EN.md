# SWC Audit — ERC20PermitToken

> Versión en español: [`SWC-AUDIT-ES.md`](SWC-AUDIT-ES.md)

Verification of the `ERC20PermitToken` contract against the [SWC Registry](https://swcregistry.io/) (EIP-1470).

> **Note:** The SWC Registry has not been actively maintained since ~2020. For up-to-date guidance see also [SCSVS](https://github.com/ComposableSecurity/SCSVS) and [EEA EthTrust](https://entethalliance.org/specs/ethtrust/).

**Audited contract:** `src/ERC20PermitToken.sol`  
**Date:** 2026-08-23  
**Test reference:** `test/ERC20PermitToken.t.sol`

---

## Executive Summary

| Status | Count |
|--------|-------|
| ✅ Mitigated / Not applicable | 34 |
| ⚠️ Informational (ERC-20/permit design risk) | 2 |
| ❌ Vulnerable | 0 |

**Conclusion:** The contract has no exploitable SWC vulnerabilities within its scope (ERC-20 token + EIP-2612). The two informational items are known limitations of the standard, not implementation bugs.

---

## Full Matrix SWC-100 — SWC-136

| ID | Title | Applies | Status | Evidence in `ERC20PermitToken` |
|----|-------|---------|--------|--------------------------------|
| SWC-100 | Function Default Visibility | Yes | ✅ | Every function explicitly declares `external` |
| SWC-101 | Integer Overflow and Underflow | Yes | ✅ | Solidity 0.8.24; checks before `unchecked`; `_totalSupply` bounds balances |
| SWC-102 | Outdated Compiler Version | Yes | ✅ | `pragma solidity 0.8.24` + pinned `foundry.toml` |
| SWC-103 | Floating Pragma | Yes | ✅ | Exact pragma `0.8.24` (no `^`) |
| SWC-104 | Unchecked Call Return Value | No | N/A | No external calls to untrusted contracts |
| SWC-105 | Unprotected Ether Withdrawal | No | N/A | ERC-20 token; does not handle ETH |
| SWC-106 | Unprotected SELFDESTRUCT | No | N/A | No `selfdestruct` |
| SWC-107 | Reentrancy | Partial | ✅ | Strict CEI; no external calls before effects are finalized; no callbacks |
| SWC-108 | State Variable Default Visibility | Yes | ✅ | `private` state; getters via `external` functions |
| SWC-109 | Uninitialized Storage Pointer | No | N/A | No storage pointers |
| SWC-110 | Assert Violation | No | N/A | No `assert` in production code |
| SWC-111 | Deprecated Solidity Functions | Yes | ✅ | No `suicide`, `throw`, `tx.origin`, etc. |
| SWC-112 | Delegatecall to Untrusted Callee | No | N/A | No `delegatecall` |
| SWC-113 | DoS with Failed Call | No | N/A | No failure propagation from external calls |
| SWC-114 | Transaction Order Dependence | Yes | ⚠️ | See [Informational risks](#informational-risks) — `approve` front-running |
| SWC-115 | Authorization through tx.origin | No | N/A | `tx.origin` is not used |
| SWC-116 | Block values as a proxy for time | Yes | ✅ | `block.timestamp` only for the `permit` deadline (accepted use) |
| SWC-117 | Signature Malleability | Yes | ✅ | Rejects `s > secp256k1_half_order` (EIP-2); test `test_Permit_RevertMalleableSignature` |
| SWC-118 | Incorrect Constructor Name | No | N/A | Solidity 0.8+ constructor (`constructor`) |
| SWC-119 | Shadowing State Variables | Yes | ✅ | No shadowing between interfaces and contract |
| SWC-120 | Weak Sources of Randomness | No | N/A | No on-chain randomness |
| SWC-121 | Missing Protection against Signature Replay | Yes | ✅ | `_nonces`, `PERMIT_TYPEHASH`, `DOMAIN_SEPARATOR` with `chainId` |
| SWC-122 | Lack of Proper Signature Verification | Yes | ✅ | `ecrecover` + `recovered == owner` check + `owner != address(0)` |
| SWC-123 | Requirement Violation | Yes | ✅ | Complies with ERC-20 and EIP-2612; conformance tests |
| SWC-124 | Write to Arbitrary Storage Location | No | N/A | No assembly writing to arbitrary storage |
| SWC-125 | Incorrect Inheritance Order | Partial | ✅ | Simple inheritance `IERC20, IERC20Permit`; no complex linearization |
| SWC-126 | Insufficient Gas Griefing | No | N/A | No relayers with gas stipend |
| SWC-127 | Arbitrary Jump with Function Type Variable | No | N/A | No dynamic function types |
| SWC-128 | DoS With Block Gas Limit | Partial | ✅ | O(1) operations; no loops over user input |
| SWC-129 | Typographical Error | Yes | ✅ | Manual review + `forge build` |
| SWC-130 | Right-To-Left-Override control character | No | N/A | ASCII strings in deploy/tests |
| SWC-131 | Presence of unused variables | Yes | ✅ | No dead variables |
| SWC-132 | Unexpected Ether balance | No | N/A | Contract does not receive ETH (no `payable`) |
| SWC-133 | Hash Collisions With Multiple Variable Length Arguments | Partial | ✅ | `abi.encode` in the EIP-712 struct hash (no `encodePacked` with dynamic types) |
| SWC-134 | Message call with hardcoded gas amount | No | N/A | No `.call{gas: ...}` |
| SWC-135 | Code With No Effects | No | N/A | No statements without effect |
| SWC-136 | Unencrypted Private Data On-Chain | Partial | ✅ | Balances/allowances are public by ERC-20 design; no secrets |

---

## Informational Risks

### SWC-114 — `approve` front-running

**Description:** A third party can observe an `approve(spender, newAmount)` in the mempool and call `transferFrom` with the previous allowance before the new one is confirmed.

**Status:** ⚠️ Inherent to the ERC-20 standard (documented in EIP-20).

**Mitigations in this project:**
- Use `permit` (EIP-2612) for single-step gasless approvals whenever possible.
- Recommended pattern: approve `0` before changing an allowance (responsibility of the off-chain integrator).
- `approve` + `transferFrom` tests validate post-transaction consistency.

### `permit` front-running (related to SWC-114 / EIP-2612)

**Description:** Any relayer can submit a valid `permit` signature to the contract; the owner does not control who pays the gas.

**Status:** ⚠️ By design in EIP-2612; not a vulnerability as long as the signature only expresses an allowance.

**Mitigation:** Document in integrations that the signer must assume the signature can be executed publicly.

---

## SWC → Tests Mapping

| SWC | Related test(s) |
|-----|-----------------|
| SWC-101 | Fuzz tests + `test_Transfer_RevertInsufficientBalance` |
| SWC-103 | Pinned compiler (build) |
| SWC-107 | CEI verified in the Phase 7 checklist |
| SWC-117 | `test_Permit_RevertMalleableSignature` |
| SWC-121 | `test_Permit_InvalidNonce`, `test_DomainSeparator_ChangesOnFork` |
| SWC-122 | `test_Permit_ValidSignature`, `test_Permit_WrongSigner` |
| SWC-116 | `test_Permit_ExpiredDeadline` |

---

## References

- [SWC Registry](https://swcregistry.io/)
- [EIP-1470](https://eips.ethereum.org/EIPS/eip-1470)
- [EIP-2612 Permit](https://eips.ethereum.org/EIPS/eip-2612)
- [EIP-712 Typed Data](https://eips.ethereum.org/EIPS/eip-712)
