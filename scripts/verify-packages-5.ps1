$ids = @('GoLang.Go', 'Hashicorp.Terraform')
foreach ($id in $ids) {
    $null = winget show --id $id --exact 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $id"
    } else {
        Write-Host "[FAIL] $id"
    }
}
