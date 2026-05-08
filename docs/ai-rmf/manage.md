# NIST AI RMF — MANAGE Function
## Help Desk AI Triage Agent

**Document Type:** AI Risk Treatment & Continuous Monitoring  
**Framework:** NIST AI Risk Management Framework (AI RMF 1.0)  
**Function:** MANAGE  
**System:** Help Desk AI Triage Agent  
**Date:** 2026-05-07  
**Status:** Implemented  

---

## Overview

The MANAGE function defines how identified and measured AI risks are treated,
monitored, and improved over time. It closes the loop between risk
identification (MAP) and risk evidence (MEASURE) by establishing ongoing
processes that keep risk at an acceptable level.

MANAGE answers: *what do we do about risks — now and continuously?*

---

## Risk Treatment Decisions

For each risk identified in MAP, a treatment decision has been made:

| Risk ID | Risk | Treatment | Rationale |
|---|---|---|---|
| MAP-001 | Prompt injection | **Mitigate** | `sanitize_input()` implemented and tested |
| MAP-002 | Jailbreak attempt | **Mitigate** | `sanitize_input()` strips common jailbreak patterns |
| MAP-003 | Social engineering | **Mitigate** | Input sanitization + structured pipeline limits impact |
| MAP-004 | FAISS deserialization | **Mitigate** | Integrity hash monitoring implemented |
| MAP-005 | RAG poisoning | **Mitigate** | Hash verification on every load + docs in version control |
| MAP-006 | Knowledge base integrity | **Mitigate** | FAISS hash baseline established |
| MAP-007 | Malformed JSON output | **Mitigate** | Retry logic (3 attempts) + empty response detection implemented |
| MAP-008 | Silent data corruption | **Mitigate** | Fallback defaults on all JSON-returning functions |
| MAP-009 | Denial of service | **Mitigate** | Rate limiting implemented (10s cooldown) |
| MAP-010 | Resource exhaustion | **Mitigate** | Rate limiting reduces Ollama overload risk |
| MAP-011 | Hallucinated policy guidance | **Mitigate** | Synthesizer prompt enforces citation and uncertainty acknowledgment |
| MAP-012 | Overconfident response | **Mitigate** | Escalation path added to synthesizer prompt |
| MAP-013 | Missing embedding model | **Mitigate** | Automated model availability check in deploy.sh |
| MAP-014 | Embedding model version change | **Accept** | Low impact; rebuild vector store procedure documented |

---

## Incident Response Plan

### AI-Specific Incidents

#### IR-1 — Prompt Injection Detected

**Trigger:** Sanitized input differs significantly from raw input  
**Indicators:** Injection patterns in system logs, unexpected agent behavior  
**Response:**
1. Review systemd journal for the session: `sudo journalctl -u helpdesk-agent -n 100`
2. Identify the injection pattern used
3. Add pattern to `sanitize_input()` in `app.py`
4. Push fix via CI/CD pipeline: `git push` → `ssh helpdesk-ai-server "~/deploy.sh"`
5. Document in this file under Incident Log

#### IR-2 — FAISS Integrity Failure

**Trigger:** Hash mismatch detected during deploy or manual check  
**Indicators:** Deploy script exits with `[FAIL] FAISS index hash mismatch`  
**Response:**
1. Immediately stop the agent: `sudo systemctl stop helpdesk-agent`
2. Do not restart until integrity is confirmed
3. Compare current hash against known-good baseline (stored in password manager)
4. If tampered — rebuild vector store from source documents: `uv run python ingest.py`
5. Verify new hash matches expected post-build hash
6. Restart agent: `sudo systemctl start helpdesk-agent`
7. Document incident in Incident Log

#### IR-3 — Agent Producing Harmful or Incorrect Guidance

**Trigger:** User reports incorrect policy citation or dangerous recommendation  
**Indicators:** User feedback, IT staff escalation  
**Response:**
1. Document the exact ticket text and agent response
2. Test manually to reproduce
3. Identify whether issue is in classifier, researcher, recommender, or synthesizer
4. Update relevant prompt in `tools.py` or `agent.py`
5. Push fix via CI/CD pipeline
6. Document in Incident Log

#### IR-4 — Unauthorized SSH Access Attempt

