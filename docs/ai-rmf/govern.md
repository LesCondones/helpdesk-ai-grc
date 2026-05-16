# NIST AI RMF — GOVERN Function
## Help Desk AI Triage Agent

**Document Type:** AI Risk Governance Policy  
**Framework:** NIST AI Risk Management Framework (AI RMF 1.0)  
**Function:** GOVERN  
**System:** Help Desk AI Triage Agent  
**Date:** 2026-05-06  
**Status:** Implemented  

---

## Overview

The GOVERN function establishes the policies, processes, and accountability structures that guide how AI risk is managed across the organization. It is the foundational function of the NIST AI RMF — all other functions (MAP, MEASURE, MANAGE) depend on GOVERN being in place first.

For the Help Desk AI Triage Agent, GOVERN defines:
- What the agent is authorized to do
- What it is explicitly prohibited from doing
- Who is accountable for its behavior
- What the acceptable risk tolerance is
- How human oversight is maintained

---

## G1 — Organizational Policies

### AI System Purpose Statement

The Help Desk AI Triage Agent is authorized to:

- Receive IT support tickets submitted by users
- Classify tickets by team and urgency level
- Summarize the issue type and problem description
- Query a FAISS vector store built from approved SANS policy documents
- Generate structured triage responses referencing retrieved policy content
- Recommend ordered action steps based on classification and knowledge base results

The agent is explicitly **NOT authorized** to:

- Access external systems, networks, or APIs
- Store, log, or retain personally identifiable information (PII)
- Make decisions on behalf of IT staff
- Modify system configurations or user accounts
- Escalate tickets automatically to external ticketing systems
- Execute any action beyond providing text-based guidance
- Override or contradict official IT policy without citation

### Accountability Structure

| Role | Responsibility |
|---|---|
| System Owner | Accountable for agent behavior, policy compliance, and risk acceptance |
| IT Staff | Human reviewers for escalated or uncertain tickets |
| End Users | Responsible for accurately describing their IT issues |

### Policy Basis

All agent responses are grounded in the following approved policy documents:

- SANS Access Management Policy
- SANS Acceptable Use Standard
- SANS Email Management Policy
- SANS Network Device Management Policy
- SANS Password Construction Standard
- SANS Perimeter Network Access Management Policy
- SANS Privileged Account Management Policy
- SANS Software Management Policy
- SANS Internet Usage Standard
- VPN Troubleshooting Runbook

---

## G2 — Risk Tolerance

### Acceptable Use Boundaries

| Scenario | Risk Level | Agent Action |
|---|---|---|
| Password reset guidance | Low | Provide step-by-step instructions citing policy |
| Account lockout | Low | Provide unlock procedure citing policy |
| VPN connectivity issue | Medium | Provide troubleshooting steps from runbook |
| Suspicious email / phishing | High | Escalate — recommend immediate human IT contact |
| Data breach indication | Critical | Escalate immediately — human intervention required |
| Request outside knowledge base | Medium | Acknowledge limitation, recommend human IT contact |
| Ambiguous or unclear ticket | Low-Medium | Request clarification, provide best-effort guidance |

### Uncertainty Policy

The agent is instructed to explicitly acknowledge uncertainty in the following cases:

1. The knowledge base retrieval returns no relevant policy excerpts
2. The ticket describes a scenario outside the scope of loaded policy documents
3. The recommended action requires elevated system access
4. The issue involves potential security incidents

**Implementation:** The synthesizer prompt explicitly instructs the model:
> *"If the issue is outside the scope of the knowledge base or requires elevated access, explicitly state: 'This issue requires human IT staff intervention. Please contact your IT helpdesk directly.'"*

**Framework Mapping:** NIST AI RMF GOVERN G2, OWASP LLM08 (Excessive Agency)

### Fabrication Prevention

The agent is explicitly instructed never to fabricate policy details. If policy excerpts are insufficient, it must acknowledge the limitation rather than generate plausible-sounding but unverified guidance.

**Implementation:** Synthesizer prompt instruction:
> *"Never fabricate policy details. If policy excerpts are insufficient, acknowledge the limitation clearly."*

**Framework Mapping:** NIST AI RMF GOVERN G2, OWASP LLM02 (Insecure Output Handling)

---

## G3 — Human Oversight

### Oversight Model

The Help Desk AI Triage Agent operates in a **human-on-the-loop** model:

- The agent processes tickets autonomously
- IT staff review agent responses before acting on them
- The agent explicitly identifies when human intervention is required
- No automated actions are taken — all recommendations require human execution

### Escalation Triggers

The agent is configured to recommend human IT staff contact when:

- The issue involves potential security incidents
- The issue requires elevated system privileges
- The knowledge base contains no relevant policy guidance
- The ticket describes actions outside the agent's authorized scope

### Override Policy

IT staff may override any agent recommendation. The agent's output is advisory only — it has no authority to enforce or execute recommendations.

### Monitoring

- All agent interactions are logged via systemd journal
- The Ubuntu server's auditd monitors all system-level activity
- fail2ban protects the SSH access to the server
- UFW firewall restricts network access to authorized ports only

---

## G4 — AI Risk Culture

### Transparency

- The agent identifies itself as an AI triage assistant in all responses
- Users are aware they are interacting with an automated system
- The knowledge base sources are documented and version-controlled
- All governance decisions are documented in this repository

### Continuous Improvement

- Policy documents in the knowledge base will be updated as new SANS templates are released
- The vector store (FAISS index) will be rebuilt when policy documents are updated
- Agent performance will be reviewed periodically against real IT ticket outcomes
- This governance document will be updated to reflect any changes to agent behavior or policy

---

## Control Mapping

| AI RMF Control | NIST 800-53 | OWASP LLM | Implementation |
|---|---|---|---|
| GOVERN G1 | AC-3, AC-6 | LLM08 | Agent authorization boundary defined in synthesizer prompt |
| GOVERN G2 | SI-12, AC-4 | LLM01, LLM02 | Uncertainty acknowledgment, no fabrication policy |
| GOVERN G3 | AC-2, IR-6 | LLM08 | Human escalation path in synthesizer prompt |
| GOVERN G4 | AT-2, CA-7 | — | Transparency, monitoring, continuous improvement |

---

## Revision History

| Date | Change | Author |
|---|---|---|
| 2026-05-06 | Initial document — GOVERN function implemented | Lester L. Artis Jr. |
| 2026-05-06 | Synthesizer prompt updated with uncertainty acknowledgment and escalation path | Lester L. Artis Jr. |
