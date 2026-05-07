#!/bin/bash
# =============================================================================
# Phase 1 Hardening Script — Help Desk AI GRC Project
# OS: Ubuntu 24.04 LTS
# Frameworks: NIST 800-53 Rev 5, NIST 800-37, NIST AI RMF
# =============================================================================
# USAGE:
#   1. Copy this script to your VM:
#      scp -P 22 phase1-hardening.sh grcadmin@<VM_IP>:~/
#   2. Make it executable:
#      chmod +x phase1-hardening.sh
#   3. Run it:
#      sudo ./phase1-hardening.sh
# =============================================================================

set -euo pipefail

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration — edit these before running ---
USERNAME="grcadmin"
SSH_PORT="2222"
PROJECT_DATE=$(date +%Y-%m-%d)

# =============================================================================
log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
# =============================================================================

# Must run as root
if [[ $EUID -ne 0 ]]; then
  error "Run this script with sudo: sudo ./phase1-hardening.sh"
fi

echo ""
echo "============================================================"
echo "  Phase 1 Hardening — Help Desk AI GRC Project"
echo "  Date: $PROJECT_DATE"
echo "  User: $USERNAME | SSH Port: $SSH_PORT"
echo "============================================================"
echo ""
warn "This script will harden the server. Make sure you have"
warn "already copied your SSH public key to this server before"
warn "running, or you will be locked out."
echo ""
read -p "Have you copied your SSH public key to this server? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  warn "Exiting. Copy your SSH key first:"
  echo "  ssh-copy-id -i ~/.ssh/helpdesk-ai-grc.pub -p 22 $USERNAME@<VM_IP>"
  exit 0
fi

# =============================================================================
section "STEP 1 — System Update (NIST 800-53: SI-2)"
# =============================================================================
log "Updating package lists..."
apt update -y

log "Upgrading installed packages..."
apt upgrade -y

log "Installing required tools..."
apt install -y \
  curl wget git \
  ufw \
  fail2ban \
  auditd audispd-plugins \
  unattended-upgrades \
  apt-listchanges

log "System update complete."

# =============================================================================
section "STEP 2 — SSH Hardening (NIST 800-53: IA-2, AC-17, AC-3, AC-8)"
# =============================================================================

# Verify SSH key exists before locking down password auth
if [[ ! -f /home/$USERNAME/.ssh/authorized_keys ]]; then
  error "No SSH authorized_keys found for $USERNAME. Aborting to prevent lockout."
fi

KEY_COUNT=$(wc -l < /home/$USERNAME/.ssh/authorized_keys)
if [[ $KEY_COUNT -eq 0 ]]; then
  error "authorized_keys file is empty. Aborting to prevent lockout."
fi

log "SSH key found ($KEY_COUNT key(s)). Proceeding with SSH hardening..."

# Create login banner — AC-8 Legal Notice
cat > /etc/ssh/banner << 'EOF'
***************************************************************************
NOTICE: This system is for authorized use only.
Unauthorized access is prohibited and may be subject to criminal prosecution.
All activity on this system is monitored and recorded.
***************************************************************************
EOF
log "Login banner created."

# Create SSH hardening drop-in config
cat > /etc/ssh/sshd_config.d/99-hardening.conf << EOF
# GRC Project - SSH Hardening
# Framework: NIST 800-53 IA-2, AC-17, AC-3, AC-8
# Date: $PROJECT_DATE

Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowTcpForwarding no
AllowUsers $USERNAME
ClientAliveInterval 300
ClientAliveCountMax 2
Banner /etc/ssh/banner
EOF
log "SSH hardening config written."

# Validate SSH config before restarting
if sshd -t; then
  log "SSH config validation passed."
  systemctl daemon-reload
  systemctl restart ssh.socket
  log "SSH restarted on port $SSH_PORT."
else
  error "SSH config validation failed. Check /etc/ssh/sshd_config.d/99-hardening.conf"
