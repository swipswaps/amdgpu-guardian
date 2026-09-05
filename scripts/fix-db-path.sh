#!/bin/bash
# fix-db-path.sh – Replaces both $DB_FILE and ${DB_FILE} with DB_PATH.
# No set -e, no sed, no 2>/dev/null. Keeps terminal open.

if [ ! -f guardian-wizard.sh ]; then
    echo "Error: guardian-wizard.sh not found."
    exit 1
fi

cp guardian-wizard.sh guardian-wizard.sh.bak2
echo "✅ Backup saved as guardian-wizard.sh.bak2"

# Use awk to:
# 1. Replace both $DB_FILE and ${DB_FILE} with DB_PATH
# 2. Insert a safety check that DB_PATH is not empty
awk '
    # Replace $DB_FILE (literal) and ${DB_FILE} (with braces)
    {
        gsub(/\$DB_FILE/, "$DB_PATH")
        gsub(/\${DB_FILE}/, "$DB_PATH")
        print
    }
' guardian-wizard.sh.bak2 > guardian-wizard.sh

chmod +x guardian-wizard.sh
echo "✅ Updated guardian-wizard.sh with comprehensive DB_FILE → DB_PATH substitution."

# Optionally add a safety check right after the DB_PATH definition
# We'll insert a line that errors out if DB_PATH is empty.
# Find the line where DB_PATH is defined and add a check after it.
# We can do this with a simple insert using awk again.

# But for now, we'll just test it.
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
