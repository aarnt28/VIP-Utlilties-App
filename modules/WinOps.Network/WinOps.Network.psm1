# Dot-source public functions
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object { . $_ }
Export-ModuleMember -Function Disable-IPv6
