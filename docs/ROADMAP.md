# WinOpsToolkit Delivery Roadmap

This roadmap elaborates the recommended phases for delivering a unified CLI and GUI automation experience. Each phase lists its goals, key activities, deliverables, ownership guidance, and exit criteria so work can be tracked and delegated.

## Phase 1 – Discovery & Documentation (Week 1)
**Goals:** Understand the current standards, translate them into declarative tasks, and document configuration expectations.

**Key activities**
- Inventory workstation and server standards (folders, registry keys, baseline applications, scheduled tasks, security policies).
- Break standards into discrete, idempotent task steps that map to existing module capabilities (e.g., `WinOps.Files/Layout::Ensure-StandardFolders`).
- Author YAML task definitions in `tasks/` (with JSON mirrors for PS 5.1) following the `standard_build` example.
- Document configuration defaults (`config/defaults.*`) and create per-site profiles in `config/profiles/` to isolate environment-specific overrides.

**Deliverables**
- `docs/standards-matrix.md` capturing each requirement and the task/module responsible.
- Updated `tasks/<name>.yaml` and `<name>.json` for each baseline scenario (workstation, server, specialty roles).
- Populated `config/defaults.*` and profile files with placeholders or real values, plus documentation describing required secrets.
- Diagram (optional) of configuration precedence (defaults → profile overrides → runtime parameters).

**Exit criteria**
- Every standard has an owner module/task and the documentation is peer-reviewed.
- CLI can parse task definitions without runtime errors using sample configurations.

## Phase 2 – CLI Core Hardening (Weeks 2–3)
**Goals:** Make the PowerShell bootstrap resilient, observable, and extensible.

**Key activities**
- Extend `bootstrap/Start-WinOps.ps1` to include:
  - Parameter validation (ensure task files exist, profiles resolve, prevent duplicates).
  - Structured log levels (info/warn/error) and correlation IDs for downstream tooling.
  - Progress reporting hooks (e.g., `Write-Progress`) that can later feed the GUI stream.
- Create contribution guidelines for modules (naming, folder structure, function templates, test expectations).
- Refactor or add PowerShell modules (`modules/`) so each concern (files, registry, apps, services) is encapsulated with `Test-*` and `Invoke-*` functions.
- Add inline comment-based help and `Get-Help` support for CLI scripts.

**Deliverables**
- Updated bootstrap script and modules with tests in `tests/` (Pester) covering success and failure paths.
- `docs/cli-architecture.md` describing module layout, logging strategy, and configuration flow.
- `CONTRIBUTING.md` section or standalone file codifying module conventions.

**Exit criteria**
- `Start-WinOps.ps1` passes automated linting/testing and handles invalid input gracefully.
- Modules expose clear public functions with matching tests and documentation.

## Phase 3 – Shared Abstraction Layer (Week 4)
**Goals:** Provide a single contract that both CLI and GUI can consume to enumerate tasks/profiles and monitor execution.

**Key activities**
- Define a JSON schema (e.g., `schemas/task-metadata.json`) describing task metadata, configurable parameters, and validation rules.
- Implement PowerShell commands (e.g., `Get-WinOpsMetadata`, `Invoke-WinOpsTask -AsJob`) that emit machine-readable status updates.
- Add a lightweight REST or named-pipe bridge (optional) or rely on STDOUT JSONL for GUI consumption.
- Document environment variables and exit codes to maintain parity between interfaces.

**Deliverables**
- Metadata discovery command accessible via CLI returning available tasks/profiles.
- Streaming log format documentation (e.g., NDJSON events) and sample payloads.
- `docs/api-contract.md` detailing the contract, including example CLI invocations and expected responses.

**Exit criteria**
- CLI can list available tasks/profiles programmatically.
- Execution emits structured events consumable by the GUI prototype without additional parsing.

## Phase 4 – GUI Evolution (Weeks 5–6)
**Goals:** Turn the Python GUI into a thin yet dynamic shell over the shared abstraction layer with robust UX.

**Key activities**
- Refactor `python_gui/app/main.py` to:
  - Query the metadata contract and populate task/profile dropdowns dynamically.
  - Launch CLI runs, stream events, and render progress/logs in real time.
  - Surface validation errors and status codes from CLI execution.
- Introduce user feedback elements (spinner/progress bar, log pane, summary screen).
- Implement error boundaries, retries, and clear messaging for missing dependencies (PowerShell, winget).
- Add accessibility and layout improvements (keyboard shortcuts, high-contrast mode awareness).

**Deliverables**
- Updated GUI with modular components (e.g., `views/`, `services/`, `models/`) and configuration for packaging via PyInstaller.
- UX documentation or screenshots demonstrating key flows.
- `python_gui/tests/` with unit tests for metadata parsing and CLI invocation wrappers (pytest).

**Exit criteria**
- GUI can complete end-to-end runs using the same task definitions as the CLI and shows success/failure states.
- Automated GUI smoke test passes in CI (headless, if possible).

## Phase 5 – Testing & Delivery (Week 7+)
**Goals:** Institutionalize automated validation, packaging, and deployment.

**Key activities**
- Expand Pester test coverage for PowerShell modules and bootstrap (mocking external dependencies like winget).
- Add Python unit and integration tests, plus GitHub Actions workflows covering both stacks.
- Configure code quality tooling (PSScriptAnalyzer, flake8/black, mypy as applicable).
- Draft packaging scripts:
  - PowerShell module manifest updates and publishing steps.
  - PyInstaller spec file or MSIX packaging for GUI.
- Define deployment documentation (how to install CLI, how to deploy GUI asset).

**Deliverables**
- `tests/` directory populated with Pester and pytest suites plus CI configuration in `.github/workflows/` (or equivalent).
- Packaging artifacts or scripts stored under `scripts/` or `build/`.
- `docs/release-checklist.md` describing release steps, verification, and rollback guidance.

**Exit criteria**
- CI pipeline executes linting, unit tests, and smoke tests on push/PR.
- Packaged deliverables can be installed on a clean workstation following documented steps.

## Cross-cutting Practices
- Maintain a living changelog (`CHANGELOG.md`) updated each sprint.
- Track work via issues/epics referencing roadmap phases.
- Review documentation alongside code in pull requests to ensure alignment.

## Suggested Timeline Snapshot
| Week | Focus | Key Milestone |
|------|-------|---------------|
| 1 | Discovery & Documentation | Standards matrix approved |
| 2–3 | CLI Core Hardening | Hardened bootstrap + module guidelines |
| 4 | Shared Abstraction Layer | Metadata/API contract signed off |
| 5–6 | GUI Evolution | GUI consuming shared contract |
| 7+ | Testing & Delivery | CI + packaging pipeline operational |

This roadmap should be revisited at the end of each phase to incorporate feedback and adjust scope.
