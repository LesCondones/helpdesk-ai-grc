## Risk Treatment Decisions

The following table records the formal treatment decision for each risk identified in MAP. Treatment decisions last reviewed: 2026-05-16.

| Risk ID | Risk | Likelihood | Impact | Treatment | Rationale | Status |
|---|---|---|---|---|---|---|
| MAP-001 | Prompt injection via ticket text | High | High | Mitigate | `sanitize_input()` strips injection patterns; 2000-char truncation in `app.py` | ✅ Mitigated |
| MAP-002 | Jailbreak attempt to extract system prompts | Medium | Medium | Mitigate | `sanitize_input()` strips jailbreak patterns in `app.py` | ✅ Mitigated |
| MAP-003 | Social engineering via crafted ticket | Medium | Medium | Mitigate | `sanitize_input()` applied to all user input before pipeline entry | ✅ Mitigated |
| MAP-004 | Code execution via tampered index.pkl | Low | Critical | Mitigate | SHA-256 integrity hash via `get_index_hash()` in `rag.py`; logged to systemd journal on every load | ✅ Monitored |
| MAP-005 | RAG poisoning via modified policy documents | Low | High | Mitigate | FAISS index integrity monitoring on every query via `load_vector_store()` | ✅ Monitored |
| MAP-006 | Knowledge base integrity loss | Low | High | Mitigate | Integrity hash baseline established 2026-05-07; compared on every load | ✅ Monitored |
| MAP-007 | Pipeline crash from malformed model output | Medium | Medium | Mitigate | Retry logic (3 attempts) + Pydantic schema validation implemented in tools.py | ✅ Mitigated |
| MAP-008 | Silent data corruption from unexpected JSON fields | Medium | Medium | Mitigate | Fallback defaults + Pydantic schema validation implemented in tools.py | ✅ Mitigated |
| MAP-009 | Denial of service via ticket flooding | Medium | High | Mitigate | 10-second rate limit per session in `app.py` (SC-5) | ✅ Mitigated |
| MAP-010 | Resource exhaustion crashing Ollama | Medium | High | Mitigate | Rate limiting prevents burst inference calls to Ollama | ✅ Mitigated |
| MAP-011 | Hallucinated policy guidance | Medium | High | Accept | Synthesizer prompt constrains model to knowledge base; residual hallucination risk accepted | 🟡 Monitored |
| MAP-012 | Overconfident response on unknown issues | Medium | Medium | Accept | Uncertainty acknowledgment in synthesizer prompt; human escalation path present | 🟡 Monitored |
| MAP-013 | RAG failure from missing embedding model | Low | High | Mitigate | Automated nomic-embed-text availability check implemented in rag.py - pulls model if missing on startup | ✅ Mitigated |
| MAP-014 | Degraded retrieval from embedding model version change | Low | Medium | Accept | Low probability; manual re-embedding procedure documented | 🟢 Low |

---

## Incident Log

| Date       | Incident                                                                 | Severity | Response                                                        | Status       |
|------------|--------------------------------------------------------------------------|----------|-----------------------------------------------------------------|--------------|
| —          | No incidents recorded                                                    | —        | —                                                               | Clean        |
| 2026-05-07 | Temporary UFW port 22 rule was never removed after initial SSH key setup | Medium   | Rule deleted — port 22 closed, SSH access on port 2222 only    | ✅ Resolved  |
| 2026-05-08 | Streamlit exposed directly on port 8501 with no TLS | Medium | Caddy reverse proxy installed, TLS cert deployed, Streamlit restricted to localhost | ✅ Resolved |
| 2026-05-08 | PasswordAuthentication yes in 50-cloud-init.conf overriding hardening config | Medium | Fixed via sed, passwordauthentication no confirmed | ✅ Resolved |
| 2026-05-09 | UFW port rule misconfiguration allowing external access | Medium | Rule corrected, firewall audit completed | ✅ Resolved |
| 2026-05-14 | Completed nmap scan confirming UFW boundary protection — all non-whitelisted ports filtered. SC-7 evidence documented. | Low | nmap scan results reviewed; SC-7 boundary protection confirmed; evidence logged | ✅ Resolved |
| 2026-05-16 | TLS certificate regenerated after network mode change from NAT to bridged — new cert issued with correct SANs for current deployment. SC-8 transmission confidentiality maintained. | Low | Certificate regenerated and trusted on client machine. | ✅ Resolved |

---
