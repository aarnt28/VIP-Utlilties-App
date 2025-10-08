$script:Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$script:EventsFile = Join-Path $script:Root "logs\events.jsonl"

function Write-Event {
  param([string]$Message, [string]$Level = "info", [hashtable]$Data)
  $obj = @{
    time = (Get-Date).ToString("o")
    level = $Level
    message = $Message
    data = $Data
  }
  $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -Path $script:EventsFile -Value $line
}
Export-ModuleMember -Function Write-Event
