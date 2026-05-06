# 🔐 Help Desk AI GRC Engineering Project

> A hands-on GRC engineering project demonstrating secure deployment of a locally-hosted AI agent using industry frameworks including NIST AI RMF, NIST 800-53, NIST 800-37, MITRE ATLAS, and OWASP LLM Top 10.

---

## 📌 Project Overview

This project documents the end-to-end process of deploying a secure, production-hardened **IT Help Desk AI Triage Agent** on an Ubuntu 24.04 LTS server. Every infrastructure and AI security decision is mapped to a recognized GRC framework control, making this a living security plan rather than just a technical deployment.

The agent uses a LangGraph multi-agent pipeline with FAISS RAG over SANS security policy documents to triage IT support tickets — classifying, summarizing, researching, and synthesizing structured responses in real time.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Ubuntu 24.04 LTS Server             │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │         Help Desk AI Agent (Streamlit)       │    │
│  │                                              │    │
│  │  START ─┬─> classifier ─┐                   │    │
│  │         │               ├─> researcher       │    │
│  │         └─> summarizer ─┘    (FAISS RAG)     │    │
│  │                    │                         │    │
│  │              recommender                     │    │
│  │                    │                         │    │
│  │              synthesizer ──> END             │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Ollama  │  │   UFW    │  │    auditd         │  │
│  │  gemma4  │  │Firewall  │  │  fail2ban         │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────┘
```

**Stack:**
- OS: Ubuntu 24.04.4 LTS (aarch64)
- AI Framework: LangGraph + LangChain + FAISS
- Model: Gemma 4 (via Ollama, local inference)
- UI: Streamlit
- Process Manager: systemd
- Firewall: UFW

---

## 🛡️ Security Frameworks Applied

| Framework | Purpose | Phase |
|---|---|---|
| NIST 800-53 Rev 5 | Security control catalog for server and application hardening | 1, 2, 3 |
| NIST 800-37 | Risk Management Framework — categorize, select, implement, assess | All |
| NIST AI RMF | AI-specific risk governance: Govern, Map, Measure, Manage | 2, 3 |
| MITRE ATLAS | Adversarial ML threat modeling for the AI agent | 3 |
| OWASP LLM Top 10 | AI application vulnerability controls | 2, 3 |

---

## 📋 Phase 1 — Server Setup & Hardening

### Objective
Establish a secure, auditable Ubuntu server baseline before deploying any application code.

### Controls Implemented

| Control ID | Control Name | Implementation | Status |
|---|---|---|---|
| SI-2 | Flaw Remediation | `apt upgrade`, unattended-upgrades | ✅ |
| CM-2 | Baseline Configuration | Automated via `phase1-hardening.sh` | ✅ |
| CM-6 | Configuration Settings | SSH hardening drop-in config | ✅ |
| CM-3 | Configuration Change Control | All changes tracked, temp rules reverted | ✅ |
| AC-3 | Access Enforcement | SSH key-only auth, AllowUsers directive | ✅ |
| AC-6 | Least Privilege | Non-root user, systemd sandboxing | ✅ |
| AC-7 | Unsuccessful Login Attempts | fail2ban, maxretry=3, bantime=3600s | ✅ |
| AC-8 | System Use Notification | SSH login banner | ✅ |
| AC-17 | Remote Access | SSH on port 2222, ED25519 key auth | ✅ |
| AU-2 | Event Logging | auditd with custom ruleset | ✅ |
| AU-12 | Audit Record Generation | Tracks identity, sudo, exec, network changes | ✅ |
| IA-2 | Identification & Authentication | ED25519 SSH key, no password auth | ✅ |
| IA-5 | Authenticator Management | Key passphrase required | ✅ |
| SC-7 | Boundary Protection | UFW default deny, explicit allow rules | ✅ |
| SC-39 | Process Isolation | systemd NoNewPrivileges, PrivateTmp | ✅ |

### Key Configurations
- SSH moved from port 22 to port 2222
- Root login disabled
- Password authentication disabled (key-only)
- UFW default deny incoming, ports 2222/80/443/8501 allowed
- auditd monitoring: passwd, shadow, sudoers, SSH config, log changes, command execution
- fail2ban protecting SSH with auto-ban after 3 failed attempts
- Automatic security updates enabled

### Automation
Phase 1 is fully automated via `scripts/phase1-hardening.sh`. The script:
- Validates SSH key is present before disabling password auth (lockout prevention)
- Fixes Ubuntu 24.04 cloud-init SSH override automatically
- Runs a verification check at the end confirming all controls are active

---

## 📋 Phase 2 — AI Agent Deployment

### Objective
Deploy the Help Desk AI Triage Agent as a hardened, persistent systemd service with proper process isolation.

### Agent Architecture
The agent uses a **LangGraph StateGraph** with 5 specialized nodes:

1. **Classifier** — Determines ticket team and urgency
2. **Summarizer** — Extracts issue type and summary
3. **Researcher** — Queries FAISS vector store over SANS policy documents
4. **Recommender** — Generates ordered action list
5. **Synthesizer** — Composes final structured response via Gemma 4

Classifier and summarizer run in **parallel** from START, both feed into researcher, then the pipeline runs sequentially to END.

### Knowledge Base
The FAISS vector store is built from the following SANS policy documents:
- Access Management Policy
- Acceptable Use Standard
- Email Management Policy
- Network Device Management Policy
- Password Construction Standard
- Perimeter Network Access Management Policy
- Privileged Account Management Policy
- Software Management Policy
- Internet Usage Standard
- VPN Troubleshooting Runbook

### OWASP LLM Top 10 Controls Applied

| Risk | Control Implemented |
|---|---|
| LLM01 Prompt Injection | Input handled through structured LangGraph pipeline, not raw prompt passthrough |
| LLM02 Insecure Output | Output displayed in sandboxed Streamlit UI |
| LLM06 Sensitive Info Disclosure | Local model only — no data leaves the server |
| LLM08 Excessive Agency | Agent has no external tool access, read-only RAG |
| LLM10 Model Theft | Ollama bound to localhost only (127.0.0.1:11434) |

### Deployment
- Agent runs as a **systemd service** (`helpdesk-agent.service`)
- Starts automatically on boot
- Restarts on failure with 5-second delay
- systemd security hardening: `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem`
- Streamlit UI accessible on port 8501

---

## 📋 Phase 3 — Framework Mapping & Threat Modeling (In Progress)

- [ ] NIST AI RMF — Govern, Map, Measure, Manage functions
- [ ] MITRE ATLAS threat model for the help desk agent
- [ ] Full OWASP LLM Top 10 assessment
- [ ] Risk register completion
- [ ] System Security Plan (SSP) draft

---

## 🗂️ Repository Structure

```
helpdesk-ai-grc/
├── README.md
├── scripts/
│   ├── phase1-hardening.sh     # Automated Phase 1 hardening
│   └── setup-vm.sh             # VM creation script (VMware Fusion)
├── configs/
│   ├── ssh/
│   │   └── 99-hardening.conf   # SSH hardening drop-in
│   ├── audit/
│   │   └── hardening.rules     # auditd rules
│   ├── fail2ban/
│   │   └── jail.local          # fail2ban SSH jail config
│   └── helpdesk-agent.service  # systemd service definition
└── docs/
    ├── phase1-server-hardening.md
    ├── control-mapping.md
    └── risk-register.md
