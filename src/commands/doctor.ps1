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
    $systemChecks = [ordered]@{ Windows=$isWin; WindowsVersion=$sysInfo.Caption; Architecture=$sysInfo.Architecture; PowerShellVersion=$PSVersionTable.PSVersion.ToString(); Winget=(Test-WingetAvailable); WingetVersion=(Get-WingetVersionString); Network=(Test-NetworkConnectivity) }
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
    Write-Host 'DevOps' -ForegroundColor White
    foreach ($name in @('docker','wsl','virtualization')) { $d=$devOps.$name; $label=$name.Substring(0,1).ToUpper()+$name.Substring(1); $tag=if($d.status -eq 'READY'){'[OK]'}elseif($d.status -eq 'MISSING'){'[SKIP]'}else{'[WARN]'}; Write-Host "  $tag $label $($d.status)" }
    Write-Host 'Cloud CLI' -ForegroundColor White
    foreach ($id in @('aws_cli','azure_cli')) { $r=$packageResults | Where-Object Id -eq $id | Select-Object -First 1; $tag=if($r.Status -eq 'INSTALLED_OK'){'[OK]'}else{'[SKIP]'}; Write-Host "  $tag $($r.DisplayName) optional" }
    Write-Host "Health: $($document.summary.totalChecks) checks; required failures: $requiredFailures" -ForegroundColor White
    return $exitCode
}