fi

# =============================================================================
section "STEP 3 — Firewall (NIST 800-53: SC-7)"
# =============================================================================
log "Configuring UFW firewall..."

# Reset to clean state
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH on new port
ufw allow $SSH_PORT/tcp

# Allow HTTP and HTTPS for AI agent
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw --force enable

log "UFW configured and enabled."
ufw status verbose

# =============================================================================
section "STEP 4 — Audit Logging (NIST 800-53: AU-2, AU-12)"
# =============================================================================
log "Configuring auditd..."

# Write persistent audit rules
cat > /etc/audit/rules.d/hardening.rules << EOF
# GRC Project - Audit Rules
# Framework: NIST 800-53 AU-2, AU-12
# Date: $PROJECT_DATE

# Identity and authentication files
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# SSH config changes
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /etc/ssh/sshd_config.d/ -p wa -k sshd_config

# Log directory changes
-w /var/log/ -p wa -k log_changes

# Track all command execution
-a always,exit -F arch=b64 -S execve -k exec_commands

# Track privilege escalation
-w /bin/su -p x -k privilege_escalation
-w /usr/bin/sudo -p x -k privilege_escalation

# Track network config changes
-w /etc/hosts -p wa -k network_changes
-w /etc/ufw/ -p wa -k network_changes
EOF

systemctl enable auditd
systemctl restart auditd
augenrules --load

log "Auditd configured with $(auditctl -l | wc -l) rules."

# =============================================================================
section "STEP 5 — Fail2ban (NIST 800-53: AC-7, SI-3)"
# =============================================================================
log "Configuring fail2ban..."

cat > /etc/fail2ban/jail.local << EOF
# GRC Project - Fail2ban Configuration
# Framework: NIST 800-53 AC-7, SI-3
# Date: $PROJECT_DATE

[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3
banaction = ufw

[sshd]
enabled  = true
port     = $SSH_PORT
maxretry = 3
EOF

systemctl enable fail2ban
systemctl restart fail2ban

log "Fail2ban configured."

# =============================================================================
section "STEP 6 — Automatic Updates (NIST 800-53: SI-2)"
# =============================================================================
log "Enabling unattended-upgrades..."

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

log "Automatic security updates enabled."

# =============================================================================
section "VERIFICATION — Phase 1 Baseline Check"
# =============================================================================
echo ""
log "Running final verification checks..."
echo ""

echo "--- UFW Status ---"
ufw status verbose
echo ""

echo "--- Auditd Status ---"
systemctl is-active auditd && echo "auditd: ACTIVE" || echo "auditd: FAILED"
echo "Rules loaded: $(auditctl -l | wc -l)"
echo ""

echo "--- Fail2ban Status ---"
fail2ban-client status
echo ""

echo "--- Auto Updates ---"
cat /etc/apt/apt.conf.d/20auto-upgrades
echo ""

echo "--- SSH Effective Config ---"
sshd -T | grep -E "port|permitrootlogin|passwordauthentication|x11forwarding|maxauthtries"
echo ""

# =============================================================================
echo ""
echo "============================================================"
echo -e "${GREEN}  Phase 1 Hardening Complete!${NC}"
echo "============================================================"
echo ""
echo "IMPORTANT — Next steps:"
echo "  1. Open a NEW terminal and test SSH on port $SSH_PORT:"
echo "     ssh -i ~/.ssh/helpdesk-ai-grc -p $SSH_PORT $USERNAME@<VM_IP>"
echo ""
echo "  2. Confirm you can log in BEFORE closing this session"
echo ""
echo "  3. Take a VMware snapshot named: Phase1-Hardened-Baseline"
echo ""
echo "  4. Commit configs to GitHub:"
echo "     - /etc/ssh/sshd_config.d/99-hardening.conf"
echo "     - /etc/audit/rules.d/hardening.rules"
echo "     - /etc/fail2ban/jail.local"
echo "============================================================"
echo ""
