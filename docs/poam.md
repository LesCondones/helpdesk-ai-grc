# Plan of Action and Milestones (POA&M)
## Help Desk AI Triage Agent

**Document Type:** Plan of Action and Milestones  
**Framework:** NIST SP 800-37 Rev 2, NIST SP 800-53 Rev 5  
**System:** Help Desk AI Triage Agent  
**Date:** 2026-05-16  
**Status:** Active  
**Classification:** Unclassified / Non-Production Portfolio Project  

---

## 1. Purpose

This Plan of Action and Milestones (POA&M) tracks all residual weaknesses, control gaps, and planned mitigations identified for the Help Desk AI Triage Agent. Items are sourced from the FIPS 199 categorization baseline gap analysis (`docs/categorization.md`), OWASP LLM Top 10 assessment (`docs/owasp/llm-top10.md`), and NIST AI RMF risk treatment decisions (`docs/ai-rmf/manage.md`).

Each POA&M item remains open until the milestone is completed and evidence is committed to this repository. Completed items are retained for audit continuity.

---

## 2. POA&M Table

| Item ID | Weakness | Source | Severity | Scheduled Completion | Responsible Party | Milestone | Status |
|---|---|---|---|---|---|---|---|
| POA-001 | No SIEM or centralized log aggregation | SI-4 gap — `docs/categorization.md` | High | Phase 9 | Lester L. Artis Jr. | Grafana + Loki SIEM deployed Phase 9 — dashboard active with 6 panels monitoring auditd, auth, fail2ban, helpdesk-agent, health-check, syslog | ✅ Completed |
| POA-002 | No automated system backup schedule | CP-9 gap — `docs/categorization.md` | Medium | Phase 10 | Lester L. Artis Jr. | Implement automated VM snapshots | Planned |
| POA-003 | No automated incident handling | IR-4 gap — `docs/categorization.md` | Medium | Phase 9 | Lester L. Artis Jr. | Integrate Wazuh alerting with IR procedures | Planned |
| POA-004 | No confidence scoring on AI output | LLM09 — `docs/owasp/llm-top10.md` | Medium | Phase 7 | Lester L. Artis Jr. | Add confidence scoring to synthesizer node | Completed |
| POA-005 | No server-side input logging for sanitized inputs | LLM01, AU-2 — `docs/ai-rmf/map.md` | Medium | Phase 7 | Lester L. Artis Jr. | Add rotating file logger for sanitized inputs | Completed |
| POA-006 | No SBOM for dependency tracking | LLM05, SA-12 — `docs/owasp/llm-top10.md` | Low | Phase 10 | Lester L. Artis Jr. | Generate SBOM via `uv export` | Planned |
| POA-007 | No output length validation on LLM responses | LLM02 — `docs/owasp/llm-top10.md` | Low | Phase 7 | Lester L. Artis Jr. | Add output truncation in Streamlit | Planned |

---

### Item Detail

#### POA-001 — No SIEM or Centralized Log Aggregation
- **Control Gap:** SI-4 (System Monitoring) — Moderate baseline requires active monitoring and alerting
- **Current State:** Daily health check script (`scripts/daily-health-check.sh`) runs via cron; auditd logs written locally; no centralized aggregation or real-time alerting
- **Risk:** Security events (brute-force escalation, file integrity changes, anomalous access) may go undetected between daily health checks
- **Planned Mitigation:** Deploy Wazuh agent on the Ubuntu VM with centralized dashboard; configure alerts for auditd events, fail2ban triggers, and file integrity changes
- **Mapped Risks:** R-002, MAP-011

#### POA-002 — No Automated System Backup Schedule
- **Control Gap:** CP-9 (System Backup) — Moderate baseline requires periodic backup of system and user-level information
- **Current State:** VM snapshots taken manually at major project milestones; no scheduled or automated backup
- **Risk:** A VM corruption or accidental deletion between milestones could cause loss of configuration, audit logs, and vector store data
- **Planned Mitigation:** Implement automated VMware Fusion snapshots on a scheduled cadence; document recovery procedure
- **Mapped Risks:** R-008

#### POA-003 — No Automated Incident Handling
- **Control Gap:** IR-4 (Incident Handling) — Moderate baseline requires an incident handling capability
- **Current State:** Manual incident response process documented in `docs/ai-rmf/manage.md`; no automated detection-to-response pipeline
- **Risk:** Incident response time depends entirely on manual log review; high-severity events may not trigger timely response
- **Planned Mitigation:** Integrate Wazuh alerting (from POA-001) with documented IR procedures; define automated alert thresholds for Critical and High events
- **Depends On:** POA-001 (Wazuh deployment)
- **Mapped Risks:** R-001, R-004

#### POA-004 — No Confidence Scoring on AI Output ✅
- **Control Gap:** LLM09 (Overreliance) — users may act on AI output without understanding its reliability
- **Current State (at identification):** Synthesizer returned structured responses with no indication of certainty level
- **Mitigation Implemented:** Confidence scoring added to synthesizer node in Phase 7
- **Evidence:** Phase 7 commit history in `help-desk-agent` repository

#### POA-005 — No Server-Side Input Logging ✅
- **Control Gap:** LLM01 (Prompt Injection), AU-2 (Event Logging) — sanitized inputs not logged for forensic review
- **Current State (at identification):** `sanitize_input()` stripped injection patterns but did not log the original or sanitized input
- **Mitigation Implemented:** Rotating file logger added for sanitized inputs in Phase 7; logs retained per AU-12 requirements
- **Evidence:** Phase 7 commit history in `help-desk-agent` repository

#### POA-006 — No SBOM for Dependency Tracking
- **Control Gap:** LLM05 (Supply Chain Vulnerabilities), SA-12 (Supply Chain Protection)
- **Current State:** `uv.lock` pins exact dependency versions; no machine-readable SBOM exported
- **Risk:** Dependency vulnerabilities cannot be tracked by automated scanning tools without a formal SBOM artifact
- **Planned Mitigation:** Run `uv export --format requirements-txt` and generate CycloneDX or SPDX SBOM; commit artifact to repository
- **Mapped Risks:** LLM05

#### POA-007 — No Output Length Validation on LLM Responses
- **Control Gap:** LLM02 (Insecure Output Handling) — unbounded LLM output could cause UI rendering issues or client-side injection via oversized payloads
- **Current State:** Streamlit renders synthesizer output without length truncation
- **Risk:** A model producing an abnormally large response could degrade UI performance or exploit Streamlit markdown rendering
- **Planned Mitigation:** Add output length cap (e.g., 4000 characters) and truncation warning in Streamlit before rendering synthesizer response
- **Mapped Risks:** MAP-008

---

## 3. Revision History

| Date | Change | Author |
|---|---|---|
| 2026-05-16 | Initial POA&M — 7 items across SI-4, CP-9, IR-4 gaps and LLM Top 10 findings | Lester L. Artis Jr. |
