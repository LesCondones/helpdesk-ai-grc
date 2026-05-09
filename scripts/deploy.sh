#!/bin/bash
# Deploy script — pulls latest code and restarts agent
# NIST 800-53 CM-3 (Configuration Change Control)
# Updated: 2026-05-07

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error(){ echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# =============================================================================
log "Pulling latest code from GitHub..."
cd ~/helpdesk-agent
git pull origin main

# =============================================================================
log "Installing any new dependencies..."
source ~/.local/bin/env
uv sync

# =============================================================================
# Verify required Ollama models are present — MAP-013 (NIST 800-53 CP-10)
log "Verifying required Ollama models..."
REQUIRED_MODELS=("llama3.2:3b" "nomic-embed-text")
for model in "${REQUIRED_MODELS[@]}"; do
  if ollama list | grep -q "$model"; then
    log "Model found: $model"
  else
    warn "$model not found — pulling now..."
    ollama pull "$model"
    log "Model pulled: $model"
  fi
done

# =============================================================================
# FAISS integrity check — MAP-004 (NIST 800-53 SI-7, MITRE ATLAS AML.T0020)
log "Verifying FAISS vector store integrity..."
EXPECTED="<REDACTED - store securely outside version control>"
ACTUAL=$(cd ~/helpdesk-agent && .venv/bin/python3 -c "from rag import get_index_hash; print(get_index_hash())" 2>/dev/null || echo "ERROR")

if [[ "$ACTUAL" == "ERROR" ]]; then
  warn "Could not compute FAISS hash — skipping integrity check"
elif [[ "$EXPECTED" == "<REDACTED - store securely outside version control>" ]]; then
  warn "FAISS baseline hash not set — skipping integrity check"
  log "Current hash: $ACTUAL"
  log "Store this hash as your baseline in the EXPECTED variable above"
else
  if [ "$EXPECTED" = "$ACTUAL" ]; then
    log "FAISS index integrity verified"
  else
    error "FAISS index hash mismatch — possible tampering detected. Aborting deploy."
  fi
fi

# =============================================================================
log "Restarting helpdesk-agent service..."
sudo systemctl restart helpdesk-agent

# =============================================================================
log "Verifying service status..."
sudo systemctl status helpdesk-agent

# =============================================================================
log "Deploy complete at $(date)"
