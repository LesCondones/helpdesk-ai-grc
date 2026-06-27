# Control Traceability Matrix (CTM)
## Help Desk AI Triage Agent

**Framework:** NIST SP 800-53 Rev 5 — Moderate Baseline (287 controls)
**System Categorization:** Moderate (FIPS 199)
**Date:** 2026-05-21
**Author:** Lester L. Artis Jr.

## Status Key

| Status | Meaning |
|---|---|
| ✅ Implemented | Control is fully implemented with evidence |
| 🔲 POA&M | Planned remediation — see docs/poam.md |
| N/A | Not applicable to this system — justification provided |
| ⚠️ Partial | Partially implemented — gaps documented |

## Access Control (AC)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| AC-1 | Access Control Policy | N/A | Single-person portfolio project. No formal organizational policy required. System owner serves all roles. |
| AC-2 | Account Management | N/A | Single user system. No user provisioning, account lifecycle, or group management required. Only grcadmin account exists. |
| AC-3 | Access Enforcement | ✅ Implemented | SSH key-only authentication. AllowUsers grcadmin directive in sshd_config. systemd ProtectSystem=strict. Evidence: configs/ssh/99-hardening.conf |
| AC-4 | Information Flow Enforcement | N/A | No multi-level security or information flow policy required for this single-tier system. |
| AC-5 | Separation of Duties | N/A | Single-person portfolio project. System Owner, ISSO, and Developer roles held by same individual. Documented as known limitation in docs/ssp.md. |
| AC-6 | Least Privilege | ✅ Implemented | Non-root grcadmin user. systemd NoNewPrivileges=yes. Ollama bound to localhost only. Evidence: configs/helpdesk-agent.service |
| AC-7 | Unsuccessful Login Attempts | ✅ Implemented | fail2ban maxretry=3, bantime=3600s. Validated via Hydra test in Phase 11. Evidence: configs/fail2ban/jail.local, docs/pentest-report.md |
| AC-8 | System Use Notification | ✅ Implemented | SSH legal notice banner configured. Evidence: configs/ssh/99-hardening.conf |
| AC-9 | Previous Logon Notification | N/A | No interactive user sessions beyond system owner. No requirement for logon notification. |
| AC-10 | Concurrent Session Control | N/A | Single user system. No concurrent session restrictions required. |
| AC-11 | Device Lock | N/A | Server system — no interactive desktop sessions. Not applicable. |
| AC-12 | Session Termination | N/A | SSH sessions terminate on disconnect. No web session management beyond Streamlit defaults. |
| AC-14 | Permitted Actions Without Identification | N/A | All system access requires authentication. No anonymous access permitted. |
| AC-17 | Remote Access | ✅ Implemented | SSH on non-default port 2222. ED25519 key-only authentication. Evidence: configs/ssh/99-hardening.conf |
| AC-18 | Wireless Access | N/A | No wireless interfaces on the VM. Not applicable. |
| AC-19 | Access Control for Mobile Devices | N/A | No mobile device access to the system. Not applicable. |
| AC-20 | Use of External Systems | N/A | No external system connections. Local inference only. No cloud APIs. |
| AC-21 | Information Sharing | N/A | No information sharing with external parties. |
| AC-22 | Publicly Accessible Content | N/A | System is not publicly accessible. Internal network only. |

## Awareness and Training (AT)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| AT-1 | Awareness and Training Policy | N/A | Single-person portfolio project. No organizational training program required. |
| AT-2 | Literacy Training and Awareness | N/A | No end users beyond system owner. System owner has self-directed security training via this GRC project. |
| AT-3 | Role-Based Training | N/A | Single person holds all roles. Formal role-based training program not required. |
| AT-4 | Training Records | N/A | No formal training program to document. |

