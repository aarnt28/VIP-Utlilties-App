function Install-Apps {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string[]]$list,
    [hashtable]$options
  )
  $winget = (Get-Command winget -ErrorAction SilentlyContinue)
  if (-not $winget) {
    Write-Warning "winget not found. Skipping app installs."
    return
  }
  foreach ($pkg in $list) {
    Write-Host "[*] Installing $pkg via winget..."
    try {
      winget install --id $pkg --accept-package-agreements --accept-source-agreements --silent --scope machine
    } catch {
      Write-Warning "Failed to install $pkg: $($_.Exception.Message)"
    }
  }
}
Export-ModuleMember -Function Install-Apps
