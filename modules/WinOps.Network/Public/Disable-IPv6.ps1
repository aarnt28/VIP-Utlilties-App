function Disable-IPv6 {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('All','NonTunnel','Specific')]
        [string]$Scope = 'All',
        [string[]]$InterfaceAlias = @()
    )

    # Idempotency check helper
    function Test-IPv6State {
        param([string[]]$Ifaces)
        $targets = if ($Ifaces) { $Ifaces } else { (Get-NetAdapter | Where-Object Status -eq 'Up').InterfaceAlias }
        $diff = foreach ($i in $targets) {
            $binding = Get-NetAdapterBinding -Name $i -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
            if ($binding.Enabled) { $i }
        }
        return [PSCustomObject]@{
            EnabledOn = $diff
            IsCompliant = ($diff.Count -eq 0)
        }
    }

    $before = Test-IPv6State -Ifaces $InterfaceAlias
    if ($before.IsCompliant) {
        return [PSCustomObject]@{ Step='Disable-IPv6'; Status='ok'; Changed=$false; Message='Already disabled' }
    }

    if ($PSCmdlet.ShouldProcess("Interfaces: $($before.EnabledOn -join ', ')","Disable IPv6 binding")) {
        foreach ($i in $before.EnabledOn) {
            Disable-NetAdapterBinding -Name $i -ComponentID ms_tcpip6 -PassThru | Out-Null
        }
    }

    $after = Test-IPv6State -Ifaces $InterfaceAlias
    return [PSCustomObject]@{
        Step='Disable-IPv6'
        Status= if ($after.IsCompliant) { 'ok' } else { 'warn' }
        Changed=$true
        Message= if ($after.IsCompliant) { 'IPv6 disabled' } else { "Some interfaces still enabled: $($after.EnabledOn -join ', ')" }
    }
}