## Audit and Accountability (AU)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| AU-1 | Audit and Accountability Policy | N/A | Single-person project. No formal organizational policy required. |
| AU-2 | Event Logging | ✅ Implemented | auditd with 13-rule custom ruleset. Tracks identity, sudo, exec, network changes. Evidence: configs/audit/hardening.rules |
| AU-3 | Content of Audit Records | ✅ Implemented | auditd records timestamp, user, command, result. Server-side input logging in helpdesk-agent logs directory. |
| AU-4 | Audit Log Storage Capacity | ✅ Implemented | Log rotation configured. Weekly rotation, 4-week retention. Evidence: configs/logrotate-helpdesk |
| AU-5 | Response to Audit Logging Process Failures | N/A | No automated alerting on audit failure. Accepted for portfolio project. |
| AU-6 | Audit Record Review | ⚠️ Partial | Daily health check reviews fail2ban and auditd. Manual log review per host. No centralized SIEM aggregation. |
| AU-7 | Audit Record Reduction and Report Generation | ⚠️ Partial | No automated report generation or centralized log aggregation. Manual review of individual log files. |
| AU-8 | Time Stamps | ✅ Implemented | System time synchronized. auditd records UTC timestamps. |
| AU-9 | Protection of Audit Information | ✅ Implemented | auditd logs in /var/log protected by filesystem permissions. systemd ProtectSystem restricts write access. |
| AU-10 | Non-Repudiation | N/A | No digital signature or non-repudiation requirements for this system. |
| AU-11 | Audit Record Retention | ✅ Implemented | Log rotation retains 4 weeks of health check logs. Input logs retain 7 days. Evidence: configs/logrotate-helpdesk |
| AU-12 | Audit Record Generation | ✅ Implemented | auditd generates records for all defined events. Server-side input sanitization logging active. Evidence: configs/audit/hardening.rules |

## Assessment, Authorization, and Monitoring (CA)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| CA-1 | Assessment Authorization and Monitoring Policy | N/A | Single-person portfolio project. No formal organizational policy. |
| CA-2 | Control Assessments | ⚠️ Partial | Internal self-assessment conducted. SCA role performed by system owner. No independent third-party assessment. Documented limitation in docs/ssp.md. |
| CA-3 | Information Exchange | N/A | No interconnections with external systems. GitHub used for CI/CD only. |
| CA-5 | Plan of Action and Milestones | ✅ Implemented | POA&M documented in docs/poam.md covering 7 items. |
| CA-6 | Authorization | N/A | No formal ATO process. Portfolio project in prototype state. Documented in docs/ssp.md. |
| CA-7 | Continuous Monitoring | ⚠️ Partial | Daily health check script via cron, auditd, and fail2ban provide ongoing monitoring. Manual log review. No centralized SIEM. Evidence: daily-health-check.sh |
| CA-8 | Penetration Testing | ✅ Implemented | Internal penetration test conducted Phase 11. Evidence: docs/pentest-report.md |
| CA-9 | Internal System Connections | N/A | No internal system connections beyond localhost. |

## Configuration Management (CM)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| CM-1 | Configuration Management Policy | N/A | Single-person project. No formal organizational policy. |
| CM-2 | Baseline Configuration | ✅ Implemented | Automated baseline via phase1-hardening.sh. Evidence: scripts/phase1-hardening.sh |
| CM-3 | Configuration Change Control | ✅ Implemented | All changes via GitHub CI/CD pipeline. Commit history provides audit trail. Evidence: scripts/deploy.sh |
| CM-4 | Impact Analysis | ⚠️ Partial | Informal impact analysis performed before changes. No formal change advisory board. |
| CM-5 | Access Restrictions for Change | ✅ Implemented | GitHub repo access controlled. Deploy requires SSH key authentication. |
| CM-6 | Configuration Settings | ✅ Implemented | SSH hardening drop-in config. UFW rules. auditd rules. Evidence: configs/ directory |
| CM-7 | Least Functionality | ⚠️ Partial | Unnecessary services not explicitly audited. Server version header stripped via Caddy. Evidence: docs/pentest-report.md F-001 resolved. |
| CM-8 | System Component Inventory | N/A | Single VM with known components. No formal inventory management system required. |
| CM-9 | Configuration Management Plan | N/A | No formal CM plan document. Baseline defined in scripts/phase1-hardening.sh. |
| CM-10 | Software Usage Restrictions | N/A | All software is open source. No licensing restrictions to manage. |
| CM-11 | User-Installed Software | N/A | No end users. System owner controls all software installation. |

