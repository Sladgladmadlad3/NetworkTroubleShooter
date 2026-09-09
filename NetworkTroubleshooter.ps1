$adapter = Get-NetAdapter | Where-Object { $_.Name -eq 'Wi-Fi' } | Select-Object -First 1
$config = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex

#$subnetmaskdecimal =Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | where-object {$_.InterfaceIndex -eq $adapter.InterfaceIndex} | Select-Object -ExpandProperty IPSubnet | where-object { $_ -like '255.*' }

function Test-IPv4Address {
    $GetIPAddress = $config.IPv4Address.IPAddress
    $GetPrefixLength = $config.IPv4Address.PrefixLength
    $GetDefaultGateway = $config.IPv4DefaultGateway.NextHop
    #$GetSubnetMask = $subnetmaskdecimal

    if($null -eq $GetPrefixLength) {
        Write-Host "No IPv4 address is assigned to the adapter."
        return
    }else {
        function Convert-PrefixLengthToNetworkAddress {
            param (
                [int]$PrefixLength
            )
            $IpSubnetToConvertedNetworkAddress = @()
            $IpSubnetToDefaultGateway = @()
            $binary = ('1' * $PrefixLength).PadRight(32, '0')
            $binaryFormatted = ($binary -split '(.{8})' | Where-Object { $_ -ne '' }) -join '.'
            $ipAddress = ($GetIPAddress -split '\.')
            $GetDefaultGateway = ($GetDefaultGateway -split '\.')
            $subnetMask = ($binaryFormatted -split '\.') | ForEach-Object { [Convert]::ToInt32($_, 2) }

            for ($i = 0; $i -lt 4; $i++) {
                $result = $ipAddress[$i] -band $subnetMask[$i]
                $ipSubnetToConvertedNetworkAddress += [string]$result
            }

            for ($i = 0; $i -lt 4; $i++) {
                $result = $GetDefaultGateway[$i] -band $subnetMask[$i]
                $ipSubnetToDefaultGateway += [string]$result
            }

            If (($ipSubnetToConvertedNetworkAddress -join '.') -eq ($ipSubnetToDefaultGateway -join '.')) {
                Write-Host "The default gateway is in the same network as the IP address."
                Write-Host "IP Address: $($GetIPAddress)"
                Write-Host "Default Gateway: $($ipSubnetToDefaultGateway -join '.')"
            } else {
                Write-Host "The default gateway is NOT in the same network as the IP address."
                Write-Host "IP Address: $($GetIPAddress)"
                Write-Host "Default Gateway: $($ipSubnetToDefaultGateway -join '.')"
            }

            return
        }
    }

    return Convert-PrefixLengthToNetworkAddress -PrefixLength $GetPrefixLength
}

Test-IPv4Address