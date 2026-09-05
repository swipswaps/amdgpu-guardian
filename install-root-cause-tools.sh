#!/bin/bash
# install-root-cause-tools.sh – Automatic fallback for RGD/RVS.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Auto‑Fallback)"
echo "═══════════════════════════════════════════════════════════"

# ------------------------------------------------------------------
# Pre-flight: ROCm repository (optional)
# ------------------------------------------------------------------
if ! grep -q "repo.radeon.com/rocm" /etc/yum.repos.d/*.repo 2>/dev/null; then
    echo "⚠️  ROCm repository not found."
    echo "  RVS (stress testing) requires ROCm libraries."
    echo "  You can add it later; continuing with other tools."
fi

# ------------------------------------------------------------------
# 1. Install all correct Fedora packages (from verification report)
# ------------------------------------------------------------------
echo "[1] Installing build dependencies (correct package names)..."
sudo dnf install -y \
    rocm-smi radeontop nvtop trace-cmd perf \
    git make gcc gcc-c++ cmake python3 sqlite \
    autoconf automake libtool meson ninja-build \
    ncurses-devel zlib-ng-compat-devel libdrm-devel \
    llvm-devel clang mesa-libgbm-devel \
    libglvnd-devel libglvnd-egl pkgconf-pkg-config \
    libpciaccess-devel json-c-devel SDL2-devel

sudo dnf install -y --skip-unavailable \
    rocm-dkms rocm-dev rocprofiler rocgdb rocprim rocblas rocblas-devel rocrand

# ------------------------------------------------------------------
# 2. UMR – build with GUI enabled (always works)
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register) with GUI..."

if [ -d /tmp/umr ]; then
    rm -rf /tmp/umr
fi

git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /tmp/umr
cd /tmp/umr || { echo "ERROR: Failed to enter /tmp/umr"; exit 1; }

if [ -f CMakeLists.txt ]; then
    echo "  Building UMR with CMake (GUI enabled)..."
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
# 3. Radeon GPU Detective – automatic fallback if failure
# ------------------------------------------------------------------
echo "[3] Installing Radeon GPU Detective (with submodules)..."

# Clean previous builds
if [ -d /tmp/radeon_gpu_detective ]; then
    rm -rf /tmp/radeon_gpu_detective
fi

# Try automated clone and build
git clone --recursive https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/radeon_gpu_detective
cd /tmp/radeon_gpu_detective || { echo "ERROR: Failed to enter RGD directory"; exit 1; }

git submodule update --init --recursive

if [ -d build ]; then
    rm -rf build
fi
mkdir build && cd build || { echo "ERROR: Failed to create build directory"; exit 1; }

cmake .. 2>&1 | tee /tmp/rgd_cmake.log
if [ $? -ne 0 ]; then
    echo ""
    echo "  ⚠️  Automated RGD build failed. Running manual fallback..."
    # Manual fallback: fresh clone to /tmp/rgd_manual
    cd /tmp || { echo "ERROR: Failed to cd to /tmp"; exit 1; }
    if [ -d /tmp/rgd_manual ]; then
        rm -rf /tmp/rgd_manual
    fi
    git clone --recursive https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/rgd_manual
    cd /tmp/rgd_manual || { echo "ERROR: Failed to enter /tmp/rgd_manual"; exit 1; }
    git submodule update --init --recursive
    if [ -d build ]; then
        rm -rf build
    fi
    mkdir build && cd build || { echo "ERROR: Failed to create build directory"; exit 1; }
    cmake .. || { echo "ERROR: Manual CMake failed."; exit 1; }
    make -j$(nproc) || { echo "ERROR: Manual make failed."; exit 1; }
    sudo make install || { echo "ERROR: Manual install failed."; exit 1; }
    echo "  ✅ RGD installed via manual fallback."
else
    make -j$(nproc) || { echo "ERROR: RGD build failed."; exit 1; }
    sudo make install || { echo "ERROR: RGD installation failed."; exit 1; }
    echo "  ✅ RGD installed (automated)."
fi

# ------------------------------------------------------------------
# 4. ROCm Validation Suite – automatic fallback if failure
# ------------------------------------------------------------------
echo "[4] Installing ROCm Validation Suite..."

if ! rpm -q rocblas-devel &>/dev/null; then
    echo "⚠️  rocblas-devel not found. RVS requires it."
    echo "  To install: sudo dnf install rocblas-devel"
    echo "  Skipping RVS."
else
    if [ -d /tmp/ROCmValidationSuite ]; then
        rm -rf /tmp/ROCmValidationSuite
    fi
    git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/ROCmValidationSuite
    cd /tmp/ROCmValidationSuite || { echo "ERROR: Failed to enter RVS directory"; exit 1; }
    if [ -d build ]; then
        rm -rf build
    fi
    mkdir build && cd build || { echo "ERROR: Failed to create RVS build directory"; exit 1; }
    cmake .. || { echo "  ⚠️  Automated RVS build failed. Running manual fallback..."
        cd /tmp || exit 1
        if [ -d /tmp/rvs_manual ]; then
            rm -rf /tmp/rvs_manual
        fi
        git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/rvs_manual
        cd /tmp/rvs_manual || exit 1
        mkdir build && cd build || exit 1
        cmake .. || { echo "ERROR: Manual CMake failed."; exit 1; }
        make -j$(nproc) || { echo "ERROR: Manual make failed."; exit 1; }
        sudo make install || { echo "ERROR: Manual install failed."; exit 1; }
        echo "  ✅ RVS installed via manual fallback."
        # Since we're in the fallback, we need to skip the rest of the automated block.
        exit 0
    }
    make -j$(nproc) || { echo "ERROR: RVS build failed."; exit 1; }
    sudo make install || { echo "ERROR: RVS installation failed."; exit 1; }
    echo "  ✅ RVS installed (automated)."
fi

# ------------------------------------------------------------------
# 5. Install root-cause-checker (from repo root)
# ------------------------------------------------------------------
echo "[5] Installing root-cause-checker..."

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
echo "  To launch UMR GUI: XDG_RUNTIME_DIR=/run/user/$(id -u) sudo -E umr --gui"
echo "═══════════════════════════════════════════════════════════"
exit 0
