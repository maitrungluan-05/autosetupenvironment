Write-Host "--- search apache ---"
winget search apache | Select-Object -First 10
Write-Host "--- search gradle ---"
winget search "gradle" | Select-Object -First 10
Write-Host "--- search maven ---"
winget search "maven" | Select-Object -First 10
