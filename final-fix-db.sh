#!/bin/bash
# final-fix-db.sh – Robust insertion of XDG DB_PATH block.
# No set -e, no sed, no 2>/dev/null. Keeps terminal open.

if [ ! -f guardian-wizard.sh ]; then
    echo "Error: guardian-wizard.sh not found."
    exit 1
fi

cp guardian-wizard.sh guardian-wizard.sh.bak3
echo "✅ Backup saved as guardian-wizard.sh.bak3"

# Build the new XDG block as a variable (with proper escaping for awk)
NEW_BLOCK=$(cat <<'BLOCKEOF'
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
BLOCKEOF
)

# Use awk to:
# 1. Remove any existing line that sets DB_FILE (including comments)
# 2. Insert the new block after the color definitions (search for "NC='\033[0m'")
# 3. Replace all references to DB_FILE with DB_PATH

awk -v new_block="$NEW_BLOCK" '
    # Skip lines that set DB_FILE (including ${DB_FILE} patterns)
    /^[[:space:]]*DB_FILE=/ { next }
    /^[[:space:]]*DB_FILE="/ { next }
    /^[[:space:]]*DB_FILE='\''/ { next }

    # When we find the line with NC='\033[0m', print the new block right after it
    /NC='\''\\033\[0m'\''/ {
        print
        print new_block
        next
    }

    # For all other lines, replace $DB_FILE and ${DB_FILE} with DB_PATH
    {
        gsub(/\$DB_FILE/, "$DB_PATH")
        gsub(/\${DB_FILE}/, "$DB_PATH")
        print
    }
' guardian-wizard.sh.bak3 > guardian-wizard.sh

chmod +x guardian-wizard.sh
echo "✅ Updated guardian-wizard.sh with XDG block and substituted all DB_FILE references."

# Optional: also update the SQLite commands to use DB_PATH consistently (they should already be updated)
# Now test the script
echo ""
echo "Do you want to test the updated script now? (y/n)"
read -r answer
if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
    sudo ./guardian-wizard.sh
else
    echo "You can test later with: sudo ./guardian-wizard.sh"
fi

echo ""
echo "If the error persists, you can manually create the table with:"
echo "  sqlite3 ~/.local/share/amdgpu-guardian/amdgpu-guardian.db \"CREATE TABLE boots (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, kernel TEXT, flip_errors INTEGER, ta_warnings INTEGER, vendor_warnings INTEGER, param_active TEXT);\""
echo ""
echo "You can also check the DB_PATH definition by running:"
echo "  grep -A 5 \"DB_PATH=\" guardian-wizard.sh"
