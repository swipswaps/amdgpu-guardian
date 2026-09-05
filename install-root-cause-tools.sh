#!/bin/bash
# install-root-cause-tools.sh – Idempotent installer for UMR, RGD, RVS.
# Handles existing /opt/umr, skips missing ROCm packages, builds in /tmp.
# No set -e; explicit error checking.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Final)"
echo "═══════════════════════════════════════════════════════════"

# ------------------------------------------------------------------
# Pre-flight: Check for ROCm repository
# ------------------------------------------------------------------
if ! grep -q "repo.radeon.com/rocm" /etc/yum.repos.d/*.repo 2>/dev/null; then
    echo "⚠️  ROCm repository not found."
    echo "  To add it, run:"
    echo "    sudo tee /etc/yum.repos.d/rocm.repo <<'REPOEOF'"
    echo "[ROCm]"
    echo "name=ROCm"
    echo "baseurl=https://repo.radeon.com/rocm/yum/rpm"
    echo "enabled=1"
    echo "gpgcheck=1"
    echo "gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key"
    echo "REPOEOF"
    echo ""
    echo "Then rerun this script."
    exit 1
fi

# ------------------------------------------------------------------
# 1. Install dnf packages (skip unavailable)
# ------------------------------------------------------------------
echo "[1] Installing dnf packages (skipping unavailable)..."
sudo dnf install -y rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool meson ninja-build
sudo dnf install -y --skip-unavailable rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool meson ninja-build rocm-dkms rocm-dev rocprofiler rocgdb

# ------------------------------------------------------------------
# 2. UMR – Meson build (handles existing /opt/umr)
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register)..."

if [ -d /opt/umr ]; then
    echo "  /opt/umr already exists – pulling latest changes and cleaning build."
    cd /opt/umr || exit
    sudo git pull --rebase
    # Remove stale build directory if present
    if [ -d build ]; then
        sudo rm -rf build
        echo "  Removed stale build/ directory."
    fi
else
    sudo git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /opt/umr
    cd /opt/umr || exit
fi

# Build with Meson (use --reconfigure to be safe)
sudo meson setup build --reconfigure
sudo ninja -C build
sudo ninja -C build install
echo "  UMR installed."

# ------------------------------------------------------------------
# 3. Radeon GPU Detective – CMake build in /tmp
# ------------------------------------------------------------------
echo "[3] Installing Radeon GPU Detective..."

# Clone to /tmp (writable)
if [ -d /tmp/radeon_gpu_detective ]; then
    echo "  /tmp/radeon_gpu_detective already exists – pulling latest."
    cd /tmp/radeon_gpu_detective || exit
    git pull --rebase
else
    git clone https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/radeon_gpu_detective
    cd /tmp/radeon_gpu_detective || exit
fi

# Build in /tmp/build (clean)
if [ -d build ]; then
    rm -rf build
fi
mkdir build && cd build || exit
cmake ..
make -j$(nproc)
sudo make install
echo "  RGD installed."

# ------------------------------------------------------------------
# 4. ROCm Validation Suite – CMake build in /tmp
# ------------------------------------------------------------------
echo "[4] Installing ROCm Validation Suite..."

if [ -d /tmp/ROCmValidationSuite ]; then
    echo "  /tmp/ROCmValidationSuite already exists – pulling latest."
    cd /tmp/ROCmValidationSuite || exit
    git pull --rebase
else
    git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/ROCmValidationSuite
    cd /tmp/ROCmValidationSuite || exit
fi

if [ -d build ]; then
    rm -rf build
fi
mkdir build && cd build || exit
cmake ..
make -j$(nproc)
sudo make install
echo "  RVS installed."

# ------------------------------------------------------------------
# 5. Install root-cause-checker
# ------------------------------------------------------------------
echo "[5] Installing root-cause-checker..."
if [ -f ./root-cause-checker ]; then
    sudo cp ./root-cause-checker /usr/local/bin/root-cause-checker
    sudo chmod +x /usr/local/bin/root-cause-checker
    echo "  root-cause-checker installed."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Installation complete."
echo "  Run 'root-cause-checker' to verify."
echo "  Run 'sudo ./guardian-wizard.sh' to run health check."
echo "═══════════════════════════════════════════════════════════"
