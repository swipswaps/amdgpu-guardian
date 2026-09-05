#!/bin/bash
# update-db-path.sh – Idempotent update to use XDG Base Directory for SQLite database.
# No set -e, no sed, no 2>/dev/null. Keeps terminal open.

if [ ! -f guardian-wizard.sh ]; then
    echo "Error: guardian-wizard.sh not found."
    exit 1
fi

cp guardian-wizard.sh guardian-wizard.sh.bak
echo "✅ Backup saved as guardian-wizard.sh.bak"

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

# Now use "$DB_PATH" for all SQLite operations
BLOCKEOF
)

awk -v new_block="$NEW_BLOCK" '
    /^DB_FILE="\${HOME}\/\.amdgpu-guardian\.db"/ {
        print new_block
        next
    }
    {
        gsub(/\$DB_FILE/, "$DB_PATH")
        print
    }
' guardian-wizard.sh.bak > guardian-wizard.sh

chmod +x guardian-wizard.sh
echo "✅ Updated guardian-wizard.sh with XDG database path."

echo ""
echo "Do you want to commit and push this change to GitHub? (y/n)"
read -r answer
if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
    git add guardian-wizard.sh
    git commit -m "feat: Use XDG Base Directory for SQLite database (fixes sudo ownership)"
    git push origin master
    if [ $? -eq 0 ]; then
        echo "✅ Changes pushed to GitHub."
    else
        echo "❌ Push failed. Please run 'git push origin master' manually."
    fi
else
    echo "ℹ️  Changes staged. You can commit manually later."
fi

echo ""
echo "✅ Update complete. The database will now be stored in:"
echo "   ~/.local/share/amdgpu-guardian/amdgpu-guardian.db"
echo ""
echo "Backup of original script: guardian-wizard.sh.bak"
echo ""
echo "You can now test with: sudo ./guardian-wizard.sh"
