#!/bin/bash
# install-root-cause-tools.sh – Final correct version with explicit exit codes.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Final Correct)"
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
    echo "Then rerun this script."
    exit 1
fi

# ------------------------------------------------------------------
# 1. Install dnf packages (skip unavailable)
# ------------------------------------------------------------------
echo "[1] Installing dnf packages (skipping unavailable)..."
sudo dnf install -y rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool meson ninja-build
sudo dnf install -y --skip-unavailable rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool meson ninja-build rocm-dkms rocm-dev rocprofiler rocgdb rocprim rocblas rocrand

# ------------------------------------------------------------------
# 2. UMR – Fresh clone and clean build
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register)..."

# Completely remove old directory if present
if [ -d /opt/umr ]; then
    echo "  Removing old /opt/umr..."
    sudo rm -rf /opt/umr
fi

echo "  Cloning UMR..."
sudo git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /opt/umr
cd /opt/umr || { echo "ERROR: Failed to enter /opt/umr"; exit 1; }

echo "  Setting up meson build..."
sudo meson setup build
if [ $? -ne 0 ]; then
    echo "ERROR: UMR Meson setup failed."
    exit 1
fi

echo "  Building UMR..."
sudo ninja -C build
if [ $? -ne 0 ]; then
    echo "ERROR: UMR build failed."
    exit 1
fi

echo "  Installing UMR..."
sudo ninja -C build install
if [ $? -ne 0 ]; then
    echo "ERROR: UMR installation failed."
    exit 1
fi
echo "  ✅ UMR installed."

# ------------------------------------------------------------------
# 3. Radeon GPU Detective – CMake build with submodules
# ------------------------------------------------------------------
echo "[3] Installing Radeon GPU Detective..."

if [ -d /tmp/radeon_gpu_detective ]; then
    echo "  /tmp/radeon_gpu_detective exists – removing for fresh clone."
    rm -rf /tmp/radeon_gpu_detective
fi

echo "  Cloning RGD with --recursive..."
git clone --recursive https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/radeon_gpu_detective
cd /tmp/radeon_gpu_detective || { echo "ERROR: Failed to enter RGD directory"; exit 1; }

mkdir build && cd build || { echo "ERROR: Failed to create build directory"; exit 1; }
cmake .. || { echo "ERROR: RGD CMake configuration failed."; exit 1; }
make -j$(nproc) || { echo "ERROR: RGD build failed."; exit 1; }
sudo make install || { echo "ERROR: RGD installation failed."; exit 1; }
echo "  ✅ RGD installed."

# ------------------------------------------------------------------
# 4. ROCm Validation Suite – CMake build with ROCm dependencies
# ------------------------------------------------------------------
echo "[4] Installing ROCm Validation Suite..."

if ! ldconfig -p 2>/dev/null | grep -q rocblas; then
    echo "⚠️  rocblas not found. RVS requires rocblas."
    echo "  To install: sudo dnf install rocblas"
    echo "  Skipping RVS."
else
    if [ -d /tmp/ROCmValidationSuite ]; then
        rm -rf /tmp/ROCmValidationSuite
    fi

    git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/ROCmValidationSuite
    cd /tmp/ROCmValidationSuite || { echo "ERROR: Failed to enter RVS directory"; exit 1; }

    mkdir build && cd build || { echo "ERROR: Failed to create RVS build directory"; exit 1; }
    cmake .. || { echo "ERROR: RVS CMake configuration failed."; exit 1; }
    make -j$(nproc) || { echo "ERROR: RVS build failed."; exit 1; }
    sudo make install || { echo "ERROR: RVS installation failed."; exit 1; }
    echo "  ✅ RVS installed."
fi

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
echo "  ✅ ALL TOOLS INSTALLED SUCCESSFULLY"
echo "  Run 'root-cause-checker' to verify."
echo "  Run 'sudo ./guardian-wizard.sh' to run health check."
echo "═══════════════════════════════════════════════════════════"
exit 0
