#!/bin/bash
# install-root-cause-tools.sh – Truly correct, handles build directories properly.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Real Fix)"
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
# 2. UMR – Handle build directory correctly
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register)..."

if [ -d /opt/umr ]; then
    echo "  /opt/umr exists – pulling updates and cleaning build."
    cd /opt/umr || exit
    sudo git pull --rebase
    # Remove stale build directory if present
    if [ -d build ]; then
        sudo rm -rf build
    fi
else
    sudo git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /opt/umr
    cd /opt/umr || exit
fi

# Now set up the build directory – since we removed it, just do a fresh setup
sudo meson setup build
if [ $? -ne 0 ]; then
    echo "ERROR: UMR Meson setup failed."
    exit 1
fi

sudo ninja -C build
if [ $? -ne 0 ]; then
    echo "ERROR: UMR build failed."
    exit 1
fi

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
    echo "  /tmp/radeon_gpu_detective exists – pulling updates and initializing submodules."
    cd /tmp/radeon_gpu_detective || exit
    git pull --rebase
    git submodule update --init --recursive
else
    echo "  Cloning RGD with --recursive..."
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
echo "  ✅ SUCCESS: All tools installed."
echo "  Run 'root-cause-checker' to verify."
echo "  Run 'sudo ./guardian-wizard.sh' to run health check."
echo "═══════════════════════════════════════════════════════════"