## Contingency Planning (CP)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| CP-1 | Contingency Planning Policy | N/A | Single-person portfolio project. |
| CP-2 | Contingency Plan | N/A | No formal contingency plan. System is non-production portfolio project. |
| CP-3 | Contingency Training | N/A | No end users to train. |
| CP-4 | Contingency Plan Testing | N/A | No formal contingency plan to test. |
| CP-6 | Alternate Storage Site | N/A | No alternate storage site. GitHub serves as code backup. |
| CP-7 | Alternate Processing Site | N/A | No DR site. Portfolio project. |
| CP-8 | Telecommunications Services | N/A | No telecommunications dependencies. |
| CP-9 | System Backup | 🔲 POA&M | Manual VM snapshots at major milestones only. No automated backup schedule. POA&M POA-002. |
| CP-10 | System Recovery and Reconstitution | ⚠️ Partial | VM snapshots enable manual recovery. No documented RTO/RPO. |

## Identification and Authentication (IA)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| IA-1 | Identification and Authentication Policy | N/A | Single-person portfolio project. |
| IA-2 | Identification and Authentication (Org Users) | ✅ Implemented | ED25519 SSH key authentication. No password authentication. Evidence: configs/ssh/99-hardening.conf |
| IA-3 | Device Identification and Authentication | N/A | No device-level authentication required. Single known host. |
| IA-4 | Identifier Management | N/A | Single user account. No identifier lifecycle management required. |
| IA-5 | Authenticator Management | ✅ Implemented | SSH key with passphrase. Key stored securely. Evidence: configs/ssh/99-hardening.conf |
| IA-6 | Authentication Feedback | N/A | No interactive login UI beyond SSH. |
| IA-7 | Cryptographic Module Authentication | N/A | No FIPS-validated cryptographic modules required for portfolio project. |
| IA-8 | Identification and Authentication (Non-Org Users) | N/A | No non-organizational users with privileged access. |
| IA-11 | Re-Authentication | N/A | SSH sessions do not require re-authentication. Acceptable for portfolio project. |
| IA-12 | Identity Proofing | N/A | No identity proofing required. Single known user. |

## Incident Response (IR)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| IR-1 | Incident Response Policy | N/A | Single-person portfolio project. |
| IR-2 | Incident Response Training | N/A | No end users to train. |
| IR-3 | Incident Response Testing | N/A | No formal IR testing conducted. |
| IR-4 | Incident Handling | ⚠️ Partial | Manual IR plan in docs/ai-rmf/manage.md. No automated alerting. POA&M POA-003. |
| IR-5 | Incident Monitoring | ⚠️ Partial | fail2ban monitors SSH. auditd logs privileged actions. Daily health check monitors services. No centralized log monitoring. |
| IR-6 | Incident Reporting | N/A | No organizational reporting chain. Portfolio project. |
| IR-7 | Incident Response Assistance | N/A | No external IR assistance required. |
| IR-8 | Incident Response Plan | ✅ Implemented | IR plan documented in docs/ai-rmf/manage.md covering AI-specific incident types. |
| IR-9 | Information Spillage Response | ⚠️ Partial | No formal CUI spillage procedure. Rules of Behavior in docs/ssp.md instruct users not to input sensitive data. |

