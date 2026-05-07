#!/bin/bash
# Deploy script — pulls latest code and restarts agent
# NIST 800-53 CM-3 (Configuration Change Control)

echo "[+] Pulling latest code from GitHub..."
cd ~/helpdesk-agent
git pull origin main

echo "[+] Installing any new dependencies..."
source ~/.local/bin/env
uv sync

echo "[+] Restarting helpdesk-agent service..."
sudo systemctl restart helpdesk-agent

echo "[+] Verifying service status..."
sudo systemctl status helpdesk-agent

echo "[+] Deploy complete at $(date)"
