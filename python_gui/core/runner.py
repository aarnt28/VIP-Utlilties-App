# python_gui/core/runner.py
import ctypes
import os
import shutil
import subprocess
import sys
import shlex
from typing import Iterable, Optional, Callable

# type of callback: gets one decoded line at a time (without trailing newline)
OnLine = Optional[Callable[[str], None]]

def is_admin() -> bool:
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False

def find_shell() -> str:
    # prefer pwsh, fallback to powershell.exe (mirrors your bootstrap behavior)
    candidates = (
        "pwsh",
        r"C:\Program Files\PowerShell\7\pwsh.exe",
        "powershell.exe",
    )
    for cand in candidates:
        if shutil.which(cand) or os.path.exists(cand):
            return cand
    return "powershell.exe"

def repo_root_from(this_file: str) -> str:
    # Adjust if your GUI lives deeper; this assumes python_gui/ sibling to repo root
    here = os.path.dirname(os.path.abspath(this_file))
    # if main.py is at python_gui/main.py, repo root is one up
    return os.path.abspath(os.path.join(here, os.pardir))

def run_task(task: str,
             profiles: Iterable[str],
             on_line: OnLine = None) -> Optional[int]:
    """
    Runs bootstrap/Start-WinOps.ps1 with -Task and -Profile.
    Streams output via on_line if provided, returns process exit code
    (or None when re-launched elevated via UAC).
    """
    shell = find_shell()
    # If this file is .../python_gui/core/runner.py, repo root is two up
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))
    bootstrap = os.path.join(repo_root, "bootstrap", "Start-WinOps.ps1")

    if not os.path.isfile(bootstrap):
        raise FileNotFoundError(f"Bootstrap script not found: {bootstrap}")

    profile_arg = ",".join(p.strip() for p in profiles)
    # Build a -File invocation to avoid weird quoting issues
    # Note: we keep ExecutionPolicy process-scope like your docs
    base_args = [
        "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", bootstrap,
        "-Task", task,
        "-Profile", profile_arg,
    ]

    if not is_admin():
        # Relaunch elevated. With ShellExecute "runas", you won't be able to capture stdout.
        # So we invoke -Command to forward parameters cleanly.
        # Use & to execute the file path safely in PowerShell.
        pwsh_command = f'& "{bootstrap}" -Task {shlex.quote(task)} -Profile {shlex.quote(profile_arg)}'
        params = f'-NoLogo -NoProfile -ExecutionPolicy Bypass -Command {shlex.quote(pwsh_command)}'
        # Show UAC prompt and return immediately (no live output capture possible)
        ctypes.windll.shell32.ShellExecuteW(None, "runas", shell, params, None, 1)
        return None

    # Normal (already elevated) path: capture output
    cmd = [shell] + base_args
    # Ensure we run from repo root so relative paths in tasks/config work
    proc = subprocess.Popen(
        cmd,
        cwd=repo_root,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    try:
        for line in proc.stdout:
            line = line.rstrip("\r\n")
            if on_line:
                on_line(line)
            else:
                print(line)
    finally:
        proc.wait()
    return proc.returncode
