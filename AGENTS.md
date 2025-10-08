# Repository Guidelines

## Project Structure & Module Organization
`bootstrap/Start-WinOps.ps1` is the entry point that loads layered configs from `config/` and tasks from `tasks/`. PowerShell modules live in `modules/WinOps.*`, each exporting narrowly scoped functions (files, registry, apps, logging). The GUI launcher sits in `python_gui/app/main.py`, while helper utilities reside in `scripts/` (for example `Collect-Logs.ps1`). Persist idempotency markers under `state/` when you add new modules, and keep documentation updates in `docs/`. Tests belong in `tests/Pester/` using the same folder names as the modules they cover.

## Build, Test, and Development Commands
Run the standard workstation build with:
```powershell
.\bootstrap\Start-WinOps.ps1 -Task standard_build -Profile site-plano,workstation
```
Launch the GUI from an elevated Windows terminal after installing dependencies:
```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1; pip install -r requirements.txt
python .\python_gui\app\main.py
```
Collect diagnostic output befo1re filing issues via `powershell.exe -File .\scripts\Collect-Logs.ps1`.

## Coding Style & Naming Conventions
Use PowerShell Advanced Functions with `[CmdletBinding()]` and camelCase parameters. Indent PowerShell with two spaces to match existing modules, keep function names in `Verb-Noun` form (e.g., `Ensure-StandardFolders`), and export via `Export-ModuleMember`. YAML config keys should be lowercase with dashes (`install-apps`). Python follows PEP 8 with 4-space indentation; prefer `Path` over string concatenation when possible. Commit generated artifacts to `state/` or `logs/` only if explicitly required; otherwise add them to `.gitignore`.

## Testing Guidelines
Author unit tests with Pester v5 placed under `tests/Pester/<ModuleName>.Tests.ps1`. Name tests using `Describe "WinOps.Files"` and `It "Creates missing folders"` patterns. Run suites from PowerShell 7 when available:
```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path tests/Pester -Output Detailed"
```
Add integration checks that validate idempotency by running the same task twice and asserting no changes on the second run.

## Commit & Pull Request Guidelines
Write imperative, 60-character-or-less subject lines (`Add winget retry backoff`). Group related changes per commit (module + tests + docs). Pull requests should describe the scenario, affected modules, manual test steps, and include Windows edition coverage notes (e.g., “Validated on Server 2019 Core”). Link to issue IDs when applicable and attach sanitized transcript snippets from `logs/transcript` for troubleshooting.

## Security & Configuration Tips
Every script must confirm elevation before mutating system state (`Test-ProcessAdminRights`). Guard OS-specific logic with `$PSVersionTable.OS` or `Get-CimInstance Win32_OperatingSystem` checks to branch between Windows 10/11 and Server SKUs. Never hardcode credentials; use Windows Credential Manager or secure parameters. When adding new modules, document required firewall or policy exceptions in `docs/` and expose safe defaults through configuration files rather than inline values.
