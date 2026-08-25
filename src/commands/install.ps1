# ============================================================================
# DevSetup Commands - Install & All Handler
# ============================================================================

function Invoke-DevSetupAll {
    param(
        [Parameter(Mandatory=$true)]$Config,
        [switch]$DryRun = $false,
        [switch]$Yes = $false,
        [switch]$VerboseMode = $false,
        [switch]$NoIde = $false
    )

    Write-DevSetupHeader -Title "DevSetup - All Environments Setup"

    Write-Host "Resolving environment dependencies and packages..." -ForegroundColor Gray

    # Collect unique packages from all environments
    $allPkgIds = @()
    foreach ($envKey in $Config.Environments.psobject.Properties.Name) {
        $env = $Config.Environments.$envKey
        foreach ($pkgId in $env.packages) {
            if ($allPkgIds -notcontains $pkgId) {
                $allPkgIds += $pkgId
            }
        }
    }

    # Run detection on unique package set
    $detectionResults = @()
    foreach ($id in $allPkgIds) {
        $pkg = Get-PackageDefinition -Config $Config -PackageId $id
        if ($pkg) {
            $detectionResults += Detect-PackageStatus -PackageDef $pkg
        }
    }

    Display-DetectionTable -Results $detectionResults

    # Consolidate Plan
    $plan = Create-InstallationPlan -DetectionResults $detectionResults -NoIde:$NoIde
    $installResult = Execute-InstallationPlan -PlanItems $plan -DryRun:$DryRun -Yes:$Yes

    if ($DryRun) {
        return
    }

    # Verifications
    $verifications = @()
    foreach ($item in $plan) {
        if ($item.Action -in @("KEEP", "INSTALL", "UPGRADE")) {
            $verifications += Verify-Package -PackageDef $item.PackageDef
        }
    }

    Display-VerificationReport -VerificationResults $verifications -EnvironmentName "Consolidated"
}
