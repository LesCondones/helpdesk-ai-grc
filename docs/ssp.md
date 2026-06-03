# System Security Plan (SSP)
## Help Desk AI Triage Agent

**Document Type:** System Security Plan  
**Framework:** NIST SP 800-37 Rev 2, NIST SP 800-53 Rev 5  
**System:** Help Desk AI Triage Agent  
**Date:** 2026-05-16  
**Status:** Initial  
**Classification:** Unclassified / Non-Production Portfolio Project  

---

## 1. System Identification

| Attribute | Value |
|---|---|
| System Name | Help Desk AI Triage Agent |
| System Type | AI-enabled IT support tool (RAG-based multi-agent pipeline) |
| Purpose | Triage and classify IT support tickets submitted by end users and IT staff. The agent classifies tickets by team and urgency, summarizes the issue, retrieves relevant policy guidance from a FAISS vector store, and synthesizes a structured response via a local LLM. |
| Deployment | Ubuntu 24.04 LTS server, VMware Fusion, aarch64 |
| Users | IT staff and end users submitting support tickets |
| Authorization Boundary | Single Ubuntu 24.04 LTS VM running: Streamlit web UI (HTTPS via Caddy), LangGraph multi-agent pipeline, Ollama local inference engine, FAISS vector store over SANS policy documents. No data crosses the VM boundary. |
| Data Types | IT support ticket text (free-form, no PII required); SANS policy documents (publicly available). No personally identifiable information, credentials, or classified data is processed. |
| External Dependencies | None. All model inference is local via Ollama. No external APIs. No cloud services. No data is transmitted externally. Source code is pulled from GitHub at deployment time only. |
| Operational Status | Prototype / Portfolio — NOT approved for production use. Not authorized to process CUI, PII, or classified data. |

---

## 2. System Categorization

Formal categorization was performed under FIPS 199 and NIST SP 800-60 as part of NIST 800-37 Step 2. Full rationale and impact analysis are documented in `docs/categorization.md`.

| Security Objective | Impact Level | Rationale |
|---|---|---|
| Confidentiality | Low | No PII, no sensitive data processed; public SANS knowledge base; local inference only |
| Integrity | Moderate | Incorrect AI guidance could cause wrong IT actions, misconfigurations, or extended downtime |
| Availability | Moderate | Manual fallback exists; no mission-critical dependency; no SLA defined |

**SC = {(Confidentiality, Low), (Integrity, Moderate), (Availability, Moderate)}**

**Overall System Categorization: MODERATE** (high-water mark across all three objectives)

This triggers the **NIST 800-53B Moderate Control Baseline**. Three baseline gaps (IR-4, CP-9, SI-4) are accepted risks for this non-production deployment. See `docs/categorization.md` for full FIPS 199 analysis.

---

## 3. Applicable Standards

| Standard | Version | Application |
|---|---|---|
| NIST SP 800-53 | Rev 5 | Security control catalog — 16 controls implemented across server and application layers |
| NIST AI RMF | 1.0 | AI-specific risk governance — all four functions (Govern, Map, Measure, Manage) fully documented |
| NIST SP 800-37 | Rev 2 | Risk Management Framework — system categorization, control selection, and implementation |
| FIPS 199 | — | Standards for Security Categorization — determines Moderate baseline |
| OWASP LLM Top 10 | 2025 | AI application vulnerability assessment — 7 Green / 3 Yellow / 0 Red |
| MITRE ATLAS | v2 | Adversarial ML threat modeling — 10 techniques assessed across 5 tactics |

---

## 4. Roles and Responsibilities

| Role | Individual | Responsibilities |
|---|---|---|
| System Owner | Lester L. Artis Jr. | Overall accountability for the system; approves security decisions; owns risk acceptance |
| Information System Security Officer (ISSO) | Lester L. Artis Jr. | Maintains security documentation; ensures controls are implemented and assessed; manages incident log |
| Developer / Operator | Lester L. Artis Jr. | Implements hardening controls; manages CI/CD pipeline; applies patches and updates |
| End Users | IT Staff and end users | Submit support tickets via the Streamlit UI; review AI-generated guidance before acting on it |

