#!/bin/bash
echo "Installing AMDGPU Guardian (embedded)..."
sudo dnf install -y git python3 sqlite3 rocm-smi || sudo dnf install -y git python3 sqlite3
sudo cp guardian-wizard.sh /usr/local/bin/amdgpu-guardian
sudo chmod +x /usr/local/bin/amdgpu-guardian
echo "Installed! Run with: sudo amdgpu-guardian"