## Maintenance (MA)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| MA-1 | Maintenance Policy | N/A | No physical hardware maintenance staff. VM hosted on personal workstation. |
| MA-2 | Controlled Maintenance | N/A | No scheduled maintenance program. Updates applied via unattended-upgrades. |
| MA-3 | Maintenance Tools | N/A | No specialized maintenance tools. |
| MA-4 | Nonlocal Maintenance | N/A | No remote maintenance by third parties. |
| MA-5 | Maintenance Personnel | N/A | No maintenance personnel beyond system owner. |
| MA-6 | Timely Maintenance | N/A | No SLA or maintenance schedule required for portfolio project. |

## Media Protection (MP)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| MP-1 | Media Protection Policy | N/A | No removable media used. |
| MP-2 | Media Access | N/A | No removable media. |
| MP-3 | Media Marking | N/A | No removable media. |
| MP-4 | Media Storage | N/A | No removable media. |
| MP-5 | Media Transport | N/A | No removable media transport. |
| MP-6 | Media Sanitization | N/A | No removable media to sanitize. |
| MP-7 | Media Use | N/A | No removable media used in this environment. |

## Personnel Security (PS)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| PS-1 | Personnel Security Policy | N/A | Single-person project. No personnel management program. |
| PS-2 | Position Risk Designation | N/A | Single person. No position risk designation process. |
| PS-3 | Personnel Screening | N/A | No personnel screening required. |
| PS-4 | Personnel Termination | N/A | No personnel to terminate. |
| PS-5 | Personnel Transfer | N/A | No personnel transfers. |
| PS-6 | Access Agreements | N/A | Single user. No access agreements required. |
| PS-7 | External Personnel Security | N/A | No external personnel. |
| PS-8 | Personnel Sanctions | N/A | No personnel sanctions process required. |
| PS-9 | Position Descriptions | N/A | Single-person project. |

## PII Processing and Transparency (PT)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| PT-1 | PII Processing Policy | N/A | System does not process PII by design. Documented in docs/ssp.md and docs/categorization.md. |
| PT-2 | Authority to Process PII | N/A | No PII processed. |
| PT-3 | Personally Identifiable Information Processing | N/A | No PII processed by design. Rules of Behavior prohibit PII input. sanitize_input() strips injection patterns. |
| PT-4 | Consent for PII Processing | N/A | No PII processed. |
| PT-5 | Privacy Notice | N/A | No PII collected. No privacy notice required. |
| PT-6 | System of Records Notice | N/A | No PII records maintained. |
| PT-7 | Specific Categories of PII | N/A | No PII processed. |
| PT-8 | Computer Matching Requirements | N/A | No computer matching of PII. |

## Planning (PL)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| PL-1 | Planning Policy | N/A | Single-person project. |
| PL-2 | System Security and Privacy Plan | ✅ Implemented | Full SSP documented in docs/ssp.md including operational status, rules of behavior, and continuous monitoring plan. FIPS 199 in docs/categorization.md. |
| PL-4 | Rules of Behavior | ✅ Implemented | Rules of Behavior documented in docs/ssp.md Appendix A. |
| PL-8 | Security and Privacy Architectures | ⚠️ Partial | Architecture documented in README.md and docs/architecture.svg. No formal security architecture document. |
| PL-10 | Baseline Selection | ✅ Implemented | Moderate baseline selected based on FIPS 199 categorization. Documented in docs/categorization.md. |
| PL-11 | Baseline Tailoring | ✅ Implemented | CTM documents all 287 Moderate baseline controls with implemented/N/A/POA&M status. Evidence: docs/ctm.md |

