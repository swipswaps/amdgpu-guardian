#!/bin/bash
# install-root-cause-tools.sh – Final idempotent installer with proper error handling.
# Builds UMR (Meson), RGD (CMake with submodules), RVS (CMake with ROCm deps).
# Exits with error if critical dependencies are missing.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Final Fix)"
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
sudo dnf install -y --skip-unavailable rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool meson ninja-build rocm-dkms rocm-dev rocprofiler rocgdb rocblas rocprim rocrand

# ------------------------------------------------------------------
# 2. UMR – Meson build (idempotent)
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register)..."

if [ -d /opt/umr ]; then
    cd /opt/umr || exit
    sudo git pull --rebase
    if [ -d build ]; then
        sudo rm -rf build
    fi
else
    sudo git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /opt/umr
    cd /opt/umr || exit
fi

sudo meson setup build --reconfigure
sudo ninja -C build
sudo ninja -C build install
echo "  UMR installed."

# ------------------------------------------------------------------
# 3. Radeon GPU Detective – CMake build with submodules
# ------------------------------------------------------------------
echo "[3] Installing Radeon GPU Detective..."

# Clone with --recursive to get submodules
if [ -d /tmp/radeon_gpu_detective ]; then
    cd /tmp/radeon_gpu_detective || exit
    git pull --rebase
    git submodule update --init --recursive
else
    git clone --recursive https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/radeon_gpu_detective
    cd /tmp/radeon_gpu_detective || exit
fi

if [ -d build ]; then
    rm -rf build
fi
mkdir build && cd build || exit
cmake .. || { echo "ERROR: RGD CMake configuration failed."; exit 1; }
make -j$(nproc) || { echo "ERROR: RGD build failed."; exit 1; }
sudo make install || { echo "ERROR: RGD installation failed."; exit 1; }
echo "  RGD installed."

# ------------------------------------------------------------------
# 4. ROCm Validation Suite – CMake with ROCm dependencies
# ------------------------------------------------------------------
echo "[4] Installing ROCm Validation Suite..."

# Check for rocblas (required)
if ! ldconfig -p | grep -q rocblas; then
    echo "ERROR: rocblas library not found. Please install it:"
    echo "  sudo dnf install rocblas"
    echo "  (You may need the ROCm repository enabled.)"
    exit 1
fi

if [ -d /tmp/ROCmValidationSuite ]; then
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
cmake .. || { echo "ERROR: RVS CMake configuration failed."; exit 1; }
make -j$(nproc) || { echo "ERROR: RVS build failed."; exit 1; }
sudo make install || { echo "ERROR: RVS installation failed."; exit 1; }
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
echo "  SUCCESS: All tools installed."
echo "  Run 'root-cause-checker' to verify."
echo "  Run 'sudo ./guardian-wizard.sh' to run health check."
echo "═══════════════════════════════════════════════════════════"
