#!/bin/bash
# amdgpu-guardian: Unified AMDGPU Forensic & Remediation Framework
# Uses local psr.py (embedded), no runtime cloning.
# No set -e; no sed; stderr is visible.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
# ------------------------------------------------------------------
# Determine database path (XDG Base Directory compliant)
# ------------------------------------------------------------------
# 1. Get the original user (the one who invoked sudo, if any)
ORIGINAL_USER="${SUDO_USER:-$USER}"
# 2. Get that user's real home directory
REAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

# 3. Build the XDG data directory path
DATA_HOME="${XDG_DATA_HOME:-$REAL_HOME/.local/share}"
DB_DIR="$DATA_HOME/amdgpu-guardian"
DB_PATH="$DB_DIR/amdgpu-guardian.db"

# 4. Create the directory with the original user's ownership
install -d -o "$ORIGINAL_USER" -g "$ORIGINAL_USER" "$DB_DIR"

# 5. If the database exists but is owned by root (e.g., from previous sudo runs),
#    fix the ownership so the original user can write to it later without sudo.
if [ -f "$DB_PATH" ] && [ "$(stat -c %u "$DB_PATH")" != "$(id -u "$ORIGINAL_USER")" ]; then
    chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$DB_PATH"
fi

# Safety check: if DB_PATH is still empty, fallback to a known location
if [ -z "$DB_PATH" ]; then
    echo "Warning: DB_PATH is empty, falling back to default."
    DB_PATH="$HOME/.local/share/amdgpu-guardian/amdgpu-guardian.db"
    mkdir -p "$(dirname "$DB_PATH")"
fi

# Now use "$DB_PATH" for all SQLite operations
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}AMDGPU Guardian${NC} - Health, Forensics & Remediation"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

KERNEL_VER=$(uname -r)
echo -e "\n${YELLOW}[KERNEL]${NC} Running: $KERNEL_VER"
if [[ "$KERNEL_VER" > "7.1.0" ]]; then
  PSR_PATCH_STATUS="PRESENT (Upstream backport detected)"
else
  PSR_PATCH_STATUS="ABSENT (Requires workaround)"
fi
echo -e "  PSR architectural fix: $PSR_PATCH_STATUS"

CURRENT_MASK=""
if grep -q "amdgpu.dcdebugmask" /proc/cmdline; then
  CURRENT_MASK=$(grep -o "amdgpu.dcdebugmask=[^ ]*" /proc/cmdline)
  echo -e "\n${YELLOW}[PARAMETER]${NC} Active workaround: $CURRENT_MASK"
else
  echo -e "\n${YELLOW}[PARAMETER]${NC} No debugmask active (Default driver state)."
fi

echo -e "\n${YELLOW}[PSR DETECTION]${NC} Using embedded psr.py..."
if [ -f ./psr.py ]; then
  python3 ./psr.py
else
  echo "  [WARN] psr.py not found locally."
fi

echo -e "\n${YELLOW}[DIAGNOSTICS]${NC} Scanning kernel ring buffer..."
FLIP_COUNT=$(dmesg 2>/dev/null | grep -ci "flip_done")
if [ $FLIP_COUNT -eq 0 ]; then
  echo -e "  ${GREEN}✓ flip_done timeouts: NONE${NC}"
  FLIP_STATUS="PASS"
else
  echo -e "  ${RED}✗ flip_done timeouts: $FLIP_COUNT occurrences${NC}"
  FLIP_STATUS="FAIL"
fi

TA_COUNT=$(dmesg 2>/dev/null | grep -ci "LOAD_TA")
VENDOR_COUNT=$(dmesg 2>/dev/null | grep -ci "vendor infoframe")
if [ $TA_COUNT -eq 0 ] && [ $VENDOR_COUNT -eq 0 ]; then
  echo -e "  ${GREEN}✓ Firmware init warnings: NONE${NC}"
else
  echo -e "  ${YELLOW}⚠ Firmware warnings: LOAD_TA ($TA_COUNT), VENDOR ($VENDOR_COUNT)${NC}"
fi

SMI_CMD=""
if command -v rocm-smi &>/dev/null; then
  SMI_CMD="rocm-smi"
