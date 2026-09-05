#!/bin/bash
# install-root-cause-tools.sh – Comprehensive with all deps including gbm-devel.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Ultimate Final)"
echo "═══════════════════════════════════════════════════════════"

# ------------------------------------------------------------------
# Pre-flight: ROCm repository
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
# 1. Install all known build dependencies
# ------------------------------------------------------------------
echo "[1] Installing all build dependencies (including gbm-devel)..."
sudo dnf install -y \
    rocm-smi radeontop nvtop trace-cmd perf \
    git make gcc g++ cmake python3 sqlite3 \
    autoconf automake libtool meson ninja-build \
    ncurses-devel zlib-devel libdrm-devel \
    llvm-devel clang \
    gbm-devel libglvnd-devel libglvnd-egl \
    pkgconfig

# Skip unavailable ROCm packages (they are optional)
sudo dnf install -y --skip-unavailable \
    rocm-smi radeontop nvtop trace-cmd perf \
    git make gcc g++ cmake python3 sqlite3 \
    autoconf automake libtool meson ninja-build \
    ncurses-devel zlib-devel libdrm-devel \
    llvm-devel clang \
    gbm-devel libglvnd-devel libglvnd-egl \
    pkgconfig \
    rocm-dkms rocm-dev rocprofiler rocgdb rocprim rocblas rocrand

# ------------------------------------------------------------------
# 2. UMR – CMake build (now with gbm-devel)
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register)..."

if [ -d /tmp/umr ]; then
    rm -rf /tmp/umr
fi

git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /tmp/umr
cd /tmp/umr || { echo "ERROR: Failed to enter /tmp/umr"; exit 1; }

if [ -f CMakeLists.txt ]; then
    echo "  Building UMR with CMake (GUI enabled)..."
    mkdir build && cd build || { echo "ERROR: Failed to create build directory"; exit 1; }
    cmake .. -DUMR_ENABLE_GUI=ON || { echo "ERROR: CMake configuration failed."; exit 1; }
    make -j$(nproc) || { echo "ERROR: make failed."; exit 1; }
    sudo make install || { echo "ERROR: sudo make install failed."; exit 1; }
else
    echo "ERROR: No CMakeLists.txt found. Manual fallback:"
    echo "  cd /tmp/umr && mkdir build && cd build"
    echo "  cmake .. -DUMR_ENABLE_GUI=ON && make -j$(nproc) && sudo make install"
    exit 1
fi
echo "  ✅ UMR installed."

# ------------------------------------------------------------------
# 3. Radeon GPU Detective – build in /tmp
# ------------------------------------------------------------------
echo "[3] Installing Radeon GPU Detective..."

if [ -d /tmp/radeon_gpu_detective ]; then
    rm -rf /tmp/radeon_gpu_detective
fi
git clone --recursive https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/radeon_gpu_detective
cd /tmp/radeon_gpu_detective || { echo "ERROR: Failed to enter RGD directory"; exit 1; }
mkdir build && cd build || { echo "ERROR: Failed to create build directory"; exit 1; }
cmake .. || { echo "ERROR: RGD CMake configuration failed."; exit 1; }
make -j$(nproc) || { echo "ERROR: RGD build failed."; exit 1; }
sudo make install || { echo "ERROR: RGD installation failed."; exit 1; }
echo "  ✅ RGD installed."

# ------------------------------------------------------------------
# 4. ROCm Validation Suite – build in /tmp (if rocblas present)
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
