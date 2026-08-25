# ============================================================================
# DevSetup Test Runner
# Runs unit tests with Pester or custom test assertions
# ============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Running DevSetup Test Suite..." -ForegroundColor Cyan
Write-Host ""

$pesterInstalled = Get-Module -ListAvailable -Name Pester
if ($pesterInstalled) {
    Invoke-Pester -Path $scriptDir
} else {
    Write-Host "[WARN] Pester module not installed. Running lightweight test runner..." -ForegroundColor Yellow
    
    $testFiles = Get-ChildItem -Path $scriptDir -Filter "*.tests.ps1"
    $passed = 0
    $failed = 0

    foreach ($file in $testFiles) {
        Write-Host "Running $($file.Name)..." -ForegroundColor Gray
        try {
            . $file.FullName
            Write-Host "[OK] $($file.Name)" -ForegroundColor Green
            $passed++
        } catch {
            Write-Host "[FAIL] $($file.Name): $_" -ForegroundColor Red
            $failed++
        }
    }

    Write-Host ""
    Write-Host "Test Results: Passed $passed, Failed $failed" -ForegroundColor White
}
