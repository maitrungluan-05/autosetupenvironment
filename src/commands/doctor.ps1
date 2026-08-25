# ============================================================================
# DevSetup Commands - Doctor Handler
# ============================================================================

function Invoke-DevSetupDoctor {
    param(
        [Parameter(Mandatory=$true)]$Config,
        [switch]$Json = $false,
        [switch]$VerboseMode = $false
    )

    $sysInfo = Get-WindowsVersionInfo
    $isWin = Test-IsWindows
    $wingetAvailable = Test-WingetAvailable
    $wingetVersion = Get-WingetVersionString
    $hasNetwork = Test-NetworkConnectivity

    $systemChecks = @{
        Windows = $isWin
        WindowsVersion = $sysInfo.Caption
        Architecture = $sysInfo.Architecture
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Winget = $wingetAvailable
        WingetVersion = $wingetVersion
        Network = $hasNetwork
    }

    # Detect all defined packages
    $pkgResults = @()
    foreach ($pkgKey in $Config.Packages.psobject.Properties.Name) {
        $pkg = $Config.Packages.$pkgKey
        $res = Detect-PackageStatus -PackageDef $pkg
        $pkgResults += $res
    }

    $totalChecks = $pkgResults.Count
    $passedChecks = ($pkgResults | Where-Object { $_.Status -eq "INSTALLED_OK" }).Count
    $warningChecks = ($pkgResults | Where-Object { $_.Status -in @("WARN", "OUTDATED", "PARTIAL") }).Count
    $missingChecks = ($pkgResults | Where-Object { $_.Status -in @("MISSING", "OPTIONAL_MISSING", "BROKEN") }).Count

    $isHealthy = ($missingChecks -eq 0 -and $warningChecks -eq 0)

    # Calculate Exit Code
    # 0 = healthy
    # 1 = warnings/missing optional
    # 2 = required component missing/broken
    $hasRequiredMissing = ($pkgResults | Where-Object { $_.Status -eq "MISSING" -and -not $_.PackageDef.optional }).Count -gt 0
    $exitCode = if ($isHealthy) { 0 } elseif ($hasRequiredMissing) { 2 } else { 1 }

    if ($Json) {
        $jsonObject = [ordered]@{
            healthy = $isHealthy
            exitCode = $exitCode
            system = $systemChecks
            environments = $pkgResults | ForEach-Object {
                [ordered]@{
                    id = $_.Id
                    name = $_.Name
                    displayName = $_.DisplayName
                    status = $_.Status
                    currentVersion = $_.CurrentVersion
                    minimumVersion = $_.MinimumVersion
                    optional = [bool]$_.PackageDef.optional
                }
            }
            summary = [ordered]@{
                totalChecks = $totalChecks
                passed = $passedChecks
                warnings = $warningChecks
                missing = $missingChecks
            }
        }

        # Convert to JSON with zero ANSI/color output to stdout
        $jsonStr = $jsonObject | ConvertTo-Json -Depth 5
        [Console]::Out.WriteLine($jsonStr)
        return $exitCode
    }

    # Text Display
    Write-DevSetupHeader -Title "DevSetup Doctor"

    Write-Host "System" -ForegroundColor White
    Write-Host "  [OK] $($sysInfo.Caption) ($($sysInfo.Architecture))" -ForegroundColor Green
    Write-Host "  [OK] PowerShell $($PSVersionTable.PSVersion.ToString())" -ForegroundColor Green
    if ($wingetAvailable) {
        Write-Host "  [OK] winget $wingetVersion" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] winget is missing" -ForegroundColor Red
    }
    if ($hasNetwork) {
        Write-Host "  [OK] Internet Connection" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Internet Connection unavailable" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host ("{0,-20} {1,-14} {2,-14} {3,-12}" -f "Component", "Current", "Required", "Status") -ForegroundColor White
    Write-Host ("-" * 62) -ForegroundColor Gray

    foreach ($res in $pkgResults) {
        $curr = if ($res.CurrentVersion) { $res.CurrentVersion } else { "-" }
        $req = if ($res.MinimumVersion) { ">= " + $res.MinimumVersion } else { "installed" }
        $tag = Format-StatusTag -Status $res.Status
        $color = Format-StatusColor -Status $res.Status

        Write-Host ("{0,-20} {1,-14} {2,-14} " -f $res.Name, $curr, $req) -NoNewline
        Write-Host $tag -ForegroundColor $color
    }

    Write-Host ""
    Write-Host ("-" * 62) -ForegroundColor Gray
    Write-Host "Health: $passedChecks / $totalChecks checks passed" -ForegroundColor White
    Write-Host "Warnings: $warningChecks" -ForegroundColor Yellow
    Write-Host "Missing:  $missingChecks" -ForegroundColor Red
    Write-Host ""

    return $exitCode
}