**Trigger:** fail2ban bans an IP, or multiple failed auth attempts in auth.log  
**Indicators:** `sudo fail2ban-client status sshd` shows banned IPs  
**Response:**
1. Note the banned IP: `sudo fail2ban-client status sshd`
2. Review auth log: `sudo tail -50 /var/log/auth.log`
3. If attack ongoing — extend ban time: `sudo fail2ban-client set sshd bantime 86400`
4. Review UFW rules for additional restrictions if needed
5. Document in Incident Log

---

## Continuous Monitoring

### Daily Checks

The following checks should be performed daily to maintain situational awareness:

```bash
# 1. Service health
sudo systemctl status helpdesk-agent ollama

# 2. Failed login attempts
sudo fail2ban-client status sshd

# 3. Identity file changes
sudo ausearch -k identity --start today

# 4. Privilege escalation attempts
sudo ausearch -k privilege_escalation --start today

# 5. Disk usage
df -h
```

### Weekly Checks

```bash
# 1. FAISS integrity verification
cd ~/helpdesk-agent
ACTUAL=$(.venv/bin/python3 -c "from rag import get_index_hash; print(get_index_hash())")
echo "Current hash: $ACTUAL"
# Compare against known-good hash stored in password manager

# 2. Review systemd journal for agent errors
sudo journalctl -u helpdesk-agent --since "7 days ago" | grep -i "error\|fail\|warn"

# 3. Check for available security updates
sudo apt list --upgradable 2>/dev/null | grep -i security

# 4. Review UFW logs
sudo grep "UFW BLOCK" /var/log/ufw.log | tail -20
```

### Monitoring Evidence — 2026-05-07

**Audit log review (identity changes today):**
- Result: Only `CONFIG_CHANGE` events from auditd boot initialization
- No unauthorized identity file modifications detected
- Status: ✅ Clean

**Audit log review (privilege escalation today):**
- Result: Only `CONFIG_CHANGE` events from auditd boot initialization
- No unauthorized privilege escalation attempts detected
- Status: ✅ Clean

**Fail2ban status:**
```
Currently failed:  0
Total failed:      0
Currently banned:  0
Total banned:      0
```
- Status: ✅ Clean — no brute force attempts detected

---

## Improvement Plan

### Short Term (Next Sprint)

| Item | Risk Addressed | Priority |
|---|---|---|
| Add Pydantic schema validation to `_chat_json()` | MAP-007, MAP-008 | High |
| Add embedding model availability check to deploy script | MAP-013 | Medium |
| Add automated FAISS integrity check to deploy script | MAP-004 | High |
| Remove temporary port 22 UFW rule | Infrastructure | High |

### Medium Term

| Item | Risk Addressed | Priority |
|---|---|---|
| Implement MITRE ATLAS threat model | MAP-003, MAP-005 | High |
| Complete OWASP LLM Top 10 full assessment | Multiple | High |
| Add structured logging for sanitized inputs | MAP-001 | Medium |
| Implement vector store rebuild automation | MAP-005, MAP-006 | Medium |

### Long Term

| Item | Risk Addressed | Priority |
|---|---|---|
| Implement human-in-the-loop review for Critical tickets | GOVERN G3 | Medium |
| Add response confidence scoring | MAP-011, MAP-012 | Medium |
| Implement automated red-team testing | MAP-001, MAP-002 | Low |

---

## Incident Log

| Date | Incident | Severity | Response | Status |
|---|---|---|---|---|
| — | No incidents recorded | — | — | Clean |

---

## Control Mapping

| AI RMF Control | NIST 800-53 | Implementation | Status |
|---|---|---|---|
| MANAGE 1.1 | IR-4, IR-8 | Incident response plan defined | ✅ |
| MANAGE 1.2 | CA-7 | Continuous monitoring procedures documented | ✅ |
| MANAGE 2.2 | SI-7 | FAISS integrity monitoring active | ✅ |
| MANAGE 2.4 | CM-3 | CI/CD pipeline for controlled changes | ✅ |
| MANAGE 3.1 | SA-10 | Improvement plan documented | ✅ |
| MANAGE 4.1 | AU-6 | Audit log review procedures defined | ✅ |

---

## Revision History

| Date | Change | Author |
|---|---|---|
| 2026-05-07 | Initial MANAGE document — risk treatment, IR plan, monitoring evidence | LesCondones |
