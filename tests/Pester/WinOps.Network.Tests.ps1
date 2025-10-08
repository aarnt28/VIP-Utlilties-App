Import-Module "$PSScriptRoot\..\..\modules\WinOps.Network\WinOps.Network.psm1" -Force

Describe "Disable-IPv6" {
  It "is an advanced function" {
    (Get-Command Disable-IPv6).Options.ToString() | Should -Match "ShouldProcess"
  }
  It "returns already compliant on a mock system" {
    Mock Get-NetAdapter { [pscustomobject]@{ InterfaceAlias = 'Ethernet'; Status='Up' } }
    Mock Get-NetAdapterBinding { [pscustomobject]@{ Enabled = $false } }
    $r = Disable-IPv6 -WhatIf
    $r.Status | Should -Be 'ok'
    $r.Changed | Should -BeFalse
  }
}
