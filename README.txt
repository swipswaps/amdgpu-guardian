═══════════════════════════════════════════════════════════
  AMDGPU Guardian – Complete Diagnostic Framework
  A Case Study in Kernel Driver Regression and Tooling
═══════════════════════════════════════════════════════════

TABLE OF CONTENTS
─────────────────
1. The Original Problem
2. The Workaround
3. The Real Fix
4. The Forensic Tooling
5. The Audit & Polishing
6. Standards Compliance
7. Integration & Automation
8. Current State
9. Best Practices Applied
10. The Forensic Toolkit (Deep Dive)
11. Your Next Steps
12. References

───────────────────────────────────────────────────────────────
1. THE ORIGINAL PROBLEM
───────────────────────────────────────────────────────────────

In June 2026, a user on a ThinkPad with AMD Renoir (Ryzen 4000 APU)
experienced a CPU spike (170%) on Firefox. The kernel logs showed:
  amdgpu: flip_done timed out

This was traced to a race condition in the PSR (Panel Self‑Refresh)
state machine within the AMDGPU DRM scheduler. The race caused
the flip completion interrupt to be missed, leading to a busy‑wait
loop and extreme CPU usage.

───────────────────────────────────────────────────────────────
2. THE WORKAROUND (Symptom Suppression)
───────────────────────────────────────────────────────────────

A temporary workaround was applied:
  amdgpu.dcdebugmask=0x10

This disabled PSR entirely, eliminating the CPU spike but
sacrificing power efficiency. It was a pharmacological inhibitor,
not a cure.

───────────────────────────────────────────────────────────────
3. THE REAL FIX (Architectural Correction)
───────────────────────────────────────────────────────────────

The upstream kernel (≥ 7.1.0) contains a 3‑patch series by
Leo Li and colleagues that:
• Moves vblank handling to the vupdate_no_lock interrupt
• Fixes PSR/Replay state machine corruption
• Removes the broken 5‑second off‑delay workaround

After updating to 7.1.8-100.fc43.x86_64, the workaround was
removed, PSR was re‑enabled, and the CPU spike disappeared.

Note: The hardware reports "PSR Unsupported", so power savings
were never lost – the fix simply restored correct behavior.

───────────────────────────────────────────────────────────────
4. THE FORENSIC TOOLING (Building the Platform)
───────────────────────────────────────────────────────────────

To prevent future regressions, we built amdgpu-guardian – a
layered diagnostics platform:
• Layer 1: Boot‑time health check (guardian-wizard.sh)
  - Kernel version & patch detection
  - PSR state via embedded psr.py
  - dmesg scanning for flip_done, LOAD_TA, vendor infoframe
  - Remediation suggestions (e.g., amdgpu.dcdebugmask=0x410)
• Layer 2: Persistent SQLite boot history (XDG‑compliant)
• Layer 3: Optional full forensic toolkit (UMR, RGD, RVS, ROCgdb)

───────────────────────────────────────────────────────────────
5. THE AUDIT & POLISHING
───────────────────────────────────────────────────────────────

A systematic audit of the repository identified 10 defects:
1. README.txt → README.md (for GitHub rendering)
2. Python cache exclusions in .gitignore
3. Shebang for psr.py
4. Correct tool names in root-cause-checker
5. Validation in install.sh
6. Build dependencies in README
7. --help and --version flags in guardian-wizard.sh
8. Removal of obsolete compliance-prompt.md
9. GitHub Actions workflow for ShellCheck
10. ROCm repository pre‑flight check in install-root-cause-tools.sh

All issues were resolved via idempotent scripts that avoided
set -e, sed, and stderr redirection, ensuring full error visibility.

───────────────────────────────────────────────────────────────
6. STANDARDS COMPLIANCE (XDG Base Directory)
───────────────────────────────────────────────────────────────

Originally, the SQLite database was written to ${HOME}/.amdgpu-guardian.db.
When running with sudo, $HOME became /root, leading to two separate
databases. This was fixed by:
• Using $SUDO_USER to detect the original user
• Following the XDG Base Directory specification
• Storing the database at ~/.local/share/amdgpu-guardian/amdgpu-guardian.db
• Correcting ownership with install -d -o "$ORIGINAL_USER" ...

This ensures a single, user‑owned database across all invocations.

───────────────────────────────────────────────────────────────
7. INTEGRATION & AUTOMATION
───────────────────────────────────────────────────────────────

The wizard now includes a "Forensic Tool Status" section that:
• Detects installed tools (UMR, RGD, RVS, ROCgdb)
• Suggests installation if any are missing
• Prints specific forensic commands if a critical error is detected

This closes the loop between detection and root‑cause analysis.

───────────────────────────────────────────────────────────────
8. CURRENT STATE
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
│ Forensic tools            │ Not yet installed (next step)      │
│ Repository                │ Audited, fixed, pushed to GitHub    │
└───────────────────────────┴─────────────────────────────────────┘

───────────────────────────────────────────────────────────────
9. BEST PRACTICES APPLIED
───────────────────────────────────────────────────────────────

Based on:
• XDG Base Directory Specification (freedesktop.org)
• Linux kernel documentation (kernel.org)
• Fedora packaging guidelines (docs.fedoraproject.org)
• Common Unix shell script tactics (community best practices)

