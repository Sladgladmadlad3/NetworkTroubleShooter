$adapter = Get-NetAdapter | Where-Object {$_.Name -in @('Wi-Fi', 'Ethernet 8')}

function New-TestResult {
    param (
        $TestName,
        $Value,
        [ValidateSet("PASS", "FAIL", "WARNING", "SKIP")]
        [String]$Status,
        $Message,
        $Details
    )

    return [PSCustomObject]@{
        TestName = $TestName
        Status = $Status
        Value = $Value
        Message = $Message
        Details = $Details
    }
}


function Get-PrimaryAdapter {
    $candidateAdapters = $adapter

    $upAdapter = $candidateAdapters |
        Where-Object { $_.Status -eq 'Up' } |
        Select-Object -First 1

    if ($null -ne $upAdapter) {
        return $upAdapter
    }

    return $candidateAdapters | Select-Object -First 1
}

$config = Get-NetIPConfiguration -InterfaceIndex (Get-PrimaryAdapter).InterfaceIndex
$IpAddress = $config.IPv4Address.IPAddress
$PrefixLength = $config.IPv4Address.PrefixLength
$DefaultGateway = $config.IPv4DefaultGateway.NextHop



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

$subnetMask = Convert-PrefixLengthToSubnetMask -PrefixLength $PrefixLength
$ipNetworkAddress = Get-NetworkAddress `
    -IPAddress $IpAddress `
    -SubnetMask $subnetMask

$gatewayNetworkAddress = Get-NetworkAddress `
    -IPAddress $DefaultGateway `
    -SubnetMask $subnetMask

function Test-NetworkAdapter {
   $adapter = Get-PrimaryAdapter

    if ($null -eq $adapter) {
        return New-TestResult `
            -TestName "Network Adapter Test" `
            -Status "FAIL" `
            -Message "No Ethernet or Wi-Fi adapter found." `
            -Details $null
    }

    $details = [PSCustomObject]@{
        Type        = $adapter.Name
        Description = $adapter.InterfaceDescription
        AdminStatus = $adapter.AdminStatus
        LinkSpeed   = $adapter.LinkSpeed
    }

    if ($adapter.AdminStatus -eq "Down") {
        return New-TestResult `
            -TestName "Network Adapter Test" `
            -Status "FAIL" `
            -Message "Adapter is administratively disabled." `
            -Details $details
    }

    elseif ($adapter.Status -eq "Disconnected") {
        return New-TestResult `
            -TestName "Network Adapter Test" `
            -Status "FAIL" `
            -Message "Adapter is enabled but has no active link." `
            -Details $details
    }

    else {
        return New-TestResult `
            -TestName "Network Adapter Test" `
            -Status "PASS" `
            -Message "Adapter appears operational." `
            -Details $details
    }
}

function Test-IPv4Address {
    if ($null -eq $adapter) {
        return New-TestResult `
            -TestName "IPv4 Address Test" `
            -Value $null `
            -Status "SKIP" `
            -Message "No active physical adapter found"
    }

    if ($null -eq $IpAddress) {
        return New-TestResult `
            -TestName "IPv4 Address Test" `
            -Value $null `
            -Status "FAIL" `
            -Message "No IPv4 address found for adapter $($adapter.Name)"
    }

    if ($IpAddress.StartsWith("169.254.") -and $PrefixLength -eq 16) {
        return New-TestResult `
            -TestName "IPv4 Address Test" `
            -Value $IpAddress `
            -Status "WARNING" `
            -Message "IPv4 address is in the link-local range"
    }

    if ($ipNetworkAddress -ne $gatewayNetworkAddress) {
        return New-TestResult `
            -TestName "IPv4 Address Test" `
            -Value $IpAddress `
            -Status "FAIL" `
            -Message "IPv4 address and default gateway are not in the same subnet"
    }

    return New-TestResult `
        -TestName "IPv4 Address Test" `
        -Value $IpAddress `
        -Status "PASS" `
        -Message "IPv4 address found and gateway is in the same subnet"
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
    if($null -ne $_.Details) {
        
        $_.Details.PSObject.Properties | ForEach-Object {
            Write-Host "$($_.Name): $($_.Value)"
        }
    }
    Write-Host ""
}
}
Show-TestResults -Results @(Test-NetworkAdapter)
Show-TestResults -Results @(Test-IPv4Address)