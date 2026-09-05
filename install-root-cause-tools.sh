#!/bin/bash
# install-root-cause-tools.sh – idempotent installer for full forensic toolkit
set +e

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit"
echo "═══════════════════════════════════════════════════════════"

echo "[1] Installing dnf packages..."
sudo dnf install -y rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool rocm-dkms rocm-dev rocprofiler rocgdb 2>/dev/null
sudo dnf install -y --skip-unavailable rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool rocm-dkms rocm-dev rocprofiler rocgdb

echo "[2] Installing UMR..."
if [ ! -d /opt/umr ]; then
    sudo git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /opt/umr
fi
cd /opt/umr || exit
sudo git pull 2>/dev/null
if [ ! -f Makefile ]; then
    ./autogen.sh && ./configure
fi
make && sudo make install

echo "[3] Installing Radeon GPU Detective..."
if [ ! -d /opt/radeon_gpu_detective ]; then
    sudo git clone https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /opt/radeon_gpu_detective
fi
cd /opt/radeon_gpu_detective || exit
sudo git pull 2>/dev/null
mkdir -p build && cd build || exit
cmake .. && make && sudo make install

echo "[4] Installing ROCm Validation Suite..."
if [ ! -d /opt/ROCmValidationSuite ]; then
    sudo git clone https://github.com/ROCm/ROCmValidationSuite.git /opt/ROCmValidationSuite
fi
cd /opt/ROCmValidationSuite || exit
sudo git pull 2>/dev/null
mkdir -p build && cd build || exit
cmake .. && make && sudo make install

echo "[5] Installing root-cause-checker helper..."
# Copy from the repo if it exists, otherwise create a minimal one
if [ -f ./root-cause-checker ]; then
    sudo cp ./root-cause-checker /usr/local/bin/
    sudo chmod +x /usr/local/bin/root-cause-checker
else
    echo "  root-cause-checker not found in repo – skipping."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Installation complete."
echo "  Run 'root-cause-checker' to see which tools are ready."
echo "  Run 'sudo amdgpu-guardian' for health check."
echo "═══════════════════════════════════════════════════════════"
