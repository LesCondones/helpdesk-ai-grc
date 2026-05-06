#!/bin/bash
# =============================================================================
# VM Setup Script — Help Desk AI GRC Project
# Runs on: Your Mac (NOT the VM)
# Purpose: Creates and configures the Ubuntu 24.04 VM in VMware Fusion
# Frameworks: NIST 800-53 CM-2 (Baseline Configuration)
# =============================================================================
# USAGE:
#   1. Download Ubuntu 24.04 LTS Server ARM ISO from ubuntu.com
#   2. Edit the configuration section below
#   3. chmod +x setup-vm.sh
#   4. ./setup-vm.sh
# =============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# =============================================================================
# CONFIGURATION — Edit these before running
# =============================================================================

# VM name and location
VM_NAME="helpdesk-ai-server"
VM_STORE="/Volumes/T7"                          # Your T7 SSD
VM_DIR="$VM_STORE/${VM_NAME}.vmwarevm"
VMX_FILE="$VM_DIR/${VM_NAME}.vmx"
VMDK_FILE="$VM_DIR/Virtual Disk.vmdk"

# VM Hardware specs
RAM_MB=8192                                     # 8 GB RAM
CPU_CORES=4                                     # 4 vCPUs
DISK_GB=60                                      # 60 GB disk
DISK_MB=$((DISK_GB * 1024))

# Ubuntu ISO — update this path to wherever you saved the ISO
UBUNTU_ISO="$HOME/Downloads/ubuntu-24.04.4-live-server-arm64.iso"

# Network — bridged so VM gets its own IP on your network
NETWORK_TYPE="bridged"

# VMware Fusion paths
VMRUN="/Applications/VMware Fusion.app/Contents/Library/vmrun"
VDISKMANAGER="/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager"
OVFTOOL="/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool"

# =============================================================================

echo ""
echo "============================================================"
echo "  VM Setup — Help Desk AI GRC Project"
echo "  VM: $VM_NAME"
echo "  Location: $VM_DIR"
echo "  Specs: ${CPU_CORES} vCPU | ${RAM_MB}MB RAM | ${DISK_GB}GB Disk"
echo "============================================================"
echo ""

# =============================================================================
section "STEP 1 — Preflight Checks"
# =============================================================================

# Check VMware Fusion is installed
if [[ ! -f "$VMRUN" ]]; then
  error "VMware Fusion not found at expected path. Is it installed?"
fi
log "VMware Fusion found."

# Check ISO exists
if [[ ! -f "$UBUNTU_ISO" ]]; then
  error "Ubuntu ISO not found at: $UBUNTU_ISO\nDownload from: https://ubuntu.com/download/server/arm"
fi
log "Ubuntu ISO found: $UBUNTU_ISO"

# Check T7 SSD is mounted
if [[ ! -d "$VM_STORE" ]]; then
  error "T7 SSD not found at $VM_STORE. Is it plugged in?"
fi
log "T7 SSD found at $VM_STORE."

# Check VM doesn't already exist
if [[ -d "$VM_DIR" ]]; then
  warn "VM directory already exists at $VM_DIR"
  read -p "Delete existing VM and recreate? (yes/no): " OVERWRITE
  if [[ "$OVERWRITE" == "yes" ]]; then
    # Stop VM if running
    "$VMRUN" stop "$VMX_FILE" hard 2>/dev/null || true
    rm -rf "$VM_DIR"
    log "Existing VM deleted."
  else
    warn "Exiting — VM already exists."
    exit 0
  fi
fi

# Check disk space on T7
AVAILABLE_KB=$(df "$VM_STORE" | awk 'NR==2 {print $4}')
AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))
REQUIRED_GB=$((DISK_GB + 5))
if [[ $AVAILABLE_GB -lt $REQUIRED_GB ]]; then
  error "Not enough space on T7. Need ${REQUIRED_GB}GB, have ${AVAILABLE_GB}GB."
fi
log "Disk space check passed (${AVAILABLE_GB}GB available on T7)."

# =============================================================================
section "STEP 2 — Create VM Directory and Virtual Disk"
# =============================================================================

log "Creating VM directory: $VM_DIR"
mkdir -p "$VM_DIR"

