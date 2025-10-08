# Project: VIP Utility App

## Overview
This project provides command-line and/or GUI access to run various administrative scripts or setup tasks for windows environments to simplify deployments or common maintainance.Essentially; A portable toolkit for automating Windows workstation/server setup with PowerShell 5.1 or 7+, using declarative tasks (YAML/JSON) and idempotent modules.

## Important Project Parameters
Remember to assume ultimate execution will take place on Windows systems. in some cases Windows 10/11 Pro, and in other cases Windows Server 16/19/22/25. 
when implementation would differ depending on the Windows version/Edition, ensure to include logic to identify host OS and execute the proper method for the OS.

Ease of use and Compatibility is key. User should be able to run on any common windows system and be able to get things done because the project considers the appropriate variables and modifies approach accordingly. 

## Agent Behavior
Verifying assumptions and test when possible. Make surgical changes that are necessary to implement what the user asked for, stay on task.

Update README.md when changes are made that are notable regarding the use of the application. Be thorough and assume the target end user is a beginner and needs much instruction. 

## How it flows (in practice)
	1.	Bootstrap: Start-WinOps.ps1 -Task standard_build -Profile site-plano,workstation
	•	Ensures elevation, sets $ExecutionContext.SessionState.LanguageMode, starts transcript, loads config stack: defaults.yaml → mios_core.yaml → site-plano.yaml → workstation.yaml.
	2.	Task runner reads tasks/standard_build.yaml and executes steps via exported functions in modules/*.
	3.	Idempotency: each step writes a small marker to state/applied/ and compares current system state; steps become safe to re-run.
	4.	Logging: human-readable transcript + machine-readable JSONL events, plus an HTML report in logs/reports/.
  
## What’s inside (high-level)
	•	Bootstrap: elevation → prefer pwsh 7 (auto-install via winget if possible) → fall back to 5.1 → start transcript + JSONL events.
	•	Core engine: config/task loader with YAML (7+) or JSON fallback (5.1), simple idempotency stamps, and a tiny task runner.
	•	Modules:
	•	WinOps.Files/Layout::Ensure-StandardFolders
	•	WinOps.System/Registry::Set-RegistryValues (with optional .reg backups)
	•	WinOps.Apps/Winget::Install-Apps (defaults to winget)
	•	Declarative samples: tasks/standard_build.(yaml|json) and config/*.(yaml|json)
	•	Logging: transcripts, logs/events.jsonl, simple HTML run report
	•	Python GUI: minimal customtkinter front-end that calls the PS bootstrap and streams output
	•	Scaffold: tests, scripts, templates, state directories
