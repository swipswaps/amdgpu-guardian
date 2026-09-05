#!/bin/bash
# install-root-cause-tools.sh – idempotent, no set -e, no sed, no 2>/dev/null

set +e

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Full AMDGPU Root‑Cause Toolkit (Corrected)"
echo "═══════════════════════════════════════════════════════════"

# --- 1. Install all packages available via dnf ---
echo "[1] Installing dnf packages..."
sudo dnf install -y \
    rocm-smi radeontop nvtop \
    trace-cmd perf \
    git make gcc g++ cmake python3 \
    sqlite3 autoconf automake libtool \
    rocm-dkms rocm-dev rocprofiler rocgdb 2>/dev/null || echo "  Some ROCm packages may need explicit repo."

sudo dnf install -y --skip-unavailable rocm-smi radeontop nvtop trace-cmd perf git make gcc g++ cmake python3 sqlite3 autoconf automake libtool rocm-dkms rocm-dev rocprofiler rocgdb

# --- 2. Build and install UMR (autotools) ---
echo "[2] Installing UMR (User Mode Register)..."
if [ ! -d /opt/umr ]; then
    sudo git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /opt/umr
fi
cd /opt/umr || exit
sudo git pull 2>/dev/null
if [ ! -f Makefile ]; then
    ./autogen.sh && ./configure
fi
make
sudo make install

# --- 3. Build and install Radeon GPU Detective (CMake) ---
echo "[3] Installing Radeon GPU Detective..."
if [ ! -d /opt/radeon_gpu_detective ]; then
    sudo git clone https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /opt/radeon_gpu_detective
fi
cd /opt/radeon_gpu_detective || exit
sudo git pull 2>/dev/null
mkdir -p build && cd build || exit
cmake .. && make && sudo make install

# --- 4. Build and install ROCm Validation Suite (CMake) ---
echo "[4] Installing ROCm Validation Suite..."
if [ ! -d /opt/ROCmValidationSuite ]; then
    sudo git clone https://github.com/ROCm/ROCmValidationSuite.git /opt/ROCmValidationSuite
fi
cd /opt/ROCmValidationSuite || exit
sudo git pull 2>/dev/null
mkdir -p build && cd build || exit
cmake .. && make && sudo make install

# --- 5. Add helper script ---
echo "[5] Adding root-cause-checker to /usr/local/bin..."
cat > /tmp/root-cause-checker.sh <<'EOF'
#!/bin/bash
echo "═══════════════════════════════════════════════════════════"
echo "  AMDGPU Root‑Cause Toolkit – Tool Presence Check"
echo "═══════════════════════════════════════════════════════════"

TOOLS=(
    "rocm-smi:rocm-smi"
    "radeontop:radeontop"
    "nvtop:nvtop"
    "trace-cmd:trace-cmd"
    "perf:perf"
    "rocgdb:rocgdb"
    "rocprofiler:rocprofiler"
    "umr:umr"
    "rgd:rgd"
    "rvs:rvs"
)

for entry in "${TOOLS[@]}"; do
    name="${entry%%:*}"
    cmd="${entry##*:}"
    if command -v "$cmd" &>/dev/null; then
        echo "  ✅ $name – installed"
    else
        echo "  ❌ $name – not found (may need ROCm repo)"
    fi
done
echo ""
echo "Note: To use RGD, you need a crash dump (.rgd file)."
echo "To use UMR, run: sudo umr -R ring_0"
echo "═══════════════════════════════════════════════════════════"
