# OWASP LLM Top 10 Assessment
## Help Desk AI Triage Agent

**Document Type:** AI Application Security Assessment  
**Framework:** OWASP Top 10 for Large Language Model Applications (v1.1)  
**System:** Help Desk AI Triage Agent  
**Date:** 2026-05-07  
**Status:** Implemented  

---

## Overview

The OWASP LLM Top 10 identifies the most critical security risks for
applications built on large language models. This assessment evaluates
the Help Desk AI Triage Agent against all ten risks, documents the
current implementation posture, and identifies residual gaps.

---

## LLM01 — Prompt Injection

**Risk:** Attackers manipulate LLM behavior through crafted inputs,
overriding system instructions or causing unintended actions.

### Attack Vectors for This System

**Direct injection** — malicious ticket text targeting any of the five
pipeline nodes (classifier, summarizer, researcher, recommender, synthesizer).

**Indirect injection** — malicious instructions embedded in FAISS-retrieved
policy document chunks that reach the synthesizer context.

### Current Implementation

```python
# app.py — input sanitization before pipeline entry
def sanitize_input(text: str) -> str:
    text = re.sub(r'ignore (previous|all|above) instructions?', '', ...)
    text = re.sub(r'you are now', '', ...)
    text = re.sub(r'system prompt', '', ...)
    text = re.sub(r'jailbreak', '', ...)
    text = re.sub(r'act as', '', ...)
    text = re.sub(r'pretend (you are|to be)', '', ...)
    return text[:2000].strip()
```

**Test results (2026-05-07):** All tested injection patterns stripped. ✅

### Gaps

- ✅ Unicode normalization implemented in Phase 5 — `unicodedata.normalize('NFKC')` strips zero-width spaces and homoglyphs
- ✅ Base64 detection implemented in Phase 5 — `sanitize_input()` now detects and blocks encoded payloads
- ✅ Server-side logging implemented — rotating file logger active at logs/inputs.log (AU-12, LLM01)

### Risk Rating

| Before controls | After controls |
|---|---|
| 🔴 Critical | 🟡 Medium |

**NIST 800-53:** SI-10 | **MITRE ATLAS:** AML.T0051

---

## LLM02 — Insecure Output Handling

**Risk:** LLM output is passed to downstream systems or rendered without
validation, enabling XSS, SSRF, privilege escalation, or remote code execution.

### Assessment

The agent renders output exclusively through Streamlit's `st.markdown()`
which sanitizes HTML by default. Output is never:
- Passed to a shell or subprocess
- Written to a database
- Used to construct system commands
- Sent to external APIs

The synthesizer is the only node that generates free-text output. All
other nodes return structured JSON consumed internally by the pipeline.

### Current Implementation

```python
# app.py — output rendered via Streamlit markdown
st.markdown(response)

# agent.py — synthesizer returns string only
return {"final_response": response.content}
```

### Gaps

- No output length validation — a very long response could degrade UI
- No content filtering on output — agent could theoretically output
  harmful guidance if synthesizer prompt is bypassed

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟡 Medium | 🟢 Low |

**NIST 800-53:** SI-12

---

## LLM03 — Training Data Poisoning

**Risk:** Training data is tampered with to introduce backdoors,
biases, or vulnerabilities into the model.

### Assessment

This system uses **llama3.2:3b** — a pre-trained model from Meta via
Ollama. The organization has no control over the base model training
data. However, the RAG knowledge base (FAISS + SANS policy docs) is
fully within the organization's control.

### RAG Poisoning Posture

- Policy documents sourced from official SANS templates only
- Vector store integrity monitored via SHA256 hash of `index.pkl`
- Hash logged on every load via `load_vector_store()`
- `docs/` directory protected by systemd `ProtectSystem=strict`
- `auditd` monitors all file system changes

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟡 Medium | 🟢 Low |

**NIST 800-53:** SI-7 | **MITRE ATLAS:** AML.T0020

---

## LLM04 — Model Denial of Service

**Risk:** Attackers overwhelm the LLM with resource-intensive requests,
causing degraded performance or complete unavailability.