```

---

## 🚀 Quick Start

### Prerequisites
- VMware Fusion 13+ (Apple Silicon) or any hypervisor
- Ubuntu 24.04 LTS Server ISO
- SSH key pair generated on host machine

### Deploy

**1. Create the VM (Mac):**
```bash
chmod +x scripts/setup-vm.sh
./scripts/setup-vm.sh
```

**2. Install Ubuntu, create `grcadmin` user, enable OpenSSH**

**3. Copy SSH key to VM:**
```bash
ssh-copy-id -i ~/.ssh/YOUR_KEY.pub -p 22 grcadmin@YOUR_VM_IP
```

**4. Copy and run hardening script:**
```bash
scp -P 22 scripts/phase1-hardening.sh grcadmin@YOUR_VM_IP:~/
ssh -p 22 grcadmin@YOUR_VM_IP
chmod +x phase1-hardening.sh
sudo ./phase1-hardening.sh
```

**5. Deploy the agent:**
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Ollama and pull model
curl -fsSL https://ollama.com/install.sh | sh
ollama pull gemma4

# Install dependencies
cd ~/helpdesk-agent
uv sync

# Enable service
sudo systemctl enable helpdesk-agent
sudo systemctl start helpdesk-agent
```

**6. Access the UI:**
```
http://YOUR_VM_IP:8501
```

---

## 📊 Risk Register (Summary)

| ID | Risk | Likelihood | Impact | Control | Status |
|---|---|---|---|---|---|
| R-001 | Unauthorized SSH access | High | High | fail2ban, key-only auth | ✅ Mitigated |
| R-002 | Privilege escalation | Medium | High | auditd sudoers watch | ✅ Monitored |
| R-003 | Unpatched OS vulnerabilities | Medium | High | unattended-upgrades | ✅ Mitigated |
| R-004 | Unauthorized network access | High | High | UFW default deny | ✅ Mitigated |
| R-005 | Prompt injection attack | High | High | Structured pipeline, no raw passthrough | ✅ Mitigated |
| R-006 | Sensitive data leakage | Medium | High | Local model, no external calls | ✅ Mitigated |
| R-007 | Model theft | Low | High | Ollama bound to localhost only | ✅ Mitigated |
| R-008 | Adversarial ML attack | Low | High | MITRE ATLAS mapping | 🔲 Phase 3 |

---

## 🔗 Frameworks & References

- [NIST AI RMF](https://www.nist.gov/artificial-intelligence/ai-risk-management-framework)
- [NIST 800-53 Rev 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [NIST 800-37 Rev 2](https://csrc.nist.gov/publications/detail/sp/800-37/rev-2/final)
- [MITRE ATLAS](https://atlas.mitre.org/)
- [OWASP LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [SANS Policy Templates](https://www.sans.org/information-security-policy/)

---

## 👤 Author

**LesCondones**
GRC Engineering Project | 2026
