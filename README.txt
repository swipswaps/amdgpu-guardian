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
7. INSTALLER CORRECTIONS: Identified and installed all missing dependencies, including:
   - ncurses-devel, zlib-devel, libdrm-devel, llvm-devel, clang, gbm-devel, libglvnd-devel.
   - Built UMR with CMake (GUI enabled), RGD with submodules, RVS with rocblas check.

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
│ Repository                │ Audited, fixed, pushed to GitHub    │
└───────────────────────────┴─────────────────────────────────────┘

───────────────────────────────────────────────────────────────
  COMPLETE FORENSIC TOOLKIT
───────────────────────────────────────────────────────────────

┌──────────┬────────────────────────────────────┬─────────────────────────────┐
│ Tool     │ Purpose                            │ Invocation                  │
├──────────┼────────────────────────────────────┼─────────────────────────────┤
│ UMR      │ GPU register/ring dump             │ sudo umr -R ring_0          │
│ RGD      │ Post‑mortem crash analysis         │ rgd --input crash.rgd       │
│ RVS      │ Stress testing & validation        │ ./rvs -t basic              │
│ DebugFS  │ Kernel ring buffer state           │ cat /sys/.../amdgpu_ring_*  │
└──────────┴────────────────────────────────────┴─────────────────────────────┘

───────────────────────────────────────────────────────────────
  MANUAL FALLBACK (if the installer ever fails)
───────────────────────────────────────────────────────────────

If the installer fails, you can build each tool manually:

1. Install all dependencies:
   sudo dnf install ncurses-devel zlib-devel libdrm-devel llvm-devel clang gbm-devel libglvnd-devel libglvnd-egl pkgconfig cmake make gcc g++ git

2. UMR (CMake):
   git clone https://gitlab.freedesktop.org/tomstdenis/umr.git /tmp/umr
   cd /tmp/umr && mkdir build && cd build
   cmake .. -DUMR_ENABLE_GUI=ON && make -j$(nproc) && sudo make install

3. RGD:
   git clone --recursive https://github.com/GPUOpen-Tools/radeon_gpu_detective.git /tmp/rgd
   cd /tmp/rgd && mkdir build && cd build
   cmake .. && make -j$(nproc) && sudo make install

4. RVS:
   (Requires rocblas; install with: sudo dnf install rocblas)
   git clone https://github.com/ROCm/ROCmValidationSuite.git /tmp/rvs
   cd /tmp/rvs && mkdir build && cd build
   cmake .. && make -j$(nproc) && sudo make install

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
