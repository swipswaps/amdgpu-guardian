═══════════════════════════════════════════════════════════
  AMDGPU Guardian – Complete Diagnostic Framework
  DEFINITIVE STATE – All Tools Successfully Installed
═══════════════════════════════════════════════════════════

This project provides a self‑contained health check, forensic toolkit,
and remediation framework for AMD Radeon GPUs on Fedora Linux.

───────────────────────────────────────────────────────────────
  HOW WE GOT HERE (Complete Journey)
───────────────────────────────────────────────────────────────

1. SYMPTOM DISCOVERY: CPU spike due to PSR race.
2. WORKAROUND: amdgpu.dcdebugmask=0x10.
3. ARCHITECTURAL FIX: Upstream kernel 7.1.8.
4. FORENSIC TOOLING: Built amdgpu-guardian.
5. AUDIT & POLISHING: 10 defects fixed.
6. STANDARDS COMPLIANCE: XDG Base Directory.
7. INSTALLER CORRECTIONS: UMR build with make, RGD with submodules, RVS with rocblas check.

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
