# FIPS 199 System Categorization
## Help Desk AI Triage Agent

**Document Type:** System Categorization  
**Framework:** FIPS 199, NIST SP 800-60, NIST 800-37 Step 2  
**System:** Help Desk AI Triage Agent  
**Date:** 2026-05-15  
**Status:** Implemented  

---

## 1. System Description

| Attribute | Value |
|---|---|
| System Name | Help Desk AI Triage Agent |
| System Type | AI-enabled IT support tool (RAG-based multi-agent pipeline) |
| Purpose | Triage and classify IT support tickets submitted by end users and IT staff |
| Deployment | Ubuntu 24.04 LTS server, VMware Fusion, aarch64 |
| Users | IT staff and end users submitting support tickets |
| Authorization Boundary | Single Ubuntu VM running Streamlit UI, LangGraph pipeline, Ollama inference, FAISS vector store |
| Data Processed | IT support ticket text (free-form), SANS policy documents (public) |
| External Dependencies | None — fully local inference, no data transmitted externally |

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Rationale |
|---|---|---|
| Confidentiality | Low | No PII, no sensitive data, public SANS knowledge base, local inference only |
| Integrity | Moderate | Incorrect guidance could cause wrong IT actions, misconfigurations, or extended downtime |
| Availability | Moderate | Manual fallback exists, no mission-critical dependency, no SLA defined |

**Overall System Categorization: SC = {(Confidentiality, Low), (Integrity, Moderate), (Availability, Moderate)}**

**Final Classification: MODERATE** (high water mark across all three objectives)

---

## 3. Rationale

### Confidentiality — Low
Ticket text submitted by users contains no PII, credentials, or sensitive business data. The knowledge base consists entirely of publicly available SANS policy templates. No data is transmitted externally — all model inference runs locally via Ollama. The highest confidentiality risk identified was technology stack disclosure in the UI caption, which was mitigated in Phase 5 by removing the stack identifier from the Streamlit caption.

### Integrity — Moderate
If the agent produces incorrect policy guidance due to RAG poisoning, prompt injection, or model hallucination, IT staff could take incorrect remediation actions. Potential impacts include security misconfigurations, wrong access controls applied, or extended incident resolution time. The following controls reduce but do not eliminate this risk: sanitize_input() for injection defense, FAISS SHA256 integrity monitoring for RAG poisoning, and the synthesizer prompt enforcing citation and uncertainty acknowledgment. The human-on-the-loop model (IT staff review before acting) provides the key residual control.

### Availability — Moderate
Agent unavailability increases IT ticket response time and reduces staff efficiency. However a manual fallback exists — IT staff can and do process tickets without the agent. No SLA is defined for this system. No mission-critical operations depend exclusively on the agent. Recovery time from a failure is approximately 2-5 minutes (VM restart + Ollama model reload). Availability is therefore Moderate rather than High.

---

## 4. Impact Analysis

### Confidentiality Breach
**Impact: Low.** Unauthorized disclosure of ticket text has minimal consequence given no sensitive data is processed. The most significant confidentiality risk — technology stack disclosure via the UI caption — was mitigated in Phase 5.

### Integrity Failure
**Impact: Moderate.** Incorrect IT guidance could result in:
- Wrong access controls applied to systems or users
- Security tools incorrectly disabled or misconfigured
- Incorrect network configurations causing outages
- Extended incident resolution time due to following bad guidance

The human-on-the-loop model (IT staff must review and approve before acting on agent recommendations) is the primary residual control for integrity failures.

### Availability Loss
**Impact: Moderate.** IT helpdesk capacity is reduced but not eliminated. Users are directed to contact IT staff directly per the synthesizer prompt fallback. The agent is a productivity tool, not a mission-critical system. Recovery from failure requires VM restart and Ollama model reload, estimated at 2-5 minutes.

---

## 5. NIST 800-53 Control Baseline

A Moderate system categorization triggers the **NIST 800-53B Moderate Control Baseline**.

### Controls Currently Implemented

| Control ID | Control Name | Status |
|---|---|---|
| AC-3 | Access Enforcement | ✅ Implemented |
| AC-6 | Least Privilege | ✅ Implemented |
| AC-7 | Unsuccessful Login Attempts | ✅ Implemented |
| AC-8 | System Use Notification | ✅ Implemented |
| AC-17 | Remote Access | ✅ Implemented |
| AU-2 | Event Logging | ✅ Implemented |
| AU-12 | Audit Record Generation | ✅ Implemented |
| CM-2 | Baseline Configuration | ✅ Implemented |
| CM-3 | Configuration Change Control | ✅ Implemented |
| CM-6 | Configuration Settings | ✅ Implemented |
| IA-2 | Identification and Authentication | ✅ Implemented |
| IA-5 | Authenticator Management | ✅ Implemented |
| SC-7 | Boundary Protection | ✅ Implemented |
| SC-8 | Transmission Confidentiality | ✅ Implemented |
| SC-39 | Process Isolation | ✅ Implemented |
| SI-2 | Flaw Remediation | ✅ Implemented |

### Moderate Baseline Gaps (Accepted for Non-Production Deployment)

| Control ID | Control Name | Rationale for Gap |
|---|---|---|
| IR-4 | Incident Handling | Manual incident response documented in manage.md; no automated IR tooling |
| CP-9 | System Backup | VM snapshots taken at major milestones; no automated backup schedule |
| SI-4 | System Monitoring | System monitoring via daily automated health check (cron), auditd event logging, and fail2ban. No centralized SIEM; logs reviewed manually per host. |

These gaps are accepted risks given the non-production, portfolio nature of this deployment and are documented in docs/ai-rmf/manage.md.

---

## 6. Cross-References

| Document | Relevance |
|---|---|
| `docs/ai-rmf/govern.md` | Authorization boundary, system purpose, risk tolerance |
| `docs/ai-rmf/map.md` | 14 risks identified and mapped to this categorization |
| `docs/ai-rmf/measure.md` | Live test evidence supporting control effectiveness |
| `docs/ai-rmf/manage.md` | Risk treatment decisions, incident log, monitoring procedures |
| `README.md` | NIST 800-53 controls implementation table, risk register |

---

## Revision History

| Date | Change | Author |
|---|---|---|
| 2026-05-15 | Initial FIPS 199 categorization — NIST 800-37 Step 2 | Lester L. Artis Jr. |
