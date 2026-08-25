function Get-DevOpsResolvedPackageIds {
    param($Config, [string[]]$CloudPackageIds = @())
    $definition = Get-EnvironmentDefinition $Config 'devops'
    $requested = @($definition.packages | Where-Object { $_ -notin @('aws_cli', 'azure_cli') })
    if ($CloudPackageIds) { $requested += @($CloudPackageIds) }
    return @(Resolve-DevSetupPackages -Config $Config -PackageIds $requested | Select-Object -Unique)
}

function Select-DevOpsCloudPackages {
    param([switch]$Yes)
    if ($Yes) { return @() }
    Write-Host 'Optional cloud tools:'
    Write-Host '[1] AWS CLI'
    Write-Host '[2] Azure CLI'
    Write-Host '[3] Both'
    Write-Host '[4] Skip'
    switch (Read-Host 'Select') {
        '1' { return @('aws_cli') }
        '2' { return @('azure_cli') }
        '3' { return @('aws_cli', 'azure_cli') }
        default { return @() }
    }
}

function Get-DockerDiagnostic {
    $command = Get-Command docker.exe -ErrorAction SilentlyContinue
    $desktopPaths = @(
        (Join-Path ${env:ProgramFiles} 'Docker\Docker\Docker Desktop.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Docker\Docker\Docker Desktop.exe')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    $cliVersion = $null; $daemonReachable = $null
    if ($command) {
        $versionResult = Invoke-DevSetupProcess $command.Source @('--version') 8
        if ($versionResult.Success) { $cliVersion = Extract-VersionString "$($versionResult.StdOut)`n$($versionResult.StdErr)" }
        $daemonResult = Invoke-DevSetupProcess $command.Source @('version', '--format', '{{.Server.Version}}') 8
        $daemonReachable = [bool]$daemonResult.Success
    }
    $installed = [bool]$command -or $desktopPaths.Count -gt 0
    $status = if (-not $installed) { 'MISSING' } elseif (-not $command) { 'INSTALLED_NOT_RUNNING' } elseif ($daemonReachable) { 'READY' } elseif ($null -eq $daemonReachable) { 'UNKNOWN' } else { 'INSTALLED_NOT_RUNNING' }
    [pscustomobject]@{ installed=$installed; cliAvailable=[bool]$command; daemonReachable=$daemonReachable; version=$cliVersion; desktopPath=@($desktopPaths)[0]; status=$status }
}

function Get-WslDiagnostic {
    $command = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $command) { return [pscustomobject]@{ installed=$false; commandAvailable=$false; version=$null; defaultVersion=$null; wsl2Available=$null; distributions=@(); status='MISSING' } }
    $statusResult = Invoke-DevSetupProcess $command.Source @('--status') 8
    $versionResult = Invoke-DevSetupProcess $command.Source @('--version') 8
    $listResult = Invoke-DevSetupProcess $command.Source @('-l', '-v') 8
    $raw = "$($statusResult.StdOut)`n$($statusResult.StdErr)`n$($versionResult.StdOut)`n$($versionResult.StdErr)"
    $defaultVersion = if ($raw -match '(?im)Default Version:\s*(\d+)') { $Matches[1] } else { $null }
    $distributions = @($listResult.StdOut -split "`r?`n" | Where-Object { $_ -match '\S' } | Select-Object -Skip 1)
    $wsl2Available = if ($defaultVersion -eq '2' -or $distributions -match '\s2\s*$') { $true } elseif ($statusResult.Success -or $versionResult.Success) { $false } else { $null }
    $state = if ($statusResult.Success -or $versionResult.Success -or $listResult.Success) { if ($wsl2Available) { 'READY' } else { 'INSTALLED_NOT_RUNNING' } } else { 'UNKNOWN' }
    [pscustomobject]@{ installed=$true; commandAvailable=$true; version=(Extract-VersionString "$($versionResult.StdOut)`n$($versionResult.StdErr)"); defaultVersion=$defaultVersion; wsl2Available=$wsl2Available; distributions=$distributions; status=$state }
}

function Get-VirtualizationDiagnostic {
    try {
        $processor = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $enabled = [bool]$processor.VirtualizationFirmwareEnabled
        $supported = [bool]$processor.VMMonitorModeExtensions
        $status = if ($enabled) { 'READY' } elseif ($supported) { 'INSTALLED_NOT_RUNNING' } else { 'UNKNOWN' }
        return [pscustomobject]@{ supported=$supported; enabled=$enabled; status=$status }
    } catch { return [pscustomobject]@{ supported=$null; enabled=$null; status='UNKNOWN' } }
}

function Get-DevOpsDiagnostic {
    [pscustomobject]@{ docker=Get-DockerDiagnostic; wsl=Get-WslDiagnostic; virtualization=Get-VirtualizationDiagnostic }
}

function Invoke-DevOpsEnvironment {
    param($Config, [switch]$DryRun, [switch]$Yes, [switch]$VerboseMode, [switch]$NoIde)
    Write-DevSetupHeader -Title 'DevOps Environment'
    $diagnostic = Get-DevOpsDiagnostic
    Write-Host "Docker: $($diagnostic.docker.status)" -ForegroundColor Gray
    Write-Host "WSL: $($diagnostic.wsl.status)" -ForegroundColor Gray
    $cloud = Select-DevOpsCloudPackages -Yes:($Yes -or $DryRun)
    $packageIds = Get-DevOpsResolvedPackageIds $Config $cloud
    return Invoke-EnvironmentPipeline $Config 'devops' -PackageIds $packageIds -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde
}
