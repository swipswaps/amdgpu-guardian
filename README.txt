═══════════════════════════════════════════════════════════
  AMDGPU Guardian – Complete Diagnostic Framework
  FINAL STATE – All Tools Successfully Installed
═══════════════════════════════════════════════════════════

This project provides a self‑contained health check, forensic toolkit,
and remediation framework for AMD Radeon GPUs on Fedora Linux.

───────────────────────────────────────────────────────────────
  THE JOURNEY (How We Got Here)
───────────────────────────────────────────────────────────────

1. SYMPTOM DISCOVERY: CPU spike on Firefox due to PSR race (flip_done timeouts).
2. WORKAROUND: amdgpu.dcdebugmask=0x10 (disabled PSR).
3. ARCHITECTURAL FIX: Upstream kernel 7.1.8 with Leo Li's patch set – PSR fixed.
4. FORENSIC TOOLING: Built amdgpu-guardian with psr.py, telemetry, SQLite.
5. AUDIT & POLISHING: 10 defects fixed (README, .gitignore, shebang, tool names, etc.).
6. STANDARDS COMPLIANCE: Migrated database to XDG Base Directory (user‑owned, consistent).
7. INSTALLER CORRECTIONS: After exhaustive verification:
   - Corrected all package names for Fedora 43.
   - Used sdl2-compat-devel for UMR GUI (SDL2 compatibility).
   - RGD now uses the official pre_build.py script to fetch dependencies.
   - All tools build and install successfully.

───────────────────────────────────────────────────────────────
  CURRENT STATE
───────────────────────────────────────────────────────────────

┌───────────────────────────┬─────────────────────────────────────┐
│ Kernel                    │ 7.1.8-100.fc43.x86_64 (fix present) │
│ Debugmask                 │ None (default state)                │
│ PSR hardware              │ Unsupported (no power loss)         │
│ flip_done timeouts        │ Zero                                │
│ Firmware warnings         │ Zero                                │
│ Telemetry                 │ rocm-smi functional                 │
│ SQLite database           │ ~/.local/share/amdgpu-guardian/     │
│                           │ amdgpu-guardian.db                 │
│ Forensic tools            │ ALL INSTALLED (UMR, RGD, RVS)      │
│ UMR GUI                   │ ✅ ENABLED (sdl2-compat-devel)      │
│ Repository                │ Audited, fixed, pushed to GitHub    │
└───────────────────────────┴─────────────────────────────────────┘

───────────────────────────────────────────────────────────────
  COMPLETE FORENSIC TOOLKIT
───────────────────────────────────────────────────────────────

┌──────────┬────────────────────────────────────┬─────────────────────────────┐
│ Tool     │ Purpose                            │ Invocation                  │
├──────────┼────────────────────────────────────┼─────────────────────────────┤
│ UMR CLI  │ GPU register/ring dump             │ sudo umr -R ring_0          │
│ UMR GUI  │ Graphical register viewer          │ XDG_RUNTIME_DIR=/run/user/$(id -u) sudo -E umr --gui │
│ RGD      │ Post‑mortem crash analysis         │ rgd --input crash.rgd       │
│ RVS      │ Stress testing & validation        │ ./rvs -t basic              │
│ DebugFS  │ Kernel ring buffer state           │ cat /sys/.../amdgpu_ring_*  │
└──────────┴────────────────────────────────────┴─────────────────────────────┘

───────────────────────────────────────────────────────────────
  MANUAL FALLBACK (if the installer ever fails)
───────────────────────────────────────────────────────────────

If the installer fails, you can build each tool manually:

1. Install dependencies:
   sudo dnf install ncurses-devel zlib-ng-compat-devel libdrm-devel llvm-devel clang mesa-libgbm-devel libglvnd-devel libglvnd-egl pkgconf-pkg-config libpciaccess-devel json-c-devel sdl2-compat-devel cmake make gcc gcc-c++ git rocblas-devel

2. UMR:
   git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /tmp/umr
   cd /tmp/umr && mkdir build && cd build
   cmake .. && make -j$(nproc) && sudo make install

3. RGD (official build):
   git clone https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/rgd
   cd /tmp/rgd/build
   python3 pre_build.py
   cd ..
   mkdir build && cd build
   cmake .. && make -j$(nproc) && sudo make install

4. RVS (requires rocblas-devel):
   git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/rvs
   cd /tmp/rvs && mkdir build && cd build
   cmake .. && make -j$(nproc) && sudo make install

After manually building, run ./root-cause-checker to verify.

───────────────────────────────────────────────────────────────
  REFERENCES
───────────────────────────────────────────────────────────────

• XDG Base Directory Specification
• Linux kernel – amdgpu module parameters
• ROCm Documentation – AMD SMI
• UMR – User Mode Register Debugger
• Radeon GPU Detective
• ROCm Validation Suite

═══════════════════════════════════════════════════════════
