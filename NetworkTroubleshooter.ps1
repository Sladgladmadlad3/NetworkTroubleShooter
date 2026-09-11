$adapter = Get-NetAdapter | Where-Object { $_.Name -in @('Wi-Fi', 'Ethernet') -and $_.Status -eq 'Up'} | Select-Object -First 1
$config = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex
$IpAddress = $config.IPv4Address.IPAddress
$PrefixLength = $config.IPv4Address.PrefixLength
$DefaultGateway = $config.IPv4DefaultGateway.NextHop

function New-TestResult {
    param (
        $TestName,
        $Value,
        [ValidateSet("PASS", "FAIL", "WARNING", "SKIP")]
        [String]$Status,
        $Message
    )

    return [PSCustomObject]@{
        TestName = $TestName
        Value = $Value
        Status = $Status
        Message = $Message
    }
}


function Get-FirstUpAdapter {
    if($adapter) {
        $($adapter | Select-Object Name, InterfaceDescription, Status) | Out-Host
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
    
    
    if ($null -eq $IpAddress) {
        $Status = "FAIL"
        $Message = "No IPv4 address found for the adapter $($adapter.Name)"
        Return New-TestResult -TestName "IPv4 Address Test" -Value $IpAddress -Status $Status -Message $Message
    } elseif ($IpAddress.StartsWith("169.254.") -and $PrefixLength -eq 16) {
        $Status = "WARNING"
        $Message = "IPv4 address is in the link-local range: $IpAddress"
        return New-TestResult -TestName "IPv4 Address Test" -Value $IpAddress -Status $Status -Message $Message
    } elseif ($null -eq $adapter) {
        $Status = "SKIP"
        $Message = ""
        return New-TestResult -TestName "IPv4 Address Test" -Value $IpAddress -Status $Status -Message $Message
    }
    else {
        $Status = "PASS"
        $Message = "IPv4 address found"
        return New-TestResult -TestName "IPv4 Address Test" -Value $IpAddress -Status $Status -Message $Message
    }
    
}

function Show-TestResults {
    param (
        $Results = @()
    )

    $Results | ForEach-Object {

    Write-Host "Test: $($_.TestName)"
    Write-Host "Value: $($_.Value)"

    switch ($_.Status) {
        "PASS"    { Write-Host "Status: PASS" -ForegroundColor Green }
        "FAIL"    { Write-Host "Status: FAIL" -ForegroundColor Red }
        "WARNING" { Write-Host "Status: WARNING" -ForegroundColor Yellow }
        "SKIP"    { Write-Host "Status: SKIP" -ForegroundColor DarkGray }
    }

    Write-Host "Message: $($_.Message)"
    Write-Host ""
}
}

Show-TestResults -Results @(Test-IPv4Address)