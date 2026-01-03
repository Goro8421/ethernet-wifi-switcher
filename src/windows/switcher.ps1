# Event-driven Ethernet/Wi-Fi switcher for Windows
# Uses CIM Indication Events for 0% CPU idle.

function Log-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Get-EthernetAdapter {
    Get-NetAdapter | Where-Object { $_.PhysicalMediaType -eq "802.3" -and $_.Status -ne "Not Present" } | Select-Object -First 1
}

function Get-WifiAdapter {
    Get-NetAdapter | Where-Object { $_.PhysicalMediaType -eq "Native 802.11" -and $_.Status -ne "Not Present" } | Select-Object -First 1
}

function Check-And-Switch {
    $eth = Get-EthernetAdapter
    $wifi = Get-WifiAdapter

    if ($null -eq $eth -or $null -eq $wifi) { return }

    if ($eth.Status -eq "Up") {
        if ($wifi.Status -ne "Disabled") {
            Log-Message "Ethernet connected ($($eth.Name)). Disabling Wi-Fi..."
            Disable-NetAdapter -Name $wifi.Name -Confirm:$false
        }
    } else {
        if ($wifi.Status -eq "Disabled") {
            Log-Message "Ethernet disconnected ($($eth.Name)). Enabling Wi-Fi..."
            Enable-NetAdapter -Name $wifi.Name -Confirm:$false
        }
    }
}

# Initial check
Check-And-Switch

# Register for CIM events (Network Adapter status changes)
$query = "SELECT * FROM MSFT_NetAdapter"
Register-CimIndicationEvent -Namespace "root\StandardCimv2" -Query $query -SourceIdentifier "NetAdapterChange"

Log-Message "Starting event monitor..."
try {
    while ($true) {
        $event = Wait-Event -SourceIdentifier "NetAdapterChange"
        Check-And-Switch
        Remove-Event -SourceIdentifier "NetAdapterChange"
    }
} finally {
    Unregister-Event -SourceIdentifier "NetAdapterChange"
}
