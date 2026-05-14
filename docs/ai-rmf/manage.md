## Incident Log

| Date       | Incident                                                                 | Severity | Response                                                        | Status       |
|------------|--------------------------------------------------------------------------|----------|-----------------------------------------------------------------|--------------|
| —          | No incidents recorded                                                    | —        | —                                                               | Clean        |
| 2026-05-07 | Temporary UFW port 22 rule was never removed after initial SSH key setup | Medium   | Rule deleted — port 22 closed, SSH access on port 2222 only    | ✅ Resolved  |
| 2026-05-08 | Streamlit exposed directly on port 8501 with no TLS | Medium | Caddy reverse proxy installed, TLS cert deployed, Streamlit restricted to localhost | ✅ Resolved |
| 2026-05-08 | PasswordAuthentication yes in 50-cloud-init.conf overriding hardening config | Medium | Fixed via sed, passwordauthentication no confirmed | ✅ Resolved |
| 2026-05-09 | UFW port rule misconfiguration allowing external access | Medium | Rule corrected, firewall audit completed | ✅ Resolved |

---