log "Creating ${DISK_GB}GB virtual disk (this may take a moment)..."
"$VDISKMANAGER" \
  -c \
  -s "${DISK_GB}GB" \
  -a nvme \
  -t 0 \
  "$VMDK_FILE"

log "Virtual disk created."

# =============================================================================
section "STEP 3 — Write VMX Configuration File"
# =============================================================================

log "Writing VMX config..."

cat > "$VMX_FILE" << EOF
# VMware Fusion VM Configuration
# GRC Project: Help Desk AI Server
# Framework: NIST 800-53 CM-2 (Baseline Configuration)
# Created: $(date +%Y-%m-%d)

.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "21"

# VM Identity
displayName = "$VM_NAME"
guestOS = "ubuntu-64"
annotation = "Help Desk AI GRC Project | Ubuntu 24.04 LTS | NIST 800-53 hardened"

# CPU — NIST 800-53 SC-6 (Resource Availability)
numvcpus = "$CPU_CORES"
cpuid.coresPerSocket = "2"

# RAM
memsize = "$RAM_MB"

# Disk — NVMe (60GB)
nvme0.present = "TRUE"
nvme0:0.present = "TRUE"
nvme0:0.fileName = "Virtual Disk.vmdk"

# CD/DVD — Ubuntu ISO for initial install
sata0.present = "TRUE"
sata0:1.present = "TRUE"
sata0:1.deviceType = "cdrom-image"
sata0:1.fileName = "$UBUNTU_ISO"
sata0:1.startConnected = "TRUE"

# Network — Bridged so VM gets real IP on your network
ethernet0.present = "TRUE"
ethernet0.connectionType = "$NETWORK_TYPE"
ethernet0.virtualDev = "vmxnet3"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.addressType = "generated"

# USB
usb.present = "TRUE"
ehci.present = "TRUE"

# Display
svga.graphicsMemoryKB = "524288"

# Security hardening for VMX
# Disable drag and drop (reduces attack surface)
isolation.tools.dnd.disable = "TRUE"
isolation.tools.copy.disable = "TRUE"
isolation.tools.paste.disable = "TRUE"

# Disable shared folders (not needed, reduces attack surface)
sharedFolder.maxNum = "0"

# Boot order — CD first for install, then we'll change to HDD
bios.bootOrder = "CDROM,HDD"
bios.bootDelay = "3000"

# Logging
vmci0.present = "TRUE"
EOF

log "VMX file written."

# =============================================================================
section "STEP 4 — Register and Start VM"
# =============================================================================

log "Registering VM with VMware Fusion..."
"$VMRUN" register "$VMX_FILE" 2>/dev/null || true

log "Starting VM for Ubuntu installation..."
"$VMRUN" start "$VMX_FILE" gui

# =============================================================================
section "NEXT STEPS — Manual Installation Required"
# =============================================================================

echo ""
echo "============================================================"
echo -e "${GREEN}  VM Created and Started!${NC}"
echo "============================================================"
echo ""
echo "The VM is now booting from the Ubuntu ISO."
echo "Complete the Ubuntu Server installation manually:"
echo ""
echo "  During install, set:"
echo "  - Username:     grcadmin"
echo "  - Hostname:     helpdesk-ai-server"
echo "  - Enable:       OpenSSH server (check the box)"
echo "  - Storage:      Use entire disk with LVM"
echo "  - DO NOT install any snaps during install"
echo ""
echo "  After install completes and VM reboots:"
echo ""
echo "  1. Find the VM IP:"
echo "     ip addr show"
echo ""
echo "  2. Copy your SSH key from your Mac:"
echo "     ssh-copy-id -i ~/.ssh/helpdesk-ai-grc.pub -p 22 grcadmin@<VM_IP>"
echo ""
echo "  3. Copy the hardening script to the VM:"
echo "     scp -P 22 phase1-hardening.sh grcadmin@<VM_IP>:~/"
echo ""
echo "  4. SSH in and run it:"
echo "     ssh -p 22 grcadmin@<VM_IP>"
echo "     chmod +x phase1-hardening.sh"
echo "     sudo ./phase1-hardening.sh"
echo ""
echo "  5. After hardening completes, change boot order:"
echo "     VM Settings → Startup Disk → Hard Disk (NVMe)"
echo ""
echo "  6. Take a VMware snapshot: Phase1-Hardened-Baseline"
echo "============================================================"
echo ""
