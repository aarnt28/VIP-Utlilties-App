param([string]$OutZip = "$(Join-Path $env:TEMP "logs-$(hostname)-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip")")
$root = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $root 'logs'), $OutZip)
Write-Host "Logs collected: $OutZip"
