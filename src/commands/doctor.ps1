# DevSetup Commands - Doctor Handler
function Get-DoctorExitCode {
    param([array]$PackageResults, $DevOpsDiagnostic)
    $requiredFailure = @($PackageResults | Where-Object {
        -not $_.PackageDef.optional -and $_.Status -in @('MISSING', 'BROKEN', 'PARTIAL', 'OUTDATED')
    }).Count -gt 0
    if ($requiredFailure) { return 2 }
    $warning = @($PackageResults | Where-Object { $_.Status -ne 'INSTALLED_OK' }).Count -gt 0
    if ($DevOpsDiagnostic -and @($DevOpsDiagnostic.docker, $DevOpsDiagnostic.wsl, $DevOpsDiagnostic.virtualization | Where-Object { $_.status -notin @('READY', 'MISSING') }).Count -gt 0) { $warning = $true }
    if ($warning) { return 1 }
    return 0
}

function Invoke-DevSetupDoctor {
    param([Parameter(Mandatory=$true)]$Config,[switch]$Json,[switch]$VerboseMode)
    $sysInfo = Get-WindowsVersionInfo; $isWin = Test-IsWindows
    $networkReachable = Test-NetworkConnectivity
    $systemChecks = [ordered]@{ Windows=$isWin; WindowsVersion=$sysInfo.Caption; Architecture=$sysInfo.Architecture; PowerShellVersion=$PSVersionTable.PSVersion.ToString(); Winget=(Test-WingetAvailable); WingetVersion=(Get-WingetVersionString); Network=$networkReachable }
    $packageResults = @(); foreach ($pkgKey in $Config.Packages.psobject.Properties.Name) { $packageResults += Detect-PackageStatus -PackageDef $Config.Packages.$pkgKey }
    $devOps = Get-DevOpsDiagnostic
    $exitCode = Get-DoctorExitCode $packageResults $devOps
    $healthy = $exitCode -eq 0
    $warningChecks = @($packageResults | Where-Object { $_.Status -ne 'INSTALLED_OK' }).Count
    $requiredFailures = @($packageResults | Where-Object { -not $_.PackageDef.optional -and $_.Status -in @('MISSING','BROKEN','PARTIAL','OUTDATED') }).Count
    $environmentData = [ordered]@{}
    foreach ($result in $packageResults) { $environmentData[$result.Id] = [ordered]@{ name=$result.Name; displayName=$result.DisplayName; status=$result.Status; currentVersion=$result.CurrentVersion; minimumVersion=$result.MinimumVersion; optional=[bool]$result.PackageDef.optional } }
    $environmentData['devops'] = [ordered]@{ docker=$devOps.docker; wsl=$devOps.wsl; virtualization=$devOps.virtualization }
    $document = [ordered]@{ healthy=$healthy; exitCode=$exitCode; system=$systemChecks; environments=$environmentData; summary=[ordered]@{ totalChecks=$packageResults.Count; warnings=$warningChecks; requiredFailures=$requiredFailures } }
    if ($Json) { [Console]::Out.WriteLine(($document | ConvertTo-Json -Depth 8)); return $exitCode }
    Write-DevSetupHeader -Title 'DLD Luan Dev Doctor'
    Write-Host 'System' -ForegroundColor White
    Write-Host "  [OK] $($sysInfo.Caption) ($($sysInfo.Architecture))" -ForegroundColor Green
    $netTag = if ($networkReachable -eq $true) { '[OK]' } elseif ($networkReachable -eq $false) { '[WARN]' } else { '[INFO]' }
    $netLabel = if ($networkReachable -eq $true) { 'Network reachable' } elseif ($networkReachable -eq $false) { 'Network unreachable' } else { 'Network status unknown' }
    Write-Host "  $netTag $netLabel" -ForegroundColor $(if ($networkReachable -eq $true) { 'Green' } elseif ($networkReachable -eq $false) { 'Yellow' } else { 'Gray' })
    Write-Host 'WSL' -ForegroundColor White
    $wsl = $devOps.wsl
    if ($wsl.status -eq 'MISSING') {
        Write-Host '  [SKIP] WSL not installed' -ForegroundColor Gray
    } else {
        Write-Host '  [OK] WSL installed' -ForegroundColor Green
        if ($wsl.wsl2Available -eq $true) {
            Write-Host '  [OK] WSL 2 available' -ForegroundColor Green
        } elseif ($wsl.wsl2Available -eq $false) {
            Write-Host '  [WARN] WSL 2 not available' -ForegroundColor Yellow
        } else {
            Write-Host '  [INFO] WSL 2 availability unknown' -ForegroundColor Gray
        }
        foreach ($d in @($wsl.distributionDetails)) {
            $ver = if ($null -ne $d.version) { "WSL $($d.version)" } else { 'WSL ?' }
            $defMark = if ($d.default) { ' (default)' } else { '' }
            Write-Host "  [INFO] $($d.name) - $($d.state) - $ver$defMark" -ForegroundColor Gray
        }
        if (@($wsl.distributionDetails).Count -eq 0) {
            Write-Host '  [INFO] No distributions installed' -ForegroundColor Gray
        }
    }
    Write-Host 'Docker' -ForegroundColor White
    $docker = $devOps.docker
    $dockerTag = if ($docker.status -eq 'READY') { '[OK]' } elseif ($docker.status -eq 'MISSING') { '[SKIP]' } else { '[WARN]' }
    Write-Host "  $dockerTag Docker $($docker.status)" -ForegroundColor $(if ($docker.status -eq 'READY') { 'Green' } elseif ($docker.status -eq 'MISSING') { 'Gray' } else { 'Yellow' })
    Write-Host 'Virtualization' -ForegroundColor White
    $virt = $devOps.virtualization
    $virtTag = if ($virt.status -eq 'READY') { '[OK]' } elseif ($virt.status -eq 'UNSUPPORTED') { '[WARN]' } elseif ($virt.status -eq 'UNKNOWN') { '[INFO]' } else { '[WARN]' }
    Write-Host "  $virtTag Virtualization $($virt.status)" -ForegroundColor $(if ($virt.status -eq 'READY') { 'Green' } elseif ($virt.status -eq 'UNSUPPORTED') { 'Yellow' } else { 'Gray' })
    Write-Host 'Cloud CLI' -ForegroundColor White
    foreach ($id in @('aws_cli','azure_cli')) { $r=$packageResults | Where-Object Id -eq $id | Select-Object -First 1; $tag=if($r.Status -eq 'INSTALLED_OK'){'[OK]'}else{'[SKIP]'}; Write-Host "  $tag $($r.DisplayName) optional" }
    Write-Host "Health: $($document.summary.totalChecks) checks; required failures: $requiredFailures" -ForegroundColor White
    return $exitCode
}