elif command -v amd-smi &>/dev/null; then
  SMI_CMD="amd-smi"
fi

if [ -n "$SMI_CMD" ]; then
  echo -e "\n${YELLOW}[TELEMETRY]${NC} Using $SMI_CMD:"
  $SMI_CMD --showproductname --showpower --showtemp --showuse 2>/dev/null | head -10
else
  echo -e "\n${YELLOW}[TELEMETRY]${NC} No AMD SMI tool found. Install 'rocm-smi' or 'amd-smi'."
fi

echo -e "\n${YELLOW}[REMEDIATION PLAN]${NC}"
if [ "$FLIP_STATUS" = "FAIL" ]; then
  echo -e "  ${RED}Action Required:${NC} PSR race condition detected."
  if [[ "$KERNEL_VER" > "7.1.0" ]]; then
    echo -e "  ${GREEN}Kernel is fixed, but errors persist. Check for external factors (e.g., monitor EDID).${NC}"
  else
    echo -e "  Apply workaround: add 'amdgpu.dcdebugmask=0x410' to GRUB_CMDLINE_LINUX"
    echo -e "  Command: sudo grubby --update-kernel=ALL --args='amdgpu.dcdebugmask=0x410'"
  fi
else
  echo -e "  ${GREEN}✓ No critical errors detected. Driver is operationally stable.${NC}"


# ------------------------------------------------------------------
# FORENSIC TOOL STATUS
# ------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  FORENSIC TOOL STATUS"
echo "═══════════════════════════════════════════════════════════"

if command -v umr &>/dev/null; then
    echo "  ✅ UMR (register debugger) – installed"
    UMR_INSTALLED=1
else
    echo "  ❌ UMR (register debugger) – not installed"
    UMR_INSTALLED=0
fi

if command -v radeon-gpu-detective &>/dev/null || command -v rgd &>/dev/null; then
    echo "  ✅ RGD (post-mortem) – installed"
    RGD_INSTALLED=1
else
    echo "  ❌ RGD (post-mortem) – not installed"
    RGD_INSTALLED=0
fi

if command -v rvs &>/dev/null || command -v rocm-validation-suite &>/dev/null; then
    echo "  ✅ RVS (stress testing) – installed"
    RVS_INSTALLED=1
else
    echo "  ❌ RVS (stress testing) – not installed"
    RVS_INSTALLED=0
fi

if [ $UMR_INSTALLED -eq 0 ] || [ $RGD_INSTALLED -eq 0 ] || [ $RVS_INSTALLED -eq 0 ]; then
    echo ""
    echo "  ⚠️  Some forensic tools are missing."
    echo "  To install all tools, run:"
    echo "    ./install-root-cause-tools.sh"
fi

if [ "$FLIP_STATUS" = "FAIL" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  FORENSIC RECOMMENDATIONS (Critical Error Detected)"
    echo "═══════════════════════════════════════════════════════════"
    echo "  1. Dump GPU ring buffer: sudo umr -R ring_0"
    echo "  2. Dump VRAM: sudo umr -r -o vram.bin"
    echo "  3. If crash dump exists: rgd --input crash.rgd --output report.txt"
    echo "  4. Check kernel debugfs: cat /sys/kernel/debug/dri/0/amdgpu_ring_gfx"
fi
echo "═══════════════════════════════════════════════════════════"

  if [ -n "$CURRENT_MASK" ]; then
    echo -e "  ${YELLOW}Note: Debugmask is active unnecessarily. Consider removing it.${NC}"
  fi
fi

if command -v sqlite3 &>/dev/null; then
  mkdir -p "$(dirname "$DB_PATH")"
  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS boots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    kernel TEXT,
    flip_errors INTEGER,
    ta_warnings INTEGER,
    vendor_warnings INTEGER,
    param_active TEXT
  );"
  sqlite3 "$DB_PATH" "INSERT INTO boots (kernel, flip_errors, ta_warnings, vendor_warnings, param_active)
    VALUES ('$KERNEL_VER', $FLIP_COUNT, $TA_COUNT, $VENDOR_COUNT, '$CURRENT_MASK');"
  echo -e "\n${YELLOW}[PERSISTENCE]${NC} State logged to SQLite: $DB_PATH"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
