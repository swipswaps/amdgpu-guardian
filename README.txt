AMDGPU Guardian – Embedded Tools Edition

This repository contains a complete AMDGPU diagnostic framework with all tools embedded (no runtime cloning).

Included:
- psr.py – PSR detection from amd-debug-tools (embedded)
- Guardian wizard – health checks, telemetry, and remediation
- SQLite persistence – boot history

Prerequisites:
- Python 3
- dmesg access (run with sudo)
- Optional: rocm-smi or amd-smi for telemetry

Quick Start:
  sudo ./guardian-wizard.sh
