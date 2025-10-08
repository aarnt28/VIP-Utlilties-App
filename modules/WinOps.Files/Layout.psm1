function Ensure-StandardFolders {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable]$map
  )
  foreach ($kv in $map.GetEnumerator()) {
    $path = $kv.Key
    $opts = $kv.Value
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    Write-Host "[+] Ensured folder: $path"
    if ($opts.acl) {
      try {
        $parts = $opts.acl -split ':'
        if ($parts.Length -eq 2) {
          $identity = $parts[0]; $perm = $parts[1]
          $acl = Get-Acl $path
          $ar = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $perm, "ContainerInherit, ObjectInherit", "None", "Allow")
          $acl.AddAccessRule($ar) | Out-Null
          Set-Acl -Path $path -AclObject $acl
          Write-Host "    ACL: $identity => $perm"
        }
      } catch { Write-Warning "ACL set failed for $path: $($_.Exception.Message)" }
    }
  }
}
Export-ModuleMember -Function Ensure-StandardFolders
