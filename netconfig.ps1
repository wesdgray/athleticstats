$IP = [pscustomobject] @{
                             'Address'           = '10.64.0.217'
                             'PrefixLength'      = 24
                             'DefaultGateway'    = '10.64.0.1'
                             'DNSServerAdresses' = @('207.190.35.254, 66.78.244.253')
                        }
$ifIndex = (Get-NetAdapter | Out-Gridview -Passthru).IfIndex
$NetInterfacePrevious = Get-NetIPInterface -ifIndex $ifIndex -AddressFamily IPv4
$NetIPAddressPrevious = $NetInterfacePrevious | Get-NetIPAddress
$DnsServerPrevious    = $NetInterfacePrevious | Get-DnsClientServerAddress -AddressFamily IPv4

Function setup-network {

    $NetInterfacePrevious | New-NetIPAddress -IPAddress $IP.Address -AddressFamily IPv4 `
                                             -DefaultGateway $IP.DefaultGateway `
                                             -PrefixLength $IP.PrefixLength
    $NetInterfacePrevious | Set-DnsClientServerAddress -ServerAddresses $IP.DNSServerAdresses
}

Function reset-network {
    $NetInterfacePrevious | Set-NetIPInterface -Dhcp Enabled
    $NetInterfacePrevious | Remove-NetRoute -NextHop $IP.DefaultGateway
    $NetInterfacePrevious | Set-DnsClientServerAddress -ResetServerAddresses
    ipconfig.exe /renew
}
