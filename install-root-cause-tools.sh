#!/bin/bash
# install-root-cause-tools.sh – Official RGD pre_build.py process.

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Definitive)"
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
# 1. Install all available packages (correct names)
# ------------------------------------------------------------------
echo "[1] Installing build dependencies..."

# Base packages (all available on Fedora 43)
sudo dnf install -y \
    rocm-smi radeontop nvtop trace-cmd perf \
    git make gcc gcc-c++ cmake python3 sqlite \
    autoconf automake libtool meson ninja-build \
    ncurses-devel zlib-ng-compat-devel libdrm-devel \
    llvm-devel clang mesa-libgbm-devel \
    libglvnd-devel libglvnd-egl pkgconf-pkg-config \
    libpciaccess-devel json-c-devel

# Install sdl2-compat-devel (provides SDL2 for UMR GUI)
sudo dnf install -y sdl2-compat-devel

# Optional ROCm packages (skip if unavailable)
sudo dnf install -y --skip-unavailable \
    rocm-dkms rocm-dev rocprofiler rocgdb rocprim rocblas rocblas-devel rocrand

# ------------------------------------------------------------------
# 2. UMR – build with GUI (SDL2 now available)
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register) with GUI..."

if [ -d /tmp/umr ]; then
    rm -rf /tmp/umr
fi
git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /tmp/umr
cd /tmp/umr || exit 1

if [ -f CMakeLists.txt ]; then
    mkdir build && cd build || exit 1
    cmake .. || exit 1
    make -j$(nproc) || exit 1
    sudo make install || exit 1
else
    echo "ERROR: No CMakeLists.txt found."
    exit 1
fi
echo "  ✅ UMR installed (GUI enabled)."

# ------------------------------------------------------------------
# 3. Radeon GPU Detective – official pre_build.py process
# ------------------------------------------------------------------
echo "[3] Installing Radeon GPU Detective (official build)..."

RGD_DIR="/tmp/radeon_gpu_detective"
if [ -d "$RGD_DIR" ]; then
    rm -rf "$RGD_DIR"
fi

# Clone the main repo
git clone https://github.com/GPUOpen-Tools/radeon_gpu_detective.git "$RGD_DIR"
cd "$RGD_DIR" || exit 1

# Run the official pre_build.py script (fetches all dependencies)
cd build || exit 1
echo "  Running pre_build.py to fetch dependencies..."
python3 pre_build.py || { echo "ERROR: pre_build.py failed."; exit 1; }

# Now build with CMake
cd .. || exit 1
if [ -d build ]; then
    rm -rf build
fi
mkdir build && cd build || exit 1
cmake .. || { echo "ERROR: RGD CMake configuration failed."; exit 1; }
make -j$(nproc) || { echo "ERROR: RGD build failed."; exit 1; }
sudo make install || { echo "ERROR: RGD installation failed."; exit 1; }
echo "  ✅ RGD installed."

# ------------------------------------------------------------------
# 4. ROCm Validation Suite – if rocblas-devel present
# ------------------------------------------------------------------
echo "[4] Installing ROCm Validation Suite..."

if rpm -q rocblas-devel &>/dev/null; then
    if [ -d /tmp/ROCmValidationSuite ]; then
        rm -rf /tmp/ROCmValidationSuite
    fi
    git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/ROCmValidationSuite
    cd /tmp/ROCmValidationSuite || exit 1
    if [ -d build ]; then
        rm -rf build
    fi
    mkdir build && cd build || exit 1
    cmake .. || { echo "ERROR: RVS CMake failed."; exit 1; }
    make -j$(nproc) || { echo "ERROR: RVS build failed."; exit 1; }
    sudo make install || { echo "ERROR: RVS installation failed."; exit 1; }
    echo "  ✅ RVS installed."
else
    echo "⚠️  rocblas-devel not found – skipping RVS."
fi

# ------------------------------------------------------------------
# 5. Install root-cause-checker (from repo root)
# ------------------------------------------------------------------
echo "[5] Installing root-cause-checker..."

# Use git to find repo root, fallback to pwd
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [ -f "$REPO_ROOT/root-cause-checker" ]; then
    sudo cp "$REPO_ROOT/root-cause-checker" /usr/local/bin/root-cause-checker
    sudo chmod +x /usr/local/bin/root-cause-checker
    echo "  ✅ root-cause-checker installed."
else
    echo "  ⚠️  root-cause-checker not found in repo root."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ ALL TOOLS INSTALLED SUCCESSFULLY"
echo "  Run 'root-cause-checker' to verify."
echo "  Run 'sudo ./guardian-wizard.sh' to run health check."
echo "  To launch UMR GUI: XDG_RUNTIME_DIR=/run/user/$(id -u) sudo -E umr --gui"
echo "═══════════════════════════════════════════════════════════"
exit 0
