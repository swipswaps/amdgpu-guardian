#!/bin/bash
# install-root-cause-tools.sh – Corrected installer for UMR, RGD, RVS
# Uses Meson for UMR, CMake for RGD/RVS. Idempotent. Run with sudo.

set -e  # only for this script

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Corrected)"
echo "═══════════════════════════════════════════════════════════"

# ------------------------------------------------------------------
# 1. Install dnf packages (ROCM repo required for some)
# ------------------------------------------------------------------
echo "[1] Installing dnf packages..."
sudo dnf install -y rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool meson ninja-build
# Some may not be available; skip errors
sudo dnf install -y --skip-unavailable rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool meson ninja-build

# ------------------------------------------------------------------
# 2. UMR – Meson build (correct)
# ------------------------------------------------------------------
echo "[2] Installing UMR (User Mode Register)..."

if [ ! -d /opt/umr ]; then
    sudo git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /opt/umr
fi
cd /opt/umr || exit
sudo git pull --rebase 2>/dev/null

# Build with Meson
if [ ! -d build ]; then
    sudo meson setup build
fi
sudo ninja -C build
sudo ninja -C build install

# ------------------------------------------------------------------
# 3. Radeon GPU Detective (RGD) – CMake build in /tmp
# ------------------------------------------------------------------
echo "[3] Installing Radeon GPU Detective..."

# Clone to /tmp (writable)
if [ ! -d /tmp/radeon_gpu_detective ]; then
    git clone https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/radeon_gpu_detective
fi
cd /tmp/radeon_gpu_detective || exit
git pull --rebase 2>/dev/null

# Build in /tmp/build
if [ -d build ]; then
    rm -rf build
fi
mkdir build && cd build || exit
cmake ..
make -j$(nproc)
sudo make install

# ------------------------------------------------------------------
# 4. ROCm Validation Suite (RVS) – CMake build in /tmp
# ------------------------------------------------------------------
echo "[4] Installing ROCm Validation Suite..."

if [ ! -d /tmp/ROCmValidationSuite ]; then
    git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/ROCmValidationSuite
fi
cd /tmp/ROCmValidationSuite || exit
git pull --rebase 2>/dev/null

if [ -d build ]; then
    rm -rf build
fi
mkdir build && cd build || exit
cmake ..
make -j$(nproc)
sudo make install

# ------------------------------------------------------------------
# 5. Copy root-cause-checker to /usr/local/bin (if present)
# ------------------------------------------------------------------
if [ -f ./root-cause-checker ]; then
    sudo cp ./root-cause-checker /usr/local/bin/root-cause-checker
    sudo chmod +x /usr/local/bin/root-cause-checker
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Installation complete."
echo "  Run 'root-cause-checker' to verify."
echo "═══════════════════════════════════════════════════════════"
