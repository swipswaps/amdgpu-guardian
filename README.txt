═══════════════════════════════════════════════════════════
  AMDGPU Guardian – Complete Diagnostic Framework
═══════════════════════════════════════════════════════════

This project grew out of a real‑world debugging session on a
ThinkPad with AMD Renoir (Ryzen 4000 APU). It provides a
self‑contained health check, forensic toolkit, and remediation
framework for AMD Radeon GPUs on Fedora Linux.

───────────────────────────────────────────────────────────────
  THE JOURNEY (How We Got Here)
───────────────────────────────────────────────────────────────

1. THE ORIGINAL PROBLEM
   • CPU spike (170%) on Firefox due to PSR race condition.
   • Symptom: amdgpu: flip_done timed out
   • Workaround: amdgpu.dcdebugmask=0x10 (disabled PSR)

2. THE REAL FIX
   • Kernel 7.1.8 contains upstream patch set (Leo Li et al.).
   • Moved vblank handling to vupdate_no_lock interrupt.
   • Workaround removed; PSR re‑enabled.

3. FORENSIC TOOLING
   • Built amdgpu-guardian with embedded psr.py, telemetry (rocm-smi),
     and SQLite persistence.
   • Added UMR (register debugger), RGD (post‑mortem), RVS (stress testing).

4. AUDIT & POLISHING
   • 10 defects identified and fixed (README, .gitignore, shebang, etc.).
   • Database migrated to XDG Base Directory (~/.local/share/amdgpu-guardian/).
   • Correct ownership handling with $SUDO_USER.
   • All scripts idempotent, no set -e, no sed, full error visibility.

5. INTEGRATION
   • Forensic tools now detected by guardian-wizard.sh.
   • Specific forensic commands provided on critical errors.

───────────────────────────────────────────────────────────────
  WHERE WE ARE NOW (Current State)
───────────────────────────────────────────────────────────────

┌───────────────────────────┬─────────────────────────────────────┐
│ Kernel                    │ 7.1.8-100.fc43.x86_64 (fix present) │
│ Debugmask                 │ Not active (default state)          │
│ PSR hardware              │ Unsupported (no power loss)         │
│ flip_done timeouts        │ Zero                                │
│ Firmware warnings         │ Zero                                │
│ Telemetry                 │ Functional (rocm-smi)               │
│ SQLite database           │ ~/.local/share/amdgpu-guardian/     │
│                           │ amdgpu-guardian.db                 │
│ Forensic tools            │ UMR, RGD, RVS (install separately) │
│ Repository                │ Audited, fixed, pushed to GitHub    │
└───────────────────────────┴─────────────────────────────────────┘

───────────────────────────────────────────────────────────────
  BEST PRACTICES APPLIED
───────────────────────────────────────────────────────────────

  • XDG Base Directory Specification (data in $XDG_DATA_HOME)
  • Respect $XDG_DATA_HOME if set
  • Detect original user with $SUDO_USER
  • Correct ownership with install -d -o
  • Error handling without set -e (explicit checks)
  • Avoid sed; use awk for portability
  • Idempotent scripts

───────────────────────────────────────────────────────────────
  THE FORENSIC TOOLKIT
───────────────────────────────────────────────────────────────

┌──────────┬────────────────────────────────────┬─────────────────────────────┐
│ Tool     │ Purpose                            │ Invocation                  │
├──────────┼────────────────────────────────────┼─────────────────────────────┤
│ UMR      │ GPU register/ring dump             │ sudo umr -R ring_0          │
│ RGD      │ Post‑mortem crash analysis         │ rgd --input crash.rgd       │
│ RVS      │ Stress testing & validation        │ ./rvs -t basic              │
│ ROCgdb   │ Source‑level debugging             │ rocgdb ./my_app             │
│ DebugFS  │ Kernel ring buffer state           │ cat /sys/.../amdgpu_ring_*  │
└──────────┴────────────────────────────────────┴─────────────────────────────┘

To install all forensic tools:
  ./install-root-cause-tools.sh

To verify installation:
  ./root-cause-checker

───────────────────────────────────────────────────────────────
  YOUR NEXT STEPS (Actionable)
───────────────────────────────────────────────────────────────

1. Install the forensic tools:
     ./install-root-cause-tools.sh

2. Run the health check:
     sudo ./guardian-wizard.sh

3. Verify the database:
     sqlite3 ~/.local/share/amdgpu-guardian/amdgpu-guardian.db \
       "SELECT * FROM boots ORDER BY timestamp DESC LIMIT 3;"

4. (Optional) Migrate old databases:
     cat ~/.amdgpu-guardian.db /root/.amdgpu-guardian.db 2>/dev/null | \
       sqlite3 ~/.local/share/amdgpu-guardian/amdgpu-guardian.db

5. (Optional) Add a weekly systemd timer:
     See the online documentation for examples.

───────────────────────────────────────────────────────────────
  REPOSITORY
───────────────────────────────────────────────────────────────

  https://github.com/swipswaps/amdgpu-guardian

───────────────────────────────────────────────────────────────
  REFERENCES
───────────────────────────────────────────────────────────────

  • XDG Base Directory Specification
    https://specifications.freedesktop.org/basedir-spec/

  • Linux kernel – amdgpu module parameters
    https://www.kernel.org/doc/html/latest/gpu/amdgpu/

  • ROCm Documentation – AMD SMI
    https://rocm.docs.amd.com/projects/amdsmi/

  • UMR – User Mode Register Debugger
    https://gitlab.freedesktop.org/tomstdenis/umr

  • Radeon GPU Detective
    https://github.com/GPUOpen-Tools/radeon_gpu_detective

  • ROCm Validation Suite
    https://github.com/ROCm/ROCmValidationSuite

───────────────────────────────────────────────────────────────
  CONCLUSION
───────────────────────────────────────────────────────────────

You are now in "maintenance and monitoring" mode.
The system is stable, fully instrumented, and documented.
Enjoy the peace of mind that comes with a complete platform.
