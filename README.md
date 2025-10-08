# WinOpsToolkit

A portable toolkit for automating Windows workstation/server setup with PowerShell 5.1 or 7+, using declarative tasks (YAML/JSON) and idempotent modules.

## Quick Start

1. **Run as Admin**: Right-click PowerShell (5.1 is fine) → Run as Administrator.
2. Execute:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\bootstrap\Start-WinOps.ps1 -Task standard_build -Profile site-plano,workstation
   ```
3. The bootstrap will:
   - Try to use **PowerShell 7** (`pwsh`) if available (and relaunch itself).
   - If not installed and **winget** is present, it will offer to install `Microsoft.PowerShell` and re-run.
   - Otherwise it continues with **Windows PowerShell 5.1**.
4. Logs go to `logs\transcript` (PS transcript) and `logs\events.jsonl`. A summary HTML is saved in `logs\reports`.

## Structure

See `modules/` for exported functions and `tasks/` + `config/` for declarative recipes. JSON mirrors of YAML are provided for PS 5.1 environments without `ConvertFrom-Yaml`.

## Notes

- The sample task uses `WinOps.Files/Layout::Ensure-StandardFolders`, `WinOps.System/Registry::Set-RegistryValues`, and `WinOps.Apps/Winget::Install-Apps`.
- Replace sample app IDs and registry keys with your real standards.

## Project Roadmap

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the detailed delivery plan covering discovery, CLI hardening, shared abstractions, GUI work, and testing/packaging milestones.
