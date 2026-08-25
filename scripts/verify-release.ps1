# ============================================================================
# DevSetup Release Verification Script
# Verifies release ZIP integrity against .sha256 file
# ============================================================================

[CmdletBinding()]
param(
    [string]$Version
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
if (-not $Version) {
    $Version = (Get-Content -Path (Join-Path $rootDir "config\defaults.json") -Raw | ConvertFrom-Json).appVersion
}
$distDir = Join-Path $rootDir "dist"

$zipPath = Join-Path $distDir "DLD-Luan-Dev-v$Version.zip"
$shaPath = Join-Path $distDir "DLD-Luan-Dev-v$Version.zip.sha256"

if (-not (Test-Path $zipPath) -or -not (Test-Path $shaPath)) {
    Write-Host "[ERROR] Release artifacts not found in $distDir. Run build-release.ps1 first." -ForegroundColor Red
    exit 1
}

$expectedHash = (Get-Content -Path $shaPath -Raw).Trim().Split(' ')[0].ToLower()
$computedHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()

Write-Host "Verifying Release Artifacts..." -ForegroundColor Cyan
Write-Host "Expected SHA256: $expectedHash" -ForegroundColor Gray
Write-Host "Computed SHA256: $computedHash" -ForegroundColor Gray

if ($expectedHash -eq $computedHash) {
    Write-Host "[OK] Release verification PASSED." -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAIL] Release verification FAILED. Hashes do not match!" -ForegroundColor Red
    exit 1
}
