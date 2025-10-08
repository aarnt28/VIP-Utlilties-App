using namespace System.IO

$script:ModuleRoot = Split-Path -Parent $PSCommandPath

# Import submodules
Import-Module (Join-Path $ModuleRoot "..\WinOps.Logging\Logging.psm1") -Force
Import-Module (Join-Path $ModuleRoot "..\WinOps.Files\Layout.psm1") -Force
Import-Module (Join-Path $ModuleRoot "..\WinOps.System\Registry.psm1") -Force
Import-Module (Join-Path $ModuleRoot "..\WinOps.Apps\Winget.psm1") -Force

function Merge-Hashtable {
  param([hashtable]$Base,[hashtable]$Overlay)
  $result = @{} + $Base
  foreach ($k in $Overlay.Keys) {
    if ($result.ContainsKey($k) -and $result[$k] -is [hashtable] -and $Overlay[$k] -is [hashtable]) {
      $result[$k] = Merge-Hashtable -Base $result[$k] -Overlay $Overlay[$k]
    } else {
      $result[$k] = $Overlay[$k]
    }
  }
  return $result
}

function Get-WinOpsConfig {
  [CmdletBinding()]
  param(
    [string]$DefaultsYaml,
    [string]$DefaultsJson,
    [string[]]$ProfileYamls,
    [string[]]$ProfileJsons
  )

  # Try YAML on 7+, else JSON
  $cfg = @{}
  $defaultsLoaded = $false
  if (Test-Path $DefaultsYaml -and (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
    $cfg = Get-Content $DefaultsYaml -Raw | ConvertFrom-Yaml
    $defaultsLoaded = $true
  } elseif (Test-Path $DefaultsJson) {
    $cfg = Get-Content $DefaultsJson -Raw | ConvertFrom-Json -AsHashtable
    $defaultsLoaded = $true
  }
  if (-not $defaultsLoaded) {
    $cfg = @{}
  }

  foreach ($py in $ProfileYamls) {
    if (Test-Path $py -and (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
      $p = Get-Content $py -Raw | ConvertFrom-Yaml
      $cfg = Merge-Hashtable $cfg $p
    }
  }
  foreach ($pj in $ProfileJsons) {
    if (Test-Path $pj) {
      $p = Get-Content $pj -Raw | ConvertFrom-Json -AsHashtable
      $cfg = Merge-Hashtable $cfg $p
    }
  }
  return $cfg
}

function Get-WinOpsTask {
  [CmdletBinding()]
  param(
    [string]$TaskYaml,
    [string]$TaskJson
  )
  if (Test-Path $TaskYaml -and (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
    return (Get-Content $TaskYaml -Raw | ConvertFrom-Yaml)
  }
  elseif (Test-Path $TaskJson) {
    return (Get-Content $TaskJson -Raw | ConvertFrom-Json -AsHashtable)
  }
  else {
    throw "Task not found: $TaskYaml or $TaskJson"
  }
}

function Get-StepKey {
  param($Step)
  $s = ($Step | ConvertTo-Json -Depth 8 -Compress)
  $bytes = [Text.Encoding]::UTF8.GetBytes($s)
  $sha = [Security.Cryptography.SHA256]::Create()
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
}

function Test-StepAlreadyApplied {
  param([string]$Key)
  $root = Join-Path $PSScriptRoot "..\..\state\applied"
  New-Item -ItemType Directory -Force -Path $root | Out-Null
  Test-Path (Join-Path $root "$Key.json")
}

function Set-StepApplied {
  param([string]$Key,[hashtable]$Meta)
  $root = Join-Path $PSScriptRoot "..\..\state\applied"
  $file = Join-Path $root "$Key.json"
  $obj = @{ time = (Get-Date).ToString("o"); meta = $Meta }
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Path $file -Encoding UTF8
}

function Invoke-WinOpsTask {
  [CmdletBinding()]
  param(
    [hashtable]$Task,
    [hashtable]$Config
  )

  Write-Event "Start task" "info" @{ name = $Task.name }

  foreach ($step in $Task.steps) {
    $key = Get-StepKey $step
    if ($step.idempotent -ne $false -and (Test-StepAlreadyApplied -Key $key)) {
      Write-Event "Skipping step (already applied)" "info" @{ uses = $step.uses }
      continue
    }

    $uses = [string]$step.uses
    # Support "Module/Namespace::Function" or "Module::Function"
    $parts = $uses -split "::"
    if ($parts.Count -ne 2) { throw "Invalid 'uses' format in step: $uses" }
    $moduleSpec = $parts[0]
    $func = $parts[1]

    # Import module path (already imported above for our sample modules)
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
      throw "Function not found: $func"
    }

    $with = $step.with
    Write-Event "Running step" "info" @{ function = $func; with = $with }
    & $func @with

    if ($step.idempotent -ne $false) {
      Set-StepApplied -Key $key -Meta @{ uses = $uses }
    }
  }

  Write-Event "Task complete" "info" @{ name = $Task.name }
}

Export-ModuleMember -Function Get-WinOpsConfig, Get-WinOpsTask, Invoke-WinOpsTask
