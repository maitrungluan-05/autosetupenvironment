# ============================================================================
# DevSetup Core - Verification Module
# ============================================================================

function Verify-Package {
    param(
        [Parameter(Mandatory=$true)]$PackageDef
    )

    Refresh-ProcessEnvironment

    $id = $PackageDef.id
    $name = $PackageDef.name
    $displayName = $PackageDef.displayName
    $executables = $PackageDef.executables
    $verifyCmds = $PackageDef.verificationCommands

    $results = @()
    $allOk = $true

    foreach ($exe in $executables) {
        $found = Test-ExecutableExists -ExecutableName $exe
        if (-not $found) {
            $allOk = $false
            $results += @{
                Command = $exe
                Success = $false
                Output = "Executable not found in PATH"
            }
        }
    }

    if ($verifyCmds -and $verifyCmds.Count -gt 0) {
        foreach ($cmdStr in $verifyCmds) {
            $parts = $cmdStr.Split(' ', 2)
            $exeName = $parts[0]
            $cmdArgs = if ($parts.Count -gt 1) { $parts[1].Split(' ') } else { @() }

            $proc = Invoke-DevSetupProcess -FilePath $exeName -ArgumentList $cmdArgs -TimeoutSeconds 10
            $combined = "$($proc.StdOut)`n$($proc.StdErr)".Trim()
            $firstLine = if ($combined) { ($combined -split "`n")[0] } else { "Command executed" }

            if ($proc.Success) {
                $results += @{
                    Command = $cmdStr
                    Success = $true
                    Output = $firstLine
                }
            } else {
                $allOk = $false
                $results += @{
                    Command = $cmdStr
                    Success = $false
                    Output = $firstLine
                }
            }
        }
    }

    return @{
        Id = $id
        Name = $name
        DisplayName = $displayName
        Success = $allOk
        Details = $results
    }
}

function Display-VerificationReport {
    param(
        [Parameter(Mandatory=$true)][array]$VerificationResults,
        [string]$EnvironmentName = "Environment"
    )

    Write-Host ""
    Write-Host "Verification:" -ForegroundColor White
    Write-Host ""

    $overallSuccess = $true

    foreach ($vRes in $VerificationResults) {
        if (-not $vRes.Details -or $vRes.Details.Count -eq 0) {
            if ($vRes.Success) {
                Write-Host "  [OK] $($vRes.DisplayName)" -ForegroundColor Green
            } else {
                Write-Host "  [FAIL] $($vRes.DisplayName)" -ForegroundColor Red
                $overallSuccess = $false
            }
            continue
        }

        foreach ($det in $vRes.Details) {
            if ($det.Success) {
                Write-Host "  [OK] $($det.Command)" -ForegroundColor Green
                if ($det.Output) {
                    Write-Host "       $($det.Output)" -ForegroundColor Gray
                }
            } else {
                Write-Host "  [FAIL] $($det.Command)" -ForegroundColor Red
                if ($det.Output) {
                    Write-Host "         $($det.Output)" -ForegroundColor Red
                }
                $overallSuccess = $false
            }
        }
    }

    Write-Host ""
    if ($overallSuccess) {
        Write-Host "$EnvironmentName environment is ready." -ForegroundColor Green
    } else {
        Write-Host "$EnvironmentName environment completed with warnings." -ForegroundColor Yellow
    }
    Write-Host ""

    return $overallSuccess
}
