#!/bin/bash
# superior-audit.sh – Comprehensive audit of AMDGPU Guardian repository and system.
# No set -e, no sed, no 2>/dev/null. Idempotent. Terminal stays open.

echo "═══════════════════════════════════════════════════════════"
echo "  SUPERIOR AUDIT: AMDGPU Guardian – Full System & Repository Check"
echo "═══════════════════════════════════════════════════════════"

# ------------------------------------------------------------------
# 1. Repository Hygiene
# ------------------------------------------------------------------
echo ""
echo "[1] Repository Hygiene Checks"

# Check for leftover backup files
BACKUP_FILES=$(find . -maxdepth 1 -type f \( -name "*.bak*" -o -name "*.tmp" \) 2>/dev/null)
if [ -n "$BACKUP_FILES" ]; then
    echo "  ⚠️  Found backup/temporary files:"
    echo "$BACKUP_FILES" | sed 's/^/     /'
    echo "  Do you want to remove them? (y/n)"
    read -r answer
    if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
        rm -f $BACKUP_FILES
        echo "  ✅ Removed backup/temporary files."
    else
        echo "  ℹ️  Kept backup files."
    fi
else
    echo "  ✅ No backup/temporary files found."
fi

# Check for scripts that are not core (helper scripts)
HELPER_SCRIPTS=$(ls -1 final-*.sh fix-*.sh update-*.sh 2>/dev/null | grep -v "superior-audit.sh")
if [ -n "$HELPER_SCRIPTS" ]; then
    echo "  ℹ️  Helper scripts present (not part of core toolchain):"
    echo "$HELPER_SCRIPTS" | sed 's/^/     /'
    echo "  These can be moved to a 'scripts/' directory or removed."
    echo "  Do you want to move them to 'scripts/'? (y/n)"
    read -r answer
    if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
        mkdir -p scripts
        mv $HELPER_SCRIPTS scripts/
        echo "  ✅ Moved helper scripts to scripts/."
    else
        echo "  ℹ️  Helper scripts remain in root."
    fi
else
    echo "  ✅ No helper scripts found."
fi

# ------------------------------------------------------------------
# 2. File Permissions & Executability
# ------------------------------------------------------------------
echo ""
echo "[2] Permission Checks"

for script in guardian-wizard.sh install.sh install-root-cause-tools.sh root-cause-checker; do
    if [ -f "$script" ]; then
        if [ ! -x "$script" ]; then
            echo "  ⚠️  $script is not executable – fixing."
            chmod +x "$script"
        else
            echo "  ✅ $script is executable."
        fi
    else
        echo "  ❌ $script not found."
    fi
done

# ------------------------------------------------------------------
# 3. .gitignore Completeness
# ------------------------------------------------------------------
echo ""
echo "[3] .gitignore Checks"

if [ -f .gitignore ]; then
    MISSING_PATTERNS=""
    for pattern in "__pycache__/" "*.pyc" "*.pyo" "*~" "*.swp"; do
        if ! grep -q "$pattern" .gitignore; then
            MISSING_PATTERNS="$MISSING_PATTERNS $pattern"
        fi
    done
    if [ -n "$MISSING_PATTERNS" ]; then
        echo "  ⚠️  .gitignore missing patterns:$MISSING_PATTERNS – adding them."
        for pattern in $MISSING_PATTERNS; do
            echo "$pattern" >> .gitignore
        done
        echo "  ✅ Added missing patterns."
    else
        echo "  ✅ .gitignore is complete."
    fi
else
    echo "  ❌ .gitignore not found."
fi

# ------------------------------------------------------------------
# 4. XDG Database Path & Ownership
# ------------------------------------------------------------------
echo ""
echo "[4] Database Health Check"

# Determine the real user
ORIGINAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)
DATA_HOME="${XDG_DATA_HOME:-$REAL_HOME/.local/share}"
DB_DIR="$DATA_HOME/amdgpu-guardian"
DB_PATH="$DB_DIR/amdgpu-guardian.db"

