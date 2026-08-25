# Shared release transaction primitives
function Test-ReleaseMetadata {
    param($Metadata)
    if (-not $Metadata -or $Metadata.downloadUrl -notmatch '^https://') { throw 'Pinned HTTPS release URL required.' }
    if ($Metadata.sha256 -notmatch '^[A-Fa-f0-9]{64}$') { throw 'Pinned SHA256 required.' }
}
function Test-ReleaseRuntime { param([string]$Directory) return (Test-Path (Join-Path $Directory 'devsetup.ps1')) -and (Test-Path (Join-Path $Directory 'src\main.ps1')) }
function Test-DevSetupReleaseArchive {
    param([string]$ZipPath, [string]$ExpectedHash)
    if (-not (Test-Path -LiteralPath $ZipPath)) { throw 'Downloaded release archive is missing.' }
    if (-not (Test-DevSetupSha256 $ZipPath $ExpectedHash)) { throw 'Release archive checksum mismatch.' }
    $stage = Join-Path $env:TEMP ('DevSetup-stage-' + [guid]::NewGuid())
    try {
        New-Item -Path $stage -ItemType Directory -Force | Out-Null
        Expand-DevSetupZipSafely $ZipPath $stage
        if (-not (Test-ReleaseRuntime $stage)) { throw 'Staged release is missing required runtime files.' }
        return $stage
    } catch {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
        throw
    }
}
function Invoke-ReleaseActivation {
    param([string]$Stage, [string]$Active, [scriptblock]$Verify = { param($p) Test-ReleaseRuntime $p }, [switch]$SimulateSwapFailure)
    $parent = Split-Path $Active -Parent; $backup = Join-Path $parent ('.backup-' + [guid]::NewGuid()); $moved = $false
    try {
        if (-not (& $Verify $Stage)) { throw 'Staging validation failed.' }
        if (Test-Path $Active) { Move-Item $Active $backup -Force; $moved = $true }
        if ($SimulateSwapFailure) { throw 'Simulated activation failure.' }
        Move-Item $Stage $Active -Force
        if (-not (& $Verify $Active)) { throw 'Post-swap validation failed.' }
        if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
        return @{ Success = $true }
    } catch {
        if ($moved -and (Test-Path $Active)) { Remove-Item $Active -Recurse -Force -ErrorAction SilentlyContinue }
        if ($moved -and (Test-Path $backup)) { Move-Item $backup $Active -Force }
        return @{ Success = $false; Error = $_.Exception.Message; RolledBack = $moved }
    }
}
