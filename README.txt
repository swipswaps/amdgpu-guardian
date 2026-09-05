═══════════════════════════════════════════════════════════
  AMDGPU Guardian – Complete Diagnostic Framework
  DEFINITIVE EDITION – All Tools Fully Installed
═══════════════════════════════════════════════════════════

This project provides a self‑contained health check, forensic toolkit,
and remediation framework for AMD Radeon GPUs on Fedora Linux.

───────────────────────────────────────────────────────────────
  HOW WE GOT HERE (The Complete Journey)
───────────────────────────────────────────────────────────────

1. SYMPTOM DISCOVERY: CPU spike (170%) on Firefox due to PSR race.
2. WORKAROUND: amdgpu.dcdebugmask=0x10 (disabled PSR).
3. ARCHITECTURAL FIX: Upstream kernel 7.1.8 with Leo Li's patch set.
4. FORENSIC TOOLING: Built amdgpu-guardian with psr.py, telemetry, SQLite.
5. AUDIT & POLISHING: 10 defects fixed (README, .gitignore, shebang, etc.).
6. STANDARDS COMPLIANCE: Migrated database to XDG Base Directory.
7. INSTALLER CORRECTIONS: Fixed Meson/CMake builds, submodules, ROCm deps.
8. DEFINITIVE INSTALLATION: All tools built successfully (UMR, RGD, RVS).

───────────────────────────────────────────────────────────────
  WHERE WE ARE NOW (Current State)
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
  YOUR NEXT STEPS (Completed)
───────────────────────────────────────────────────────────────

✅ All tools are installed and verified.
✅ The health check runs without errors.
✅ The database is correctly set up.

If you encounter a future GPU issue, use the wizard first:
  sudo ./guardian-wizard.sh

Then, if deep analysis is needed, use the specific forensic commands.

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
