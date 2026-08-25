function Test-TrustedWingetPackage {
    param($PackageDef)
    return $PackageDef -and
        $PackageDef.providerType -eq 'winget' -and
        $PackageDef.wingetId -match '^[A-Za-z0-9][A-Za-z0-9.-]+$' -and
        $PackageDef.id -match '^[A-Za-z0-9][A-Za-z0-9._-]+$'
}

function Invoke-TrustedElevatedPackageInstall {
    param($PackageDef, [scriptblock]$ElevatedRunner)

    if (-not (Test-TrustedWingetPackage $PackageDef)) {
        return @{ Success = $false; State = 'FAILED'; Error = 'Invalid elevated package request.' }
    }

    if ($ElevatedRunner) {
        $result = & $ElevatedRunner $PackageDef.wingetId @($PackageDef.installArgs)
    } else {
        $tempDirectory = Join-Path $env:TEMP ('DevSetupElevated-' + [guid]::NewGuid())
        $requestPath = Join-Path $tempDirectory 'request.json'
        $resultPath = Join-Path $tempDirectory 'result.json'
        try {
            New-Item -Path $tempDirectory -ItemType Directory -Force | Out-Null
            @{ packageId = $PackageDef.id; action = 'install' } |
                ConvertTo-Json -Compress | Set-Content -LiteralPath $requestPath -Encoding UTF8
            $helper = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'scripts\elevated-install.ps1'
            Start-Process powershell.exe -Verb RunAs -ArgumentList @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $helper,
                '-RequestPath', $requestPath, '-ResultPath', $resultPath
            ) -Wait -PassThru -ErrorAction Stop | Out-Null
            if (-not (Test-Path -LiteralPath $resultPath)) {
                return @{ Success = $false; State = 'UAC_DENIED'; Skipped = $true }
            }
            $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
            if ($result.packageId -ne $PackageDef.id -or
                $result.status -notin @('SUCCESS', 'FAILED') -or
                $null -eq $result.success) {
                return @{ Success = $false; State = 'FAILED'; Error = 'Malformed elevated result.' }
            }
        } catch {
            return @{ Success = $false; State = 'UAC_DENIED'; Skipped = $true }
        } finally {
            Remove-Item -LiteralPath $tempDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if ($result.Denied) { return @{ Success = $false; State = 'UAC_DENIED'; Skipped = $true } }
    if ($result.Success) {
        Refresh-ProcessEnvironment
        return @{ Success = $true; State = 'SUCCESS' }
    }
    return @{ Success = $false; State = 'FAILED'; Error = $result.Error }
}

function Create-InstallationPlan {
    param([array]$DetectionResults, [switch]$NoIde)
    foreach ($result in $DetectionResults) {
        $package = $result.PackageDef
        $action = switch ($result.Status) {
            'INSTALLED_OK' { 'KEEP' }
            'OUTDATED' { 'UPGRADE' }
            'MISSING' { 'INSTALL' }
            'OPTIONAL_MISSING' { 'INSTALL' }
            'PARTIAL' { 'INSTALL' }
            default { 'SKIP' }
        }
        if ($result.Status -eq 'MANUAL_REQUIRED' -or $package.providerType -eq 'manual') { $action = 'SKIP' }
        if ($NoIde -and $package.optional) { $action = 'SKIP' }
        @{ Id = $package.id; DisplayName = $package.displayName; Action = $action; PackageDef = $package; Reason = $package.manualGuidance }
    }
}

function Execute-InstallationPlan {
    param([array]$PlanItems, [switch]$DryRun, [switch]$Yes, [scriptblock]$DecisionProvider, [scriptblock]$ElevatedRunner)
    if ($DryRun) { return @{ Success = $true; DryRun = $true; ExitCode = 0; States = @() } }
    $states = @()
    foreach ($item in $PlanItems) {
        if ($item.Action -eq 'KEEP') { $states += @{ Id = $item.Id; State = 'KEEP' }; continue }
        if ($item.Action -eq 'SKIP') { $states += @{ Id = $item.Id; State = 'MANUAL_REQUIRED' }; continue }
        $package = $item.PackageDef
        if ($package.requiresAdmin) {
            $elevated = Invoke-TrustedElevatedPackageInstall $package $ElevatedRunner
            $states += @{ Id = $item.Id; State = $elevated.State }
            if ($elevated.State -eq 'UAC_DENIED') { continue }
            if (-not $elevated.Success) { return @{ Success = $false; ExitCode = 3; States = $states } }
            continue
        }
        $complete = $false
        while (-not $complete) {
            $run = if ($item.Action -eq 'UPGRADE') { Upgrade-WingetPackage $package.wingetId } else { Install-WingetPackage $package.wingetId @($package.installArgs) }
            if ($run.Success) { Refresh-ProcessEnvironment; $states += @{ Id = $item.Id; State = 'SUCCESS' }; $complete = $true; continue }
            $failureState = if ($run.ExitCode -eq -1) { 'TIMEOUT' } else { 'FAILED' }
            $choice = if ($Yes) { 'S' } elseif ($DecisionProvider) { & $DecisionProvider $item $failureState } else { Read-Host "Failed $($item.DisplayName). [R]etry [S]kip [A]bort [C]ancel" }
            switch ($choice.ToUpperInvariant()) {
                'R' { $states += @{ Id = $item.Id; State = 'RETRY' } }
                'S' { $states += @{ Id = $item.Id; State = 'SKIP' }; $complete = $true }
                'A' { $states += @{ Id = $item.Id; State = 'ABORT' }; return @{ Success = $false; ExitCode = 5; States = $states } }
                'C' { $states += @{ Id = $item.Id; State = 'CANCEL' }; return @{ Success = $false; ExitCode = 5; States = $states } }
                default { $states += @{ Id = $item.Id; State = 'SKIP' }; $complete = $true }
            }
        }
    }
    return @{ Success = $true; ExitCode = 0; States = $states }
}