## Program Management (PM)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| PM-1 | Information Security Program Plan | N/A | No organizational security program. Portfolio project. |
| PM-2 | Information Security Program Leadership Roles | N/A | Single-person project. |
| PM-3 | Information Security and Privacy Resources | N/A | No budget or resource allocation process. |
| PM-4 | Plan of Action and Milestones Process | ✅ Implemented | POA&M process documented. Evidence: docs/poam.md |
| PM-5 | System Inventory | N/A | Single system. No enterprise inventory. |
| PM-6 | Measures of Performance | N/A | No formal performance measurement program. |
| PM-7 | Enterprise Architecture | N/A | No enterprise architecture program. |
| PM-8 | Critical Infrastructure Plan | N/A | Not critical infrastructure. |
| PM-9 | Risk Management Strategy | ✅ Implemented | Risk management strategy implemented via NIST AI RMF. Evidence: docs/ai-rmf/ directory. |
| PM-10 | Authorization Process | N/A | No formal ATO process. Portfolio project. |
| PM-11 | Mission and Business Process Definition | N/A | Single portfolio system. |
| PM-12 | Insider Threat Program | N/A | Single-person project. No insider threat program. |
| PM-13 | Security and Privacy Workforce | N/A | No workforce management program. |
| PM-14 | Testing Training and Monitoring | N/A | No organizational testing program. |
| PM-15 | Security and Privacy Groups and Associations | N/A | No organizational program. |
| PM-16 | Threat Awareness Program | N/A | MITRE ATLAS threat model serves as informal equivalent. Evidence: docs/threat-model/mitre-atlas.md |
| PM-17 | Protecting CUI on External Systems | N/A | No CUI processed. |
| PM-18 | Privacy Program Plan | N/A | No PII processed. No privacy program required. |
| PM-19 | Privacy Program Leadership Roles | N/A | No PII processed. |
| PM-20 | Dissemination of Privacy Program Information | N/A | No PII processed. |
| PM-21 | Accounting of Disclosures | N/A | No PII processed. |
| PM-22 | Personally Identifiable Information Quality Management | N/A | No PII processed. |
| PM-23 | Data Governance Body | N/A | No PII processed. Single-person project. |
| PM-24 | Data Integrity Board | N/A | No PII processed. |
| PM-25 | Minimization of PII Used in Testing | N/A | No PII used in testing. |
| PM-26 | Complaint Management | N/A | No end users. No complaint management required. |
| PM-27 | Privacy Reporting | N/A | No PII processed. |
| PM-28 | Risk Framing | ✅ Implemented | Risk framing documented via NIST AI RMF MAP function. Evidence: docs/ai-rmf/map.md |
| PM-29 | Risk Management Program Leadership Roles | N/A | Single-person project. |
| PM-30 | Supply Chain Risk Management Strategy | N/A | No supply chain program. Dependencies managed via uv.lock. |
| PM-31 | Continuous Monitoring Strategy | ✅ Implemented | Continuous monitoring strategy documented in docs/ssp.md Section 12. Daily health check, auditd, and fail2ban active. |
| PM-32 | Purposing | N/A | No enterprise purposing program. |

## Risk Assessment (RA)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| RA-1 | Risk Assessment Policy | N/A | Single-person project. |
| RA-2 | Security Categorization | ✅ Implemented | FIPS 199 categorization completed. Overall: Moderate. Evidence: docs/categorization.md |
| RA-3 | Risk Assessment | ✅ Implemented | Risk assessment conducted via NIST AI RMF MAP function. 14 risks identified. Evidence: docs/ai-rmf/map.md |
| RA-3(1) | Risk Assessment Supply Chain | N/A | No supply chain risk assessment required. Dependencies are open source and version-locked. |
| RA-5 | Vulnerability Monitoring and Scanning | ⚠️ Partial | Internal pentest conducted Phase 11. Monthly nmap scans per SSP Section 12. No automated vulnerability scanning. |
| RA-7 | Risk Response | ✅ Implemented | Risk treatment decisions documented. Evidence: docs/ai-rmf/manage.md |
| RA-9 | Criticality Analysis | N/A | Single system. No criticality analysis required. |

