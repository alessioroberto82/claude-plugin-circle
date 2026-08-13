# Security Audit: {Feature/System Name}

**Date**: {YYYY-MM-DD}
**Auditor**: Security Guardian (Circle)
**Scope**: {What was audited}
**Domain**: {software / general}

---

## Executive Summary

**Risk Level**: {Critical / High / Medium / Low}
**Critical Findings**: {count}
**Verdict**: {SECURITY BLOCK / SECURITY PASS with warnings / SECURITY PASS}

---

<!-- SOFTWARE DOMAIN: Include STRIDE + OWASP sections -->

## STRIDE Threat Model

| Threat | Category | Component | Severity | Status |
|---|---|---|---|---|
| {Threat description} | Spoofing / Tampering / Repudiation / Info Disclosure / DoS / Elevation | {Component} | P0/P1/P2/P3 | Open / Mitigated |

## OWASP Top 10 Check

| # | Category | Status | Notes |
|---|---|---|---|
| A01 | Broken Access Control | Pass/Fail/N/A | {Notes} |
| A02 | Cryptographic Failures | Pass/Fail/N/A | {Notes} |
| A03 | Injection | Pass/Fail/N/A | {Notes} |
| A04 | Insecure Design | Pass/Fail/N/A | {Notes} |
| A05 | Security Misconfiguration | Pass/Fail/N/A | {Notes} |
| A06 | Vulnerable Components | Pass/Fail/N/A | {Notes} |
| A07 | Auth Failures | Pass/Fail/N/A | {Notes} |
| A08 | Data Integrity Failures | Pass/Fail/N/A | {Notes} |
| A09 | Logging Failures | Pass/Fail/N/A | {Notes} |
| A10 | SSRF | Pass/Fail/N/A | {Notes} |

## Platform-Specific Security

- **{Platform security concern 1}**: {Assessment}
- **{Platform security concern 2}**: {Assessment}

<!-- BUSINESS DOMAIN: Include Compliance + Data Governance sections -->

## Regulatory Compliance

| Regulation | Applicable | Status | Gaps |
|---|---|---|---|
| GDPR | Yes/No | Compliant / Partial / Non-compliant | {Gaps} |
| CCPA | Yes/No | Compliant / Partial / Non-compliant | {Gaps} |
| {Industry-specific} | Yes/No | Compliant / Partial / Non-compliant | {Gaps} |

## Data Governance

- **Collection**: {What data, legal basis, consent mechanism}
- **Storage**: {Where, encryption, retention policy}
- **Processing**: {How, who has access, audit trail}
- **Sharing**: {Third parties, data processing agreements}

## Vendor Risk

| Vendor | Data Shared | Risk Level | DPA in Place | Notes |
|---|---|---|---|---|
| {Vendor} | {Data types} | High/Medium/Low | Yes/No | {Notes} |

<!-- ALL DOMAINS: Findings, Recommendations, Verdict -->

---

## Findings

### P0 — Critical (Must fix before implementation)
- {Finding or "None"}

### P1 — High (Fix before release)
- {Finding or "None"}

### P2 — Medium (Fix in next cycle)
- {Finding or "None"}

### P3 — Low (Track for future)
- {Finding or "None"}

## Remediation Roadmap

| Priority | Finding | Action | Owner | Timeline |
|---|---|---|---|---|
| P0 | {Finding} | {Action} | {Role} | Immediate |
| P1 | {Finding} | {Action} | {Role} | This cycle |

## Verdict

**{SECURITY BLOCK / SECURITY PASS with warnings / SECURITY PASS}**

{Summary statement}