> **Note:** GRC documentation in this repository is maintained by the automated GRC Agent operating on branch `main` of `LesCondones/helpdesk-ai-grc`, under the authorization of the System Owner.

---

## 5. System Environment

### Hardware and Operating System

| Component | Value |
|---|---|
| Host Platform | Apple Silicon Mac (aarch64) |
| Hypervisor | VMware Fusion 13+ |
| Guest OS | Ubuntu 24.04.4 LTS (aarch64) |
| Architecture | aarch64 (ARM64) |
| User Account | `grcadmin` (non-root) |

### Software Stack

| Component | Technology | Purpose |
|---|---|---|
| Web UI | Streamlit | User-facing ticket submission interface |
| Agent Framework | LangGraph StateGraph | Multi-agent pipeline orchestration (5 nodes: classifier, summarizer, researcher, recommender, synthesizer) |
| LLM Inference | Ollama — llama3.2:3b | Local language model inference; not exposed externally |
| Embeddings | Ollama — nomic-embed-text | Vector embeddings for FAISS knowledge base retrieval |
| Vector Store | FAISS | RAG retrieval over SANS policy documents |
| RAG Documents | SANS Policy Templates | Publicly available IT security policy knowledge base |
| Reverse Proxy | Caddy | TLS termination; HTTPS on port 443; Streamlit bound to localhost only |
| Process Manager | systemd | Service lifecycle management, sandboxing, and auto-restart |
| Firewall | UFW | Default deny inbound; explicit allow on ports 2222, 80, 443 |
| Intrusion Prevention | fail2ban | SSH brute-force protection (maxretry=3, bantime=3600s) |
| Audit Logging | auditd | 13-rule custom ruleset tracking identity, sudo, exec, and network changes |
| CI/CD | GitHub → `deploy.sh` | Code deployment via SSH from developer workstation |

### Network Exposure

| Port | Service | Exposure |
|---|---|---|
| 443/tcp | Caddy (HTTPS → Streamlit) | External — authorized users |
| 2222/tcp | SSH | External — ED25519 key auth only |
| 80/tcp | HTTP (redirect to HTTPS) | External |
| 8501/tcp | Streamlit (direct) | Localhost only |
| 11434/tcp | Ollama | Localhost only |

---

## 6. Control Implementation Summary

All 16 controls are drawn from the NIST 800-53B Moderate baseline. Implementation evidence is in `README.md` and `scripts/phase1-hardening.sh`.

| Control ID | Control Name | Implementation | Status |
|---|---|---|---|
| AC-3 | Access Enforcement | SSH key-only auth; `AllowUsers` directive in `configs/ssh/99-hardening.conf` | ✅ Implemented |
| AC-6 | Least Privilege | Non-root `grcadmin` user; systemd `NoNewPrivileges=yes` and `ProtectSystem=strict` | ✅ Implemented |
| AC-7 | Unsuccessful Login Attempts | fail2ban `maxretry=3`, `bantime=3600s` on SSH jail | ✅ Implemented |
| AC-8 | System Use Notification | SSH legal notice banner configured in `configs/ssh/99-hardening.conf` | ✅ Implemented |
| AC-17 | Remote Access | SSH on non-default port 2222; ED25519 key authentication; password auth disabled system-wide | ✅ Implemented |
| AU-2 | Event Logging | auditd active with 13-rule custom ruleset in `configs/audit/hardening.rules` | ✅ Implemented |
| AU-12 | Audit Record Generation | auditd tracks identity changes, sudo usage, exec calls, network config changes, and log tampering | ✅ Implemented |
| CM-2 | Baseline Configuration | Fully automated via `scripts/phase1-hardening.sh`; all settings version-controlled in this repository | ✅ Implemented |
| CM-3 | Configuration Change Control | All changes tracked in git; temporary rules reverted and committed; deployments via `deploy.sh` | ✅ Implemented |
| CM-6 | Configuration Settings | SSH hardening applied via drop-in config `configs/ssh/99-hardening.conf` | ✅ Implemented |
| IA-2 | Identification and Authentication | ED25519 SSH key required; `PasswordAuthentication no` enforced; cloud-init override patched | ✅ Implemented |
| IA-5 | Authenticator Management | SSH key passphrase required; no shared or default credentials | ✅ Implemented |
| SC-7 | Boundary Protection | UFW default deny inbound; explicit allow rules for ports 2222, 80, 443 only; nmap-verified 2026-05-14 | ✅ Implemented |
| SC-8 | Transmission Confidentiality | Caddy reverse proxy with TLS certificate; Streamlit restricted to localhost only | ✅ Implemented |
| SC-39 | Process Isolation | systemd `NoNewPrivileges=yes`, `PrivateTmp=yes`, `ProtectSystem=strict`; `ReadWritePaths` scoped to agent directory | ✅ Implemented |
| SI-2 | Flaw Remediation | `apt upgrade` applied; `unattended-upgrades` configured for automatic security patches | ✅ Implemented |

