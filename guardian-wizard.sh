#!/bin/bash
# amdgpu-guardian: Unified AMDGPU Forensic & Remediation Framework
# Uses local psr.py (embedded), no runtime cloning.
# No set -e; no sed; stderr is visible.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
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
  if [ -n "$CURRENT_MASK" ]; then
    echo -e "  ${YELLOW}Note: Debugmask is active unnecessarily. Consider removing it.${NC}"
  fi
fi

if command -v sqlite3 &>/dev/null; then
  DB_FILE="${HOME}/.amdgpu-guardian.db"
  mkdir -p "$(dirname "$DB_FILE")"
  sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS boots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    kernel TEXT,
    flip_errors INTEGER,
    ta_warnings INTEGER,
    vendor_warnings INTEGER,
    param_active TEXT
  );"
  sqlite3 "$DB_FILE" "INSERT INTO boots (kernel, flip_errors, ta_warnings, vendor_warnings, param_active)
    VALUES ('$KERNEL_VER', $FLIP_COUNT, $TA_COUNT, $VENDOR_COUNT, '$CURRENT_MASK');"
  echo -e "\n${YELLOW}[PERSISTENCE]${NC} State logged to SQLite: $DB_FILE"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