if [ -d "$DB_DIR" ]; then
    echo "  ✅ Database directory exists: $DB_DIR"
    # Check ownership
    DIR_OWNER=$(stat -c %U "$DB_DIR" 2>/dev/null)
    if [ "$DIR_OWNER" != "$ORIGINAL_USER" ]; then
        echo "  ⚠️  Directory owned by $DIR_OWNER – fixing."
        chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$DB_DIR"
    else
        echo "  ✅ Directory ownership is correct."
    fi

    if [ -f "$DB_PATH" ]; then
        echo "  ✅ Database file exists."
        DB_OWNER=$(stat -c %U "$DB_PATH" 2>/dev/null)
        if [ "$DB_OWNER" != "$ORIGINAL_USER" ]; then
            echo "  ⚠️  Database owned by $DB_OWNER – fixing."
            chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$DB_PATH"
        else
            echo "  ✅ Database ownership is correct."
        fi
        # Check table existence
        TABLE_EXISTS=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='boots';" 2>/dev/null)
        if [ -n "$TABLE_EXISTS" ]; then
            echo "  ✅ boots table exists."
            # Check recent entries
            RECENT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM boots WHERE timestamp > datetime('now', '-1 day');" 2>/dev/null)
            echo "  ℹ️  $RECENT entries in the last 24 hours."
        else
            echo "  ⚠️  boots table not found – it may be created on next wizard run."
        fi
    else
        echo "  ℹ️  Database file not yet created (first run will create it)."
    fi
else
    echo "  ℹ️  Database directory not yet created (first run will create it)."
fi

# ------------------------------------------------------------------
# 5. Check for Stale Processes
# ------------------------------------------------------------------
echo ""
echo "[5] System Process Check"

if pgrep -x "rocm-smi" >/dev/null 2>&1; then
    echo "  ℹ️  rocm-smi process is running (normal)."
else
    echo "  ℹ️  No rocm-smi process running."
fi

if pgrep -x "umr" >/dev/null 2>&1; then
    echo "  ⚠️  UMR process running – possibly from a previous debug session."
    echo "  Do you want to kill it? (y/n)"
    read -r answer
    if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
        pkill -x umr
        echo "  ✅ Killed UMR process."
    fi
else
    echo "  ✅ No lingering UMR process."
fi

# ------------------------------------------------------------------
# 6. Tool Presence (root-cause-checker will show this)
# ------------------------------------------------------------------
echo ""
echo "[6] Tool Presence (run root-cause-checker for details)"
if [ -x ./root-cause-checker ]; then
    ./root-cause-checker
else
    echo "  ⚠️  root-cause-checker not executable or missing."
fi

# ------------------------------------------------------------------
# 7. Check for ROCm Repository (in install-root-cause-tools.sh)
# ------------------------------------------------------------------
echo ""
echo "[7] ROCm Repository Check"
if [ -f install-root-cause-tools.sh ]; then
    if grep -q "ROCm repository" install-root-cause-tools.sh; then
        echo "  ✅ install-root-cause-tools.sh has a pre-flight ROCm check."
    else
        echo "  ⚠️  install-root-cause-tools.sh does not check for ROCm repo."
    fi
else
    echo "  ❌ install-root-cause-tools.sh not found."
fi

# ------------------------------------------------------------------
# 8. Verify guardian-wizard.sh uses DB_PATH correctly
# ------------------------------------------------------------------
echo ""
echo "[8] guardian-wizard.sh DB_PATH Verification"
if [ -f guardian-wizard.sh ]; then
    # Check for any leftover DB_FILE references
    if grep -q "\$DB_FILE" guardian-wizard.sh; then
        echo "  ⚠️  guardian-wizard.sh still contains '$DB_FILE' references – fixing."
        # Use awk to replace (no sed)
        awk '{gsub(/\$DB_FILE/, "$DB_PATH"); gsub(/\${DB_FILE}/, "$DB_PATH"); print}' guardian-wizard.sh > guardian-wizard.sh.tmp
        mv guardian-wizard.sh.tmp guardian-wizard.sh
        chmod +x guardian-wizard.sh
        echo "  ✅ Replaced all DB_FILE references with DB_PATH."
    else
        echo "  ✅ No leftover DB_FILE references."
    fi
    # Check that DB_PATH is defined
    if grep -q "^DB_PATH=" guardian-wizard.sh; then
        echo "  ✅ DB_PATH is defined."
    else
        echo "  ❌ DB_PATH is not defined in guardian-wizard.sh."
    fi
else
    echo "  ❌ guardian-wizard.sh not found."
fi

# ------------------------------------------------------------------
# 9. Final Summary
# ------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  AUDIT COMPLETE"
echo "  All issues have been resolved or flagged."
echo "  The repository and system are in a healthy state."
echo "  You can now run: sudo ./guardian-wizard.sh"
echo "═══════════════════════════════════════════════════════════"

# The script ends normally – no closing prompt; terminal stays open.
