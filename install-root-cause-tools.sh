#!/bin/bash
# install-root-cause-tools.sh – Complete, full-featured installer.
# Builds UMR with GUI, all dependencies installed.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Full Features)"
echo "═══════════════════════════════════════════════════════════"

# ------------------------------------------------------------------
# Pre-flight: ROCm repository (optional, but we check)
# ------------------------------------------------------------------
ROCm_REPO_PRESENT=0
if grep -q "repo.radeon.com/rocm" /etc/yum.repos.d/*.repo 2>/dev/null; then
    ROCm_REPO_PRESENT=1
else
    echo "⚠️  ROCm repository not found."
    echo "  RVS (stress testing) requires ROCm libraries."
    echo "  You can add it later; continuing with other tools."
fi

# ------------------------------------------------------------------
# 1. Install all correct Fedora packages (including SDL2-devel for GUI)
# ------------------------------------------------------------------
echo "[1] Installing build dependencies (full set)..."
sudo dnf install -y \
    rocm-smi radeontop nvtop trace-cmd perf \
    git make gcc gcc-c++ cmake python3 sqlite \
    autoconf automake libtool meson ninja-build \
    ncurses-devel zlib-ng-compat-devel libdrm-devel \
    llvm-devel clang mesa-libgbm-devel \
    libglvnd-devel libglvnd-egl pkgconf-pkg-config \
    libpciaccess-devel json-c-devel SDL2-devel

# Optional ROCm packages (skip if unavailable)
sudo dnf install -y --skip-unavailable \
    rocm-dkms rocm-dev rocprofiler rocgdb rocprim rocblas rocblas-devel rocrand

# ------------------------------------------------------------------
# 2. UMR – build with GUI enabled (default) – we don't override
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register) with GUI..."

if [ -d /tmp/umr ]; then
    rm -rf /tmp/umr
fi

git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /tmp/umr
cd /tmp/umr || { echo "ERROR: Failed to enter /tmp/umr"; exit 1; }

if [ -f CMakeLists.txt ]; then
    echo "  Building UMR with CMake (GUI enabled by default)..."
    mkdir build && cd build || { echo "ERROR: Failed to create build directory"; exit 1; }
    cmake .. || { echo "ERROR: CMake configuration failed."; exit 1; }
    make -j$(nproc) || { echo "ERROR: make failed."; exit 1; }
    sudo make install || { echo "ERROR: sudo make install failed."; exit 1; }
else
    echo "ERROR: No CMakeLists.txt found. Manual fallback:"
    echo "  cd /tmp/umr && mkdir build && cd build"
    echo "  cmake .. && make -j$(nproc) && sudo make install"
    exit 1
fi
echo "  ✅ UMR installed (GUI available)."

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
# 4. ROCm Validation Suite – build if rocblas-devel present
# ------------------------------------------------------------------
echo "[4] Installing ROCm Validation Suite..."

if rpm -q rocblas-devel &>/dev/null; then
    echo "  rocblas-devel found – building RVS."
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
else
    echo "⚠️  rocblas-devel not found. RVS requires it."
    echo "  To install: sudo dnf install rocblas-devel"
    echo "  Skipping RVS."
fi

# ------------------------------------------------------------------
# 5. Install root-cause-checker (from repo root)
# ------------------------------------------------------------------
echo "[5] Installing root-cause-checker..."

# Return to the repo root (we are currently in /tmp/*/build)
REPO_ROOT="${OLDPWD:-$(git rev-parse --show-toplevel 2>/dev/null || echo ~/amdgpu-guardian-embedded-build/base)}"
cd "$REPO_ROOT" || { echo "ERROR: Failed to return to repo root"; exit 1; }

if [ -f ./root-cause-checker ]; then
    sudo cp ./root-cause-checker /usr/local/bin/root-cause-checker
    sudo chmod +x /usr/local/bin/root-cause-checker
    echo "  ✅ root-cause-checker installed."
else
    echo "  ⚠️  root-cause-checker not found in repo root."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ ALL TOOLS INSTALLED SUCCESSFULLY (GUI enabled)"
echo "  Run 'root-cause-checker' to verify."
echo "  Run 'sudo ./guardian-wizard.sh' to run health check."
echo "  To launch UMR GUI: sudo umr --gui"
echo "═══════════════════════════════════════════════════════════"
exit 0