### Accepted Moderate Baseline Gaps

| Control ID | Control Name | Gap Rationale |
|---|---|---|
| IR-4 | Incident Handling | Manual incident response documented in `docs/ai-rmf/manage.md`; no automated IR tooling deployed |
| CP-9 | System Backup | VM snapshots taken at major milestones; no automated backup schedule |
| SI-4 | System Monitoring | ✅ Implemented — Grafana + Loki SIEM deployed Phase 9. Dashboard monitors auditd, auth, fail2ban, helpdesk-agent, health-check, and syslog. Evidence: docs/poam.md POA-001 closed. |

These gaps are accepted risks for this non-production, portfolio-scope deployment and are documented in `docs/ai-rmf/manage.md`.

---

## 7. AI-Specific Controls

AI risk governance follows NIST AI RMF 1.0 across all four functions. All functions are fully documented.

| Function | Scope | Key Controls Implemented | Document |
|---|---|---|---|
| GOVERN | AI risk policies, accountability, risk tolerance, human oversight model | Risk tolerance thresholds defined; human-on-the-loop oversight required before acting on AI output; GRC agent authorization documented | `docs/ai-rmf/govern.md` |
| MAP | Risk identification across 6 attack surfaces; 14 risks catalogued and scored | Risks mapped to OWASP LLM Top 10, MITRE ATLAS, and NIST 800-53; likelihood and impact scored; consolidated risk map maintained | `docs/ai-rmf/map.md` |
| MEASURE | Quantitative and qualitative control effectiveness testing | Live injection test evidence; FAISS integrity baseline established; rate limiting verification; response quality baseline; residual risk measurement | `docs/ai-rmf/measure.md` |
| MANAGE | Risk treatment decisions, incident log, ongoing monitoring | All 14 MAP risks formally treated (Mitigate or Accept); incident log maintained with 5 resolved incidents; residual risks tracked | `docs/ai-rmf/manage.md` |

### OWASP LLM Top 10 Summary

**Result: 7 Green / 3 Yellow / 0 Red.** Full per-item assessment in `docs/owasp/llm-top10.md`.

### MITRE ATLAS Threat Model Summary

10 adversarial ML techniques assessed across 5 tactics: 8 Mitigated / 2 Accepted (AML.T0044 Invert ML Model, AML.T0057 LLM Data Leakage). Full threat model in `docs/threat-model/mitre-atlas.md`.

---

## 8. Interconnections

