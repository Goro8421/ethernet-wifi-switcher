# Universal Ethernet/Wi-Fi Auto Switcher for Windows
# This script is self-contained and includes the switcher logic and uninstaller.

$TaskName = "EthWifiAutoSwitcher"
$DefaultInstallDir = "$env:ProgramFiles\EthWifiAuto"

# Embedded components (Base64)
$SwitcherB64 = "__SWITCHER_B64__"
$UninstallerB64 = "__UNINSTALLER_B64__"

function Install {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Please run as Administrator."
        return
    }

    $InstallDir = $DefaultInstallDir
    if ([Environment]::UserInteractive) {
        $userInput = Read-Host "Enter installation directory [$DefaultInstallDir]"
        if ($userInput) { $InstallDir = $userInput }
    }

    $SwitcherPath = "$InstallDir\eth-wifi-auto.ps1"

    Write-Host "Installing Ethernet/Wi-Fi Auto Switcher to $InstallDir..."

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    # Extract switcher
    $switcherBytes = [System.Convert]::FromBase64String($SwitcherB64)
    [System.IO.File]::WriteAllBytes($SwitcherPath, $switcherBytes)

    # Create Scheduled Task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SwitcherPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 365)

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName

    Write-Host "Installation complete. Task is running as SYSTEM."
}

function Uninstall {
    $uninstallerBytes = [System.Convert]::FromBase64String($UninstallerB64)
    $uninstallerScript = [System.Text.Encoding]::UTF8.GetString($uninstallerBytes)
    Invoke-Expression $uninstallerScript
}

param(
    [switch]$Uninstall
)

if ($Uninstall) {
    Uninstall
} else {
    Install
}