## System and Services Acquisition (SA)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| SA-1 | Acquisition Policy | N/A | No procurement process. All software is open source. |
| SA-2 | Allocation of Resources | N/A | No formal resource allocation process. |
| SA-3 | System Development Life Cycle | ⚠️ Partial | Informal SDLC followed. CI/CD pipeline provides controlled deployment. No formal SDLC documentation. |
| SA-4 | Acquisition Process | N/A | No procurement. All software open source. |
| SA-5 | System Documentation | ✅ Implemented | Comprehensive documentation in GitHub repo. README, SSP, CTM, architecture diagram, framework docs. |
| SA-8 | Security and Privacy Engineering Principles | ✅ Implemented | Least privilege, defense in depth, fail secure implemented throughout. Evidence: docs/ai-rmf/ directory. |
| SA-9 | External System Services | N/A | No external system services used. Local inference only. |
| SA-10 | Developer Configuration Management | ✅ Implemented | GitHub version control. CI/CD pipeline. Commit history. Evidence: scripts/deploy.sh |
| SA-11 | Developer Testing and Evaluation | ✅ Implemented | Internal security testing conducted. Evidence: docs/ai-rmf/measure.md, docs/pentest-report.md |
| SA-15 | Development Process Standards and Tools | N/A | No formal development process standards required. |
| SA-16 | Developer-Provided Training | N/A | System owner is the developer. No training required. |
| SA-17 | Developer Security and Privacy Architecture | N/A | No external developer. System owner designed the architecture. |
| SA-21 | Developer Screening | N/A | Single developer — system owner. |

## System and Communications Protection (SC)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| SC-1 | Policy and Procedures | N/A | Single-person project. |
| SC-2 | Separation of System and User Functionality | ✅ Implemented | Streamlit UI separated from backend pipeline. Ollama bound to localhost. |
| SC-3 | Security Function Isolation | ✅ Implemented | systemd process isolation. ProtectSystem=strict. PrivateTmp. NoNewPrivileges. |
| SC-4 | Information in Shared System Resources | N/A | No shared system resources with other tenants. Single-tenant VM. |
| SC-5 | Denial of Service Protection | ✅ Implemented | Server-side rate limiting. Caddy connection limiting. fail2ban SSH protection. Evidence: app.py |
| SC-7 | Boundary Protection | ✅ Implemented | UFW default deny. Only ports 80, 443, 2222 open. 65,531 ports filtered. Evidence: docs/pentest-report.md F-006 |
| SC-8 | Transmission Confidentiality and Integrity | ✅ Implemented | Caddy reverse proxy with TLS 1.2/1.3. HSTS. X-Frame-Options. X-Content-Type-Options. Forward secrecy. Evidence: docs/pentest-report.md |
| SC-10 | Network Disconnect | N/A | No specific network disconnect requirements. SSH sessions timeout on inactivity. |
| SC-12 | Cryptographic Key Establishment and Management | ⚠️ Partial | Self-signed TLS cert. No formal key management program. Cert renewal manual. |
| SC-13 | Cryptographic Protection | ✅ Implemented | TLS 1.2/1.3 with strong AEAD ciphers. ED25519 SSH keys. AES-256-GCM. Forward secrecy. |
| SC-15 | Collaborative Computing Devices | N/A | No collaborative computing devices. |
| SC-17 | Public Key Infrastructure Certificates | ⚠️ Partial | Self-signed certificate. No PKI. Pentest finding F-008 accepted. |
| SC-18 | Mobile Code | N/A | No mobile code executed. |
| SC-20 | Secure Name/Address Resolution | N/A | No DNS services provided. |
| SC-21 | Secure Name Resolution (Recursive) | N/A | Uses system DNS resolver. No DNS services provided. |
| SC-22 | Architecture and Provisioning for DNS | N/A | No DNS architecture. |
| SC-23 | Session Authenticity | ✅ Implemented | TLS provides session authenticity. SSH key authentication. |
| SC-24 | Fail in Known State | ✅ Implemented | Agent retry logic with fallback defaults. systemd restart on failure. |
| SC-28 | Protection of Information at Rest | ✅ Implemented | No sensitive data stored. FAISS index integrity monitored. No PII at rest. |
| SC-39 | Process Isolation | ✅ Implemented | systemd NoNewPrivileges, PrivateTmp, ProtectSystem=strict. Evidence: configs/helpdesk-agent.service |
| SC-45 | System Time Synchronization | ✅ Implemented | System time synchronized via NTP. auditd timestamps accurate. |

