#!/bin/bash
# Daily Health Check Script — Help Desk AI GRC Project
# Framework: NIST 800-53 CA-7 (Continuous Monitoring), AU-6 (Audit Review)
# Run: sudo bash ~/daily-health-check.sh

DATE=$(date '+%Y-%m-%d %H:%M:%S UTC')
REPORT="/var/log/helpdesk-health-$(date '+%Y%m%d').log"

echo "============================================================" | tee $REPORT
echo "  Daily Health Check — $DATE" | tee -a $REPORT
echo "============================================================" | tee -a $REPORT

# 1 — Service health
echo "" | tee -a $REPORT
echo "--- Service Status ---" | tee -a $REPORT
for svc in helpdesk-agent ollama caddy auditd fail2ban; do
    STATUS=$(systemctl is-active $svc)
    if [ "$STATUS" = "active" ]; then
        echo "[PASS] $svc: $STATUS" | tee -a $REPORT
    else
        echo "[FAIL] $svc: $STATUS" | tee -a $REPORT
    fi
done

# 2 — Fail2ban
echo "" | tee -a $REPORT
echo "--- Fail2ban Status ---" | tee -a $REPORT
fail2ban-client status sshd 2>/dev/null | tee -a $REPORT

# 3 — Failed login attempts today
echo "" | tee -a $REPORT
echo "--- Failed Login Attempts Today ---" | tee -a $REPORT
FAILED=$(grep "Failed password\|Invalid user" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %e')" | wc -l)
echo "Failed attempts: $FAILED" | tee -a $REPORT

# 4 — Audit log review
echo "" | tee -a $REPORT
echo "--- Audit Events Today ---" | tee -a $REPORT
echo "Identity changes:" | tee -a $REPORT
ausearch -k identity --start today 2>/dev/null | grep "type=SYSCALL" | wc -l | xargs echo "  Count:" | tee -a $REPORT
echo "Privilege escalation:" | tee -a $REPORT
ausearch -k privilege_escalation --start today 2>/dev/null | grep "type=SYSCALL" | wc -l | xargs echo "  Count:" | tee -a $REPORT

# 5 — Disk usage
echo "" | tee -a $REPORT
echo "--- Disk Usage ---" | tee -a $REPORT
df -h / | tee -a $REPORT
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "[WARN] Disk usage above 80% — $DISK_USAGE%" | tee -a $REPORT
else
    echo "[PASS] Disk usage: $DISK_USAGE%" | tee -a $REPORT
fi

# 6 — Memory usage
echo "" | tee -a $REPORT
echo "--- Memory Usage ---" | tee -a $REPORT
free -h | tee -a $REPORT

# 7 — Security updates available
echo "" | tee -a $REPORT
echo "--- Security Updates ---" | tee -a $REPORT
UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
if [ "$UPDATES" -gt 0 ]; then
    echo "[WARN] $UPDATES security updates available" | tee -a $REPORT
else
    echo "[PASS] No security updates pending" | tee -a $REPORT
fi

# 8 — UFW status
echo "" | tee -a $REPORT
echo "--- Firewall Rules ---" | tee -a $REPORT
ufw status | tee -a $REPORT

# 9 — Caddy TLS cert expiry
echo "" | tee -a $REPORT
echo "--- TLS Certificate Expiry ---" | tee -a $REPORT
EXPIRY=$(openssl x509 -enddate -noout -in /etc/caddy/cert.pem 2>/dev/null | cut -d= -f2)
echo "Cert expires: $EXPIRY" | tee -a $REPORT

echo "" | tee -a $REPORT
echo "============================================================" | tee -a $REPORT
echo "  Report saved to: $REPORT" | tee -a $REPORT
echo "============================================================" | tee -a $REPORT
