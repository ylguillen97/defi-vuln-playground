# DeFi Vulnerability Playground (Foundry)

A curated, hands-on playground of **realistic DeFi security vulnerabilities**, built to be **reproducible, test-driven, and audit-friendly**.

This repository contains small, focused protocol components (vaults, lending primitives, AMMs, token integrations, etc.) that are **intentionally vulnerable**, alongside:
- a **deterministic Proof of Concept (PoC)** exploit written as Foundry tests,
- a **fixed version** with clear mitigations,
- and **regression tests + documentation** explaining impact, root cause, and tradeoffs.

The goal is not to build a large protocol. The goal is to build **many small, high-signal security case studies** that demonstrate practical Solidity/DeFi security engineering.

---

## What you’ll find here

Each vulnerability case is structured the same way:

1. **V1 (Vulnerable)**  
   A minimal contract/protocol component with a security flaw.

2. **Exploit / PoC**  
   A contract or call sequence that exploits the flaw, demonstrated via Foundry tests.

3. **V1 (Fixed)**  
   A corrected version with a standard mitigation and brief rationale.

4. **Tests (Foundry)**  
   - One test that **successfully exploits** the vulnerable version  
   - One test that proves the **fix prevents** the exploit  
   - Additional **regression tests** to preserve intended behavior

5. **Docs (audit-style write-up)**  
   A short report covering impact, preconditions, root cause, exploit steps, and the fix.

This makes the repository easy to navigate, extend, and review.

---

## Repository layout

```text
defi-vuln-playground/
├─ src/
│  ├─ common/                  # shared mocks & helpers
│  ├─ reentrancy/              # reentrancy patterns & fixes
│  ├─ oracle-manipulation/     # spot price / TWAP / oracle pitfalls
│  ├─ access-control/          # tx.origin, missing auth, initializer issues
│  ├─ token-integration/       # ERC20 edge cases (fee-on-transfer, no-return, etc.)
│  └─ ...                      # more categories over time
├─ test/                       # Foundry tests (PoCs + regression)
├─ docs/                       # audit-style writeups per case
└─ .github/workflows/ci.yml    # CI to run tests on PRs/pushes
