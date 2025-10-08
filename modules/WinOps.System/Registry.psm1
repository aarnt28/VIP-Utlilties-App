function Set-RegistryValues {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][array]$values,
    [switch]$backup
  )
  foreach ($v in $values) {
    $path = $v.path
    $name = $v.name
    $type = $v.type
    $data = $v.data
    if ($backup) {
      $safe = (($path + "\" + $name) -replace '[:\\/]','_')
      $backupDir = Join-Path $env:ProgramData "WinOps\registry-backups"
      New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
      $backupPath = Join-Path $backupDir "$safe.reg"
      try { reg export $path $backupPath /y | Out-Null } catch {}
    }
    New-Item -Path $path -Force | Out-Null
    New-ItemProperty -Path $path -Name $name -PropertyType $type -Value $data -Force | Out-Null
    Write-Host "[+] Set $path\$name -> $data"
  }
}
Export-ModuleMember -Function Set-RegistryValues