### Attack Vectors for This System

Each ticket submission triggers **5 llama3.2:3b inference calls**:
classifier + summarizer (parallel) → researcher → recommender → synthesizer.

With an 8B parameter model at Q4_K_M quantization, each inference
consumes significant CPU/memory. Rapid ticket flooding could exhaust
system resources.

### Current Implementation

```python
# app.py — per-session rate limiting
time_since_last = time.time() - st.session_state.last_submission
if time_since_last < 10:
    st.warning(f"⚠️ Please wait {int(10 - time_since_last)} seconds...")
    st.stop()
```

### Gaps

- ✅ Server-side rate limiting implemented in Phase 5 — shared counter replaces per-session Streamlit session state
- ✅ Caddy reverse proxy provides connection-level protection in front of Streamlit
- Rate limiting ✅ implemented. Circuit breaker 🔲 planned — POA&M POA-003 (LLM04)

### Risk Rating

| Before controls | After controls |
|---|---|
| 🔴 Critical | 🟡 Medium |

**NIST 800-53:** SC-5

---

## LLM05 — Supply Chain Vulnerabilities

**Risk:** Vulnerable third-party components, models, or datasets
introduce risks into the AI application.

### Dependency Audit

| Component | Source | Risk | Status |
|---|---|---|---|
| llama3.2:3b | Meta via Ollama | Pre-trained model — no training data control | ✅ Accepted |
| LangChain | PyPI via uv | Active maintenance, widely audited | ✅ Low |
| LangGraph | PyPI via uv | Active maintenance | ✅ Low |
| FAISS | PyPI via uv | Facebook AI Research — stable | ✅ Low |
| Streamlit | PyPI via uv | Active maintenance | ✅ Low |
| Ollama | Direct install | Open source, actively maintained | ✅ Low |
| SANS policy docs | SANS Institute | Publicly available templates | ✅ Trusted |

### Dependency Management

- Dependencies managed via `uv` with locked versions in `uv.lock`
- Lock file committed to version control — reproducible builds
- `uv sync` on every deploy verifies dependency integrity

### Gaps

- No automated vulnerability scanning of Python dependencies
- No SBOM (Software Bill of Materials) generated

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟡 Medium | 🟢 Low |

**NIST 800-53:** SA-12

---

## LLM06 — Sensitive Information Disclosure

**Risk:** LLM reveals sensitive information — PII, credentials, system
details, or proprietary data — through its responses.

### Assessment

**No sensitive data exists in the system context:**
- Knowledge base contains only public SANS policy templates
- No PII is collected, stored, or processed
- No credentials or API keys in the codebase
- `.env` file contains no sensitive values
- Ollama bound to localhost — model API not exposed externally
- Technology stack disclosure removed from UI (ATLAS AML.T0000 fix)

### System Prompt Confidentiality

All five node system prompts (CLASSIFY_PROMPT, SUMMARIZE_PROMPT,
RECOMMEND_PROMPT, SYNTHESIZER_PROMPT) are defined in source code.
The sanitizer strips "system prompt" as an injection pattern, reducing
the risk of prompt extraction.

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟡 Medium | 🟢 Low |

**NIST 800-53:** SC-28, IA-5

---

## LLM07 — Insecure Plugin Design

**Risk:** LLM plugins or tools with excessive permissions enable
attackers to perform unauthorized actions.

### Assessment

The agent has **no external plugins or tool integrations**. The five
pipeline nodes call only:
- `ollama.chat()` — local inference, localhost only
- `FAISS.similarity_search()` — local vector store, read-only
- `json.loads()` — JSON parsing

No external APIs, no file system writes (outside the vector store
build), no shell commands, no database connections.

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟢 Low | 🟢 Low |

**Status:** ✅ Not applicable — no plugins implemented

---

## LLM08 — Excessive Agency

**Risk:** The LLM is given too much autonomy to perform actions with
real-world consequences without adequate human oversight.

### Assessment

The agent is explicitly constrained to **advisory output only**:

```
SYNTHESIZER_PROMPT:
"Never take or recommend actions beyond providing guidance."
"If the issue requires elevated access, explicitly state: 
'This issue requires human IT staff intervention.'"
```

