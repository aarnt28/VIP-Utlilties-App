<# 
.SYNOPSIS
  Convert a YAML file to JSON.

.DESCRIPTION
  Reads a YAML file, parses it with the powershell-yaml module, and writes JSON.
  Handles multi-document YAML ('---' separated) by emitting a JSON array.
  Works on Windows PowerShell 5.1 and PowerShell 7+.

.PARAMETER InPath
  Path to the input YAML file.

.PARAMETER OutPath
  Path to the output JSON file to create/overwrite.

.EXAMPLE
  .\Convert-YamlToJson.ps1 -InPath .\tasks\workstation.yaml -OutPath .\tasks\workstation.json

.NOTES
  Requires: powershell-yaml module
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true, Position=0)]
  [ValidateNotNullOrEmpty()]
  [string]$InPath,

  [Parameter(Mandatory=$true, Position=1)]
  [ValidateNotNullOrEmpty()]
  [string]$OutPath
)

$ErrorActionPreference = 'Stop'

function Ensure-YamlModule {
  if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Verbose "powershell-yaml module not found. Attempting install for current user..."
    try {
      # Ensure TLS 1.2 for the gallery on older hosts
      try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
      # Install for current user without prompting; may require NuGet provider
      if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
      }
      Install-Module -Name powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
      throw "Unable to install 'powershell-yaml'. Install it manually: Install-Module powershell-yaml -Scope CurrentUser. Details: $($_.Exception.Message)"
    }
  }
  Import-Module powershell-yaml -ErrorAction Stop
}

try {
  # Resolve paths and sanity checks
  $inFull  = Resolve-Path -Path $InPath -ErrorAction Stop
  $outFull = [IO.Path]::GetFullPath((Join-Path -Path (Get-Location) -ChildPath $OutPath))

  $outDir = [IO.Path]::GetDirectoryName($outFull)
  if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
  }

  Ensure-YamlModule

  # Read entire YAML file as a single string
  $yamlText = Get-Content -LiteralPath $inFull -Raw -ErrorAction Stop

  if ([string]::IsNullOrWhiteSpace($yamlText)) {
    throw "Input file '$inFull' is empty."
  }

  # Parse YAML. Use -AllDocuments to handle '---' multi-doc files.
  $parsed = ConvertFrom-Yaml -Yaml $yamlText -AllDocuments

  # If only one document, unwrap from array for cleaner JSON
  if ($parsed -is [System.Collections.IList] -and $parsed.Count -eq 1) {
    $parsed = $parsed[0]
  }

  # Convert to compact JSON with generous depth
  $json = $parsed | ConvertTo-Json -Depth 100

  # Write JSON
  Set-Content -LiteralPath $outFull -Value $json -Encoding UTF8

  Write-Host "✅ Converted '$inFull' -> '$outFull'"
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
