param(
  [Parameter(Mandatory=$true)][string]$Task,
  [string[]]$Profile = @(),
  [switch]$VerboseLogging
)

$ErrorActionPreference = 'Stop'
$script:Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# --- Elevation check/relaunch ---
function Ensure-Elevation {
  $current = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($current)
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Re-launching elevated..."
    $psi = New-Object System.Diagnostics.ProcessStartInfo "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Task `"$Task`" -Profile `"$($Profile -join ',')`" " + ($VerboseLogging.IsPresent ? "-VerboseLogging" : "")
    $psi.Verb = "runas"
    [Diagnostics.Process]::Start($psi) | Out-Null
    exit
  }
}
Ensure-Elevation

# --- Transcript & JSONL logging ---
$logDir = Join-Path $script:Root "logs"
$transcriptDir = Join-Path $logDir "transcript"
$eventsFile = Join-Path $logDir "events.jsonl"
$reportsDir = Join-Path $logDir "reports"
New-Item -ItemType Directory -Force -Path $transcriptDir,$reportsDir | Out-Null
$tsName = "$(hostname)-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
Start-Transcript -Path (Join-Path $transcriptDir $tsName) | Out-Null

function Write-Event {
  param([string]$Message, [string]$Level = "info", [hashtable]$Data)
  $obj = @{
    time = (Get-Date).ToString("o")
    level = $Level
    message = $Message
    data = $Data
  }
  $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -Path $eventsFile -Value $line
  if ($VerboseLogging) { Write-Host "[$Level] $Message" }
}

# --- Prefer pwsh if present; optionally install via winget ---
function Get-PwshPath {
  $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)
  if ($pwsh) { return $pwsh.Source }
  return $null
}

$pwshPath = Get-PwshPath
if ($PSVersionTable.PSEdition -ne 'Core' -and $pwshPath) {
  Write-Host "Relaunching under PowerShell 7+: $pwshPath"
  & $pwshPath -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Task $Task -Profile ($Profile -join ',') @($VerboseLogging.IsPresent ? "-VerboseLogging" : $null)
  Stop-Transcript | Out-Null
  exit
}

if (-not $pwshPath) {
  $winget = (Get-Command winget -ErrorAction SilentlyContinue)
  if ($winget) {
    Write-Host "PowerShell 7+ not found. Attempting install via winget (Microsoft.PowerShell)..."
    try {
      winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements --scope machine
      $pwshPath = Get-PwshPath
      if ($pwshPath) {
        Write-Host "Installed. Relaunching under PowerShell 7+: $pwshPath"
        & $pwshPath -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Task $Task -Profile ($Profile -join ',') @($VerboseLogging.IsPresent ? "-VerboseLogging" : $null)
        Stop-Transcript | Out-Null
        exit
      }
    } catch {
      Write-Warning "Failed to install PowerShell 7 via winget: $($_.Exception.Message). Continuing under Windows PowerShell 5.1."
    }
  } else {
    Write-Host "winget not present; continuing under Windows PowerShell 5.1."
  }
}

# --- Import Core ---
Import-Module (Join-Path $script:Root "modules\WinOps.Core\WinOps.Core.psm1") -Force

# --- Load config stack ---
$configRoot = Join-Path $script:Root "config"
$defaultsYaml = Join-Path $configRoot "defaults.yaml"
$defaultsJson = Join-Path $configRoot "defaults.json"

$profilesYaml = @()
$profilesJson = @()
foreach ($p in $Profile) {
  $py = Join-Path $configRoot "profiles\$p.yaml"
  $pj = Join-Path $configRoot "profiles\$p.json"
  if (Test-Path $py) { $profilesYaml += $py }
  if (Test-Path $pj) { $profilesJson += $pj }
}

$config = Get-WinOpsConfig -DefaultsYaml $defaultsYaml -DefaultsJson $defaultsJson -ProfileYamls $profilesYaml -ProfileJsons $profilesJson
Write-Event "Loaded configuration" "info" @{ profiles = $Profile }

# --- Run the task ---
$taskPathYaml = Join-Path $script:Root "tasks\$Task.yaml"
$taskPathJson = Join-Path $script:Root "tasks\$Task.json"
$task = Get-WinOpsTask -TaskYaml $taskPathYaml -TaskJson $taskPathJson
Write-Event "Executing task" "info" @{ task = $task.name }

Invoke-WinOpsTask -Task $task -Config $config

# --- Report ---
$report = Join-Path $reportsDir ("{0}-{1}.html" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd-HHmmss'))
@"
<html><body style='font-family:Segoe UI,Arial,Helvetica,sans-serif'>
<h2>WinOpsToolkit run summary</h2>
<p>Host: <b>$($env:COMPUTERNAME)</b> at $(Get-Date)</p>
<p>Task: <b>$($task.name)</b></p>
<p>Profiles: <b>$(", ".Join($Profile))</b></p>
<p>Transcript: $tsName</p>
</body></html>
"@ | Set-Content -Path $report -Encoding UTF8

Write-Host "Done. Report: $report"
Stop-Transcript | Out-Null