## System and Information Integrity (SI)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| SI-1 | Policy and Procedures | N/A | Single-person project. |
| SI-2 | Flaw Remediation | ✅ Implemented | unattended-upgrades enabled. Security updates applied regularly. Evidence: README.md Phase 5 monitoring section |
| SI-3 | Malicious Code Protection | ⚠️ Partial | No antivirus/EDR installed. sanitize_input() protects against prompt injection and DAN patterns. UFW limits attack surface. CUI spillage procedure in SSP Rules of Behavior. |
| SI-4 | System Monitoring | ⚠️ Partial | Daily health check via cron, auditd event monitoring, fail2ban active monitoring. No centralized SIEM. POA&M POA-001 tracks reinstatement. |
| SI-5 | Security Alerts and Advisories | N/A | No formal security advisory subscription. unattended-upgrades handles OS patches. |
| SI-6 | Security and Privacy Function Verification | N/A | No automated function verification. Manual testing conducted. |
| SI-7 | Software Firmware and Information Integrity | ✅ Implemented | FAISS vector store SHA256 integrity monitoring. GitHub version control for all code. Evidence: scripts/deploy.sh |
| SI-8 | Spam Protection | N/A | No email system. Not applicable. |
| SI-10 | Information Input Validation | ✅ Implemented | sanitize_input() validates and strips injection patterns. Unicode normalization. Base64 detection. DAN and persona hijacking patterns. Evidence: app.py |
| SI-11 | Error Handling | ✅ Implemented | Retry logic with fallback defaults. No stack traces exposed to users. Pydantic schema validation. Evidence: tools.py, agent.py |
| SI-12 | Information Management and Retention | N/A | No information retention requirements beyond log rotation. |
| SI-15 | Information Output Filtering | ⚠️ Partial | Synthesizer prompt instructs model not to reveal KB structure or file names. No automated output length validation. POA&M POA-007. |
| SI-16 | Memory Protection | N/A | OS memory protection via Linux kernel. No additional requirements. |
| SI-17 | Fail-Safe Procedures | ✅ Implemented | systemd restart on failure. Agent fallback defaults on JSON parse failure. Pydantic validation prevents pipeline crashes. |

## Supply Chain Risk Management (SR)

| Control | Title | Status | Implementation / Justification |
|---|---|---|---|
| SR-1 | Policy and Procedures | N/A | No supply chain program. Single-person project. |
| SR-2 | Supply Chain Risk Management Plan | N/A | No formal SCRM plan. |
| SR-3 | Supply Chain Controls and Processes | N/A | Dependencies managed via uv.lock with version pinning. |
| SR-5 | Acquisition Strategies Tools and Methods | N/A | No procurement process. All software open source. |
| SR-6 | Supplier Assessments and Reviews | N/A | No supplier assessments. Open source dependencies reviewed via uv.lock. |
| SR-8 | Notification Agreements | N/A | No supplier notification agreements. |
| SR-9 | Tamper Resistance and Detection | N/A | FAISS integrity monitoring serves as software equivalent. Evidence: scripts/deploy.sh |
| SR-10 | Inspection of Systems and Components | N/A | No physical inspection requirements. |
| SR-11 | Component Authenticity | N/A | Package hashes in uv.lock provide basic component authenticity. |
| SR-12 | Component Disposal | N/A | No physical component disposal. |

## CTM Summary

| Status | Count |
|---|---|
| ✅ Implemented | 38 |
| ⚠️ Partial | 18 |
| 🔲 POA&M | 2 |
| N/A | 229 |
| **Total** | **287** |

## Revision History

| Date | Change | Author |
|---|---|---|
| 2026-05-21 | Initial CTM — all 287 Moderate baseline controls documented | Lester L. Artis Jr. |
