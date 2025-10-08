[CmdletBinding()]
param([string]$Out = "$PSScriptRoot\..\logs\inventory_$env:COMPUTERNAME.json")

$sys = Get-CimInstance Win32_ComputerSystem
$os  = Get-CimInstance Win32_OperatingSystem
$obj = [PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    Manufacturer = $sys.Manufacturer
    Model        = $sys.Model
    TotalRAMGB   = [math]::Round($sys.TotalPhysicalMemory/1GB,2)
    OSVersion    = $os.Version
    LastBoot     = $os.LastBootUpTime
}
$obj | ConvertTo-Json -Depth 4 | Out-File -Encoding utf8 -FilePath $Out
Write-Output $Out
exit 0
