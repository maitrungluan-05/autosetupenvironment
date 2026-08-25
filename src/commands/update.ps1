# ============================================================================
# DevSetup Commands - Update Handler
# ============================================================================

function Invoke-DevSetupUpdate {
    param(
        [Parameter(Mandatory=$true)]$Config,
        [string]$TargetEnv = $null,
        [switch]$DryRun = $false,
        [switch]$Yes = $false
    )

    Write-DevSetupHeader -Title "DevSetup Update Manager"

    $packagesToCheck = @()
    if ($TargetEnv) {
        $envDef = Get-EnvironmentDefinition -Config $Config -EnvironmentId $TargetEnv
        if (-not $envDef) {
            Write-Host "Unknown environment '$TargetEnv'." -ForegroundColor Red
            return 1
        }
        foreach ($pkgId in $envDef.packages) {
            $pkg = Get-PackageDefinition -Config $Config -PackageId $pkgId
            if ($pkg) { $packagesToCheck += $pkg }
        }
    } else {
        foreach ($pkgKey in $Config.Packages.psobject.Properties.Name) {
            $packagesToCheck += $Config.Packages.$pkgKey
        }
    }

    Write-Host "Checking for available updates..." -ForegroundColor Gray

    $updatesAvailable = @()
    foreach ($pkg in $packagesToCheck) {
        $det = Detect-PackageStatus -PackageDef $pkg
        if ($det.Status -eq "OUTDATED") {
            $updatesAvailable += @{
                Name = $pkg.name
                DisplayName = $pkg.displayName
                Current = $det.CurrentVersion
                PackageDef = $pkg
            }
        }
    }

    if ($updatesAvailable.Count -eq 0) {
        Write-Host "All managed packages are up to date." -ForegroundColor Green
        return 0
    }

    Write-Host ""
    Write-Host "Available updates:" -ForegroundColor White
    Write-Host ""

    foreach ($up in $updatesAvailable) {
        Write-Host "  $($up.DisplayName)" -ForegroundColor Cyan
        Write-Host "    Current: $($up.Current)" -ForegroundColor Gray
        Write-Host "    Action:  Upgrade via Winget ($($up.PackageDef.wingetId))" -ForegroundColor Yellow
        Write-Host ""
    }

    if ($DryRun) {
        Write-Host "Dry run completed. No updates were installed." -ForegroundColor Yellow
        return 0
    }

    if (-not $Yes) {
        $confirm = Confirm-Action -PromptMessage "Update selected packages?" -DefaultYes $true
        if (-not $confirm) {
            Write-Host "Update cancelled by user." -ForegroundColor Yellow
            return 0
        }
    }

    $successCount = 0
    foreach ($up in $updatesAvailable) {
        $pkg = $up.PackageDef
        Write-Host "Upgrading $($up.DisplayName)..." -ForegroundColor Cyan
        $res = Upgrade-WingetPackage -PackageId $pkg.wingetId
        if ($res.Success) {
            Write-Host "[OK] $($up.DisplayName) upgraded successfully." -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "[ERROR] Failed to upgrade $($up.DisplayName)." -ForegroundColor Red
        }
    }

    Refresh-ProcessEnvironment
    return 0
}
