$adapter = Get-NetAdapter | Where-Object { $_.Name -in @('Wi-Fi', 'Ethernet') -and $_.Status -eq 'Up'} | Select-Object -First 1
$config = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex
$IpAddress = $config.IPv4Address.IPAddress
$PrefixLength = $config.IPv4Address.PrefixLength
$DefaultGateway = $config.IPv4DefaultGateway.NextHop

function Get-AdapterStatus {
    if($adapter) {
        $($adapter | Select-Object Name, InterfaceDescription) | Out-Host
    } else {
        Write-Host "No Adapter Found"
    }
}


function Convert-PrefixLengthToSubnetMask {
    param (
        [ValidateRange(0, 32)]
        [int]$PrefixLength
    )

    $binary = ('1' * $PrefixLength).PadRight(32, '0')

    $binaryOctets = ($binary -split '(.{8})' | Where-Object { $_ -ne '' })

    $decimalOctets = $binaryOctets | ForEach-Object { [Convert]::ToInt32($_, 2) }

    return ($decimalOctets -join '.')
}

function Get-NetworkAddress {
    param (
        [string]$IPAddress,
        [string]$SubnetMask
    )

    $ipAddressOctets = $IPAddress -split '\.'
    $subnetMaskOctets = $SubnetMask -split '\.'

    $networkAddressOctets = @()

    for ($i = 0; $i -lt 4; $i++) {
        $networkAddressOctets += [string]($ipAddressOctets[$i] -band $subnetMaskOctets[$i])
    }

    return ($networkAddressOctets -join '.')
}


function Test-IPv4Address {
    $subnetMask = Convert-PrefixLengthToSubnetMask -PrefixLength $PrefixLength

    $ipNetworkAddress = Get-NetworkAddress -IPAddress $IpAddress -SubnetMask $subnetMask

    $gatewayNetworkAddress = Get-NetworkAddress -IPAddress $DefaultGateway -SubnetMask $subnetMask
    
    if ($ipNetworkAddress -eq $gatewayNetworkAddress) {
        #Write-Host "The IPv4 address $IpAddress is in the same subnet as the default gateway $DefaultGateway"
    } else {
        Write-Host "The IPv4 address $IpAddress is NOT in the same subnet as the default gateway $DefaultGateway"
    }
    
}

Get-AdapterStatus
Test-IPv4Address