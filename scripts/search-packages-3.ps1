Write-Host "--- search Go ---"
winget search "Go" | Select-Object -First 15
Write-Host "--- search Golang ---"
winget search "Golang" | Select-Object -First 15
Write-Host "--- search Terraform ---"
winget search "Terraform" | Select-Object -First 15
Write-Host "--- search HashiCorp ---"
winget search "HashiCorp" | Select-Object -First 15