The agent cannot:
- Modify system configurations
- Access external services
- Execute commands
- Send emails or create tickets
- Escalate automatically

All recommendations require human IT staff to review and execute.

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟡 Medium | 🟢 Low |

**NIST 800-53:** AC-6 | **MITRE ATLAS:** AML.T0048

---

## LLM09 — Overreliance

**Risk:** Users or systems place excessive trust in LLM outputs without
appropriate verification, leading to harmful decisions based on
hallucinated or incorrect information.

### Assessment

**Mitigations in the synthesizer prompt:**
- Agent must cite policy sources explicitly
- Agent must acknowledge when knowledge base is insufficient
- Agent must escalate security incidents to human IT staff
- Agent must not fabricate policy details

**Human oversight model:**
- IT staff review agent responses before acting
- Agent output is labeled as AI-generated triage guidance
- No automated ticket resolution — human execution required

### Gaps

- ✅ Confidence scoring implemented Phase 7 — High/Medium/Low badge displayed with each response in app.py
- ✅ AI disclaimer implemented — st.info() banner added to app.py confirming AI-generated guidance requires verification

### Recommended addition to `app.py`:
```python
st.info("⚠️ AI-generated triage guidance. Always verify with your "
        "IT team before taking action.")
```

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟡 Medium | 🟡 Medium |

**NIST 800-53:** SI-12, AC-2

---

## LLM10 — Model Theft

**Risk:** Attackers exfiltrate the model through API access, enabling
unauthorized use or competitive intelligence gathering.

### Assessment

**Ollama is bound to localhost only:**
```
LISTEN 0  4096  127.0.0.1:11434  0.0.0.0:*  users:(("ollama"))
```

Direct model API access from the network is not possible. An attacker
must first gain shell access to the server to reach the Ollama API.
Shell access is protected by:
- SSH key-only authentication (no password auth)
- SSH on non-default port 2222
- fail2ban with 3-attempt ban
- UFW firewall default deny

### Risk Rating

| Before controls | After controls |
|---|---|
| 🟡 Medium | 🟢 Low |

**NIST 800-53:** SC-7, AC-17 | **MITRE ATLAS:** AML.T0044

---

## Assessment Summary

| # | Risk | Rating | Status |
|---|---|---|---|
| LLM01 | Prompt Injection | 🟡 Medium | Mitigated — gaps remain |
| LLM02 | Insecure Output Handling | 🟢 Low | Mitigated |
| LLM03 | Training Data Poisoning | 🟢 Low | Mitigated |
| LLM04 | Model Denial of Service | 🟡 Medium | Partially mitigated |
| LLM05 | Supply Chain Vulnerabilities | 🟢 Low | Mitigated |
| LLM06 | Sensitive Information Disclosure | 🟢 Low | Mitigated |
| LLM07 | Insecure Plugin Design | 🟢 Low | Not applicable |
| LLM08 | Excessive Agency | 🟢 Low | Mitigated |
| LLM09 | Overreliance | 🟡 Medium | Partially mitigated |
| LLM10 | Model Theft | 🟢 Low | Mitigated |

**Overall posture: 7 Green / 3 Yellow / 0 Red**

---

## Remaining Action Items

| Priority | Item | Risk |
|---|---|---|
| ✅ Done | Add server-side rate limiting — implemented Phase 5 | LLM04 |
| ✅ Done | Add Unicode normalization to sanitize_input() — implemented Phase 5 | LLM01 |
| ✅ Done — st.info() banner implemented in app.py | Add AI disclaimer to Streamlit UI | LLM09 |
| ✅ Done | Add Base64/encoding detection to sanitizer — implemented Phase 5 | LLM01 |
| Low | Generate SBOM for dependency tracking | LLM05 |
| Low | Add output length validation | LLM02 |

---

## Revision History

| Date | Change | Author |
|---|---|---|
| 2026-05-07 | Initial OWASP LLM Top 10 assessment — all 10 risks evaluated | Lester L. Artis Jr. |