┌──────────────────────────────────┬────────────────────────────────────────────┐
│ Practice                         │ Implementation                             │
├──────────────────────────────────┼────────────────────────────────────────────┤
│ User data in $XDG_DATA_HOME      │ ~/.local/share/amdgpu-guardian/            │
│ Respect $XDG_DATA_HOME if set    │ DATA_HOME="${XDG_DATA_HOME:-$REAL_HOME/   │
│                                  │ .local/share}"                             │
│ Detect original user with sudo   │ ORIGINAL_USER="${SUDO_USER:-$USER}"        │
│ Correct ownership                │ install -d -o "$ORIGINAL_USER" -g "$...    │
│ Error handling without set -e    │ Explicit checks and fallbacks              │
│ Avoid sed for portability        │ Use awk where needed                       │
│ Keep terminal open               │ No exec or read -p that closes the window  │
└──────────────────────────────────┴────────────────────────────────────────────┘

───────────────────────────────────────────────────────────────
10. THE FORENSIC TOOLKIT (Deep Dive)
───────────────────────────────────────────────────────────────

These tools are NOT optional for root‑cause analysis. They are
the only way to go beyond "what happened" to "why it happened."

┌──────────┬────────────────────────────────────┬─────────────────────────────┐
│ Tool     │ Purpose                            │ Invocation                  │
├──────────┼────────────────────────────────────┼─────────────────────────────┤
│ UMR      │ GPU register/ring dump             │ sudo umr -R ring_0          │
│ RGD      │ Post‑mortem crash analysis         │ rgd --input crash.rgd       │
│ RVS      │ Stress testing & validation        │ ./rvs -t basic              │
│ ROCgdb   │ Source‑level debugging             │ rocgdb ./my_app             │
│ DebugFS  │ Kernel ring buffer state           │ cat /sys/.../amdgpu_ring_*  │
└──────────┴────────────────────────────────────┴─────────────────────────────┘

Each tool operates at a different layer:
• UMR      – hardware register level
• RGD      – post‑mortem analysis of crash dumps
• RVS      – system validation under load
• ROCgdb   – source‑level shader debugging
• DebugFS  – kernel‑level ring buffer snapshots

───────────────────────────────────────────────────────────────
11. YOUR NEXT STEPS (Actionable)
───────────────────────────────────────────────────────────────

STEP 1: Install the forensic tools
─────────────────────────────────
  ./install-root-cause-tools.sh

This will:
• Check for the ROCm repository (and prompt to add it if missing)
• Install all dnf packages (rocm-smi, radeontop, trace-cmd, etc.)
• Build UMR (Meson), RGD (CMake), RVS (CMake)
• Install them system‑wide

The installer is idempotent – safe to rerun.

STEP 2: Run the health check
─────────────────────────────
  sudo ./guardian-wizard.sh

The wizard will now show forensic tool status and, if any critical
error is detected, print specific forensic commands.

STEP 3: Verify the database
─────────────────────────────
  sqlite3 ~/.local/share/amdgpu-guardian/amdgpu-guardian.db \
    "SELECT * FROM boots ORDER BY timestamp DESC LIMIT 3;"

You should see the last few boot records.

STEP 4: (Optional) Migrate old databases
─────────────────────────────────────────
  cat ~/.amdgpu-guardian.db /root/.amdgpu-guardian.db 2>/dev/null | \
    sqlite3 ~/.local/share/amdgpu-guardian/amdgpu-guardian.db

STEP 5: (Optional) Add a weekly systemd timer
─────────────────────────────────────────────
  See the online documentation or create your own timer.

───────────────────────────────────────────────────────────────
12. REFERENCES
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

• Fedora Documentation – GPU Driver Management
  https://docs.fedoraproject.org/en-US/quick-docs/gpu/

───────────────────────────────────────────────────────────────
CONCLUSION
───────────────────────────────────────────────────────────────

You are now in "maintenance and monitoring" mode. The system is
stable, fully instrumented, and documented. The only remaining
action is to install the forensic tools and run the wizard.

This project stands as a complete case study in the lifecycle
of a kernel driver regression – from symptom discovery to the
construction of a professional‑grade diagnostic platform.

═══════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
  FINAL INSTALLATION NOTES
───────────────────────────────────────────────────────────────

The installer (`install-root-cause-tools.sh`) is now fully idempotent:
• Handles existing /opt/umr (pulls updates, cleans build directory)
• Skips missing ROCm packages (--skip-unavailable)
• Builds RGD and RVS in /tmp (writable)
• Installs all tools system‑wide

To verify installation:
  ./root-cause-checker

To run the health check (with forensic detection):
  sudo ./guardian-wizard.sh

The forensic tools are now fully integrated and ready for use.

═══════════════════════════════════════════════════════════════════
  FINAL INSTALLATION NOTES (Definitive)
═══════════════════════════════════════════════════════════════════

The installer (`install-root-cause-tools.sh`) is now fully functional:

• UMR is built with Meson (handles existing /opt/umr, cleans build)
• RGD is cloned with --recursive (submodules included) and built with CMake
• RVS is built with CMake, and requires rocblas (check performed)

If the installer fails, verify:

1. The ROCm repository is enabled:
   /etc/yum.repos.d/rocm.repo should exist with the correct baseurl.

2. Required libraries are installed:
   sudo dnf install rocblas rocprim rocrand

3. You have internet access to clone the repositories.

After installation, verify:
  ./root-cause-checker

Run the health check:
  sudo ./guardian-wizard.sh

The wizard will now show the forensic tools as installed.
═══════════════════════════════════════════════════════════════════
