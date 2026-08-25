Write-Host "--- search maven full ---"
winget search maven | Out-String | Write-Host
Write-Host "--- search gradle full ---"
winget search gradle | Out-String | Write-Host
