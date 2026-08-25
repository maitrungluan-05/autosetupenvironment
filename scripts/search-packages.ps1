Write-Host "--- Maven search ---"
winget search Maven | Select-Object -First 10
Write-Host "--- Gradle search ---"
winget search Gradle | Select-Object -First 10
Write-Host "--- Python search ---"
winget search Python.Python | Select-Object -First 10
