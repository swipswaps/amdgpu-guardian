AMDGPU Guardian – Unified Diagnostic & Remediation Framework for AMD GPUs on Fedora

This repository provides a self‑contained health check and forensic toolkit for AMD Radeon GPUs, with built‑in PSR detection, kernel patch verification, SQLite boot history, and optional integration with full root‑cause analysis tools.

Key Features
------------
- Kernel version detection – automatically identifies whether the upstream PSR/flip_done fix is present.
- PSR state detection – uses an embedded copy of amd-debug-tools/psr.py (no runtime cloning).
- Boot‑time diagnostics – scans dmesg for flip_done timeouts, LOAD_TA, and vendor infoframe warnings.
- Remediation suggestions – if a regression is found, recommends the appropriate kernel parameter (e.g., amdgpu.dcdebugmask=0x410).
- SQLite persistence – stores every boot’s health state for longitudinal regression tracking.
- Telemetry – optionally displays temperature, power, and utilization via rocm-smi or radeontop.
- Root‑cause checker – a helper script (root-cause-checker) that lists which forensic tools are installed.

Dependencies (automatically installed by install.sh)
----------------------------------------------------
- git, python3, sqlite3, rocm-smi (optional), radeontop (optional)
- For full root‑cause analysis (optional):
    - trace-cmd, perf, rocgdb, rocprofiler
    - UMR (User Mode Register) – cloned and built from gitlab.freedesktop.org
    - Radeon GPU Detective (RGD) – cloned and built from GitHub
    - ROCm Validation Suite (RVS) – cloned and built from GitHub

Installation
------------
1. Clone the repository:
   git clone https://github.com/swipswaps/amdgpu-guardian
   cd amdgpu-guardian

2. (Optional) Install all dependencies and the wizard system‑wide:
   sudo ./install.sh

   This copies guardian-wizard.sh to /usr/local/bin/amdgpu-guardian.

Usage
-----
Run the health check (requires root to read dmesg):
   sudo ./guardian-wizard.sh
or, if installed:
   sudo amdgpu-guardian

The output will show:
- Kernel version and patch status
- Active debugmask (if any)
- PSR support (using the embedded psr.py)
- flip_done, LOAD_TA, and vendor infoframe errors
- Telemetry (if rocm-smi or radeontop is installed)
- A remediation plan (if any critical issue is found)
- A SQLite record of the boot state

Advanced Forensics
------------------
If the health check flags an issue, use the full toolkit to find the root cause:
1. Live telemetry:
   rocm-smi --showtemp --showpower --showuse
   or
   radeontop

2. Kernel tracing (reproduce the hang):
   sudo trace-cmd record -p function -l amdgpu_* -l drm_*
   sudo trace-cmd report

3. GPU state dump (if a hang occurs):
   sudo umr -R ring_0

4. Post‑mortem crash analysis (if a .rgd dump exists):
   rgd --input crash.rgd --output report.txt

5. Source‑level debugging:
   rocgdb ./my_gpu_app

The helper script root-cause-checker lists all installed tools and their status.

Troubleshooting
---------------
- rocm-smi may crash with --showallinfo on some APUs (e.g., Renoir). Use specific flags like --showtemp, --showpower, --showuse instead.
- If you see "dmesg: read kernel buffer failed", run the wizard with sudo.
- If the wizard reports "No AMD SMI tool found", install rocm-smi or radeontop.

Repository
----------
https://github.com/swipswaps/amdgpu-guardian