| Connection | Type | Direction | Data Exchanged | Authorization |
|---|---|---|---|---|
| GitHub — `LesCondones/help-desk-agent` | Code repository | Inbound at deploy time only | Source code; no system or user data | Authorized — `deploy.sh`, SSH key auth |
| GitHub — `LesCondones/helpdesk-ai-grc` | GRC documentation repository | Bidirectional | Markdown documentation only; no system data | Authorized — GRC Agent, SSH key auth |
| Ubuntu package repositories | OS updates | Outbound | Package metadata and binaries via `apt` | Authorized — `unattended-upgrades` |

**No external APIs are used. No cloud AI services are used. No PII or user data is transmitted externally.** All LLM inference runs locally via Ollama on `localhost:11434`.

---

## 9. Residual Risks

Residual risks after all treatment decisions are formally documented in the Risk Treatment Decisions table in `docs/ai-rmf/manage.md`. The following items carry accepted residual exposure as of 2026-05-16:

| Risk ID | Risk | Treatment | Residual Status | Notes |
|---|---|---|---|---|
| MAP-011 | Hallucinated policy guidance | Accept | 🟡 Monitored | Synthesizer prompt constrains output to knowledge base citations; hallucination cannot be fully eliminated at this model scale |
| MAP-012 | Overconfident response on unknown issues | Accept | 🟡 Monitored | Uncertainty acknowledgment in synthesizer prompt; human escalation path present in all responses |
| MAP-014 | Degraded retrieval from embedding model version change | Accept | 🟢 Low | Low probability event; manual re-embedding procedure is documented |

All other MAP risks (MAP-001 through MAP-010, MAP-013) are `✅ Mitigated` or `✅ Monitored` following Phase 7 controls. All 13 infrastructure R-NNN risks in `README.md` are `✅ Mitigated` or `✅ Monitored`.

---

## 10. Related Documents

| Document | Path | Purpose |
|---|---|---|
| Project Overview & Risk Register | `README.md` | NIST 800-53 controls table, R-NNN infrastructure risk register, OWASP summary, MITRE ATLAS summary, system architecture |
| System Categorization | `docs/categorization.md` | FIPS 199 categorization, NIST 800-37 Step 2, Moderate baseline selection, accepted gaps |
| AI RMF — Govern | `docs/ai-rmf/govern.md` | AI risk governance policies, accountability structure, risk tolerance thresholds, human oversight model |
| AI RMF — Map | `docs/ai-rmf/map.md` | 14 AI risks identified across 6 attack surfaces; control mapping to OWASP, MITRE, and NIST 800-53 |
| AI RMF — Measure | `docs/ai-rmf/measure.md` | Live control effectiveness evidence; injection test results; FAISS integrity baseline; residual risk measurements |
| AI RMF — Manage | `docs/ai-rmf/manage.md` | Risk treatment decisions for all 14 MAP risks; incident log; accepted residual risks |
| OWASP LLM Top 10 Assessment | `docs/owasp/llm-top10.md` | Detailed per-item OWASP LLM vulnerability assessment with mitigations |
| MITRE ATLAS Threat Model | `docs/threat-model/mitre-atlas.md` | Adversarial ML threat model; 10 techniques across 5 tactics |
| Control Traceability Matrix | `docs/ctm.md` | All 287 Moderate baseline controls with implemented/N/A/POA&M status and justifications |
| Phase 1 Hardening Script | `scripts/phase1-hardening.sh` | Automated OS hardening — SSH, UFW, auditd, fail2ban, unattended-upgrades |
| CI/CD Deploy Script | `scripts/deploy.sh` | Automated deployment pipeline via SSH from developer workstation |
| Daily Health Check | `scripts/daily-health-check.sh` | Cron-based daily system health verification script |
| SSH Hardening Config | `configs/ssh/99-hardening.conf` | SSH drop-in hardening configuration (port, auth, restrictions) |
| auditd Rules | `configs/audit/hardening.rules` | Custom 13-rule auditd ruleset |
| fail2ban Config | `configs/fail2ban/jail.local` | SSH jail configuration (maxretry, bantime) |
| Caddy Config | `configs/Caddyfile` | Reverse proxy TLS configuration |
| systemd Service Definition | `configs/helpdesk-agent.service` | systemd unit with sandboxing directives (NoNewPrivileges, PrivateTmp, ProtectSystem) |

---

## Known Limitations

- **Segregation of Duties (AC-5):** System Owner, ISSO, and Developer roles are held by the same individual. In a production environment these roles must be separated. The ISSO cannot be the same person as the Developer.
- **Tailored Baseline (PL-2):** 16 of 287 Moderate baseline controls are explicitly implemented. All remaining controls are documented in `docs/ctm.md` as either Not Applicable with justification or on the POA&M.
- **CUI Data Spillage (SC-7/SI-3):** No formal CUI spillage procedure exists beyond Rules of Behavior prohibiting PII/CUI input. In production a formal data spillage IR procedure would be required.
- **Backup and Recovery (CP-9):** Automated backup schedule not yet implemented. Manual VM snapshots taken at major milestones. Automated backup is planned in POA&M POA-002.

---

## Section 12 — Continuous Monitoring Plan

| Activity | Frequency | Method | Responsible Party | Evidence |
|---|---|---|---|---|
| Vulnerability scanning | Monthly | nmap port scan | Lester L. Artis Jr. | Scan output saved to /var/log |
| Audit log review | Weekly | Manual review of auditd and fail2ban logs | Lester L. Artis Jr. | Log review notes |
| Health check review | Daily (automated) | daily-health-check.sh via cron | Automated | /var/log/helpdesk-health-*.log |
| SIEM log review | Weekly | Grafana + Loki dashboard review | Lester L. Artis Jr. | Grafana dashboard screenshots |
| FAISS integrity check | Every deploy | SHA256 hash verification in deploy.sh | Automated | Deploy log |
| Security updates | As available | unattended-upgrades | Automated | apt log |
| Control re-assessment | Annual or upon major architecture change | SSP review | Lester L. Artis Jr. | Updated SSP revision history |
| Penetration testing | Annual | Internal red team engagement | Lester L. Artis Jr. | docs/pentest-report.md |

---

## Appendix A — Rules of Behavior

All users and administrators of this system must comply with the following rules:

### User Rules
1. Users shall not input Classified, Secret, Top Secret, or CUI data into ticket submissions
2. Users shall not input Personally Identifiable Information (PII) including names, SSNs, addresses, or financial data
3. Users shall verify all AI-generated guidance against official SANS policy documents before taking action
4. Users shall report any unexpected or concerning AI responses to the system administrator immediately
5. Users shall not attempt to manipulate, jailbreak, or bypass AI safety controls

### Administrator Rules
1. Administrators shall not bypass or disable input sanitization controls in sanitize_input()
2. Administrators shall not modify SYNTHESIZER_PROMPT or FOLLOWUP_PROMPT to remove safety instructions
3. Administrators shall not expose Ollama inference endpoint beyond localhost
4. Administrators shall review audit logs weekly per the Continuous Monitoring Plan
5. Administrators shall apply security updates within 30 days of release
6. All configuration changes must be committed to GitHub with descriptive commit messages per CM-3

### AI-Specific Rules
1. No user shall attempt prompt injection, jailbreaking, or persona hijacking attacks against the agent
2. The agent shall not be used as the sole basis for security decisions without human review
3. Agent outputs shall be treated as advisory only — human IT staff must verify before acting

### Acknowledgment
All users acknowledge these rules upon system access via the SSH legal notice banner (AC-8).

---

## 11. Revision History

| Date | Change | Author |
|---|---|---|
| 2026-05-16 | Initial SSP — System Security Plan for Help Desk AI Triage Agent | Lester L. Artis Jr. |
| 2026-05-25 | Added Operational Status row to System Identification; added Known Limitations section; added Section 12 — Continuous Monitoring Plan; added Appendix A — Rules of Behavior; added CTM reference to Related Documents (per SCA findings) | Lester L. Artis Jr. |
