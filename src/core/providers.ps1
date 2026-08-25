# ============================================================================
# DevSetup Core - Provider and Safe Archive Module
# ============================================================================

function Test-ArchiveEntrySafe {
    param([Parameter(Mandatory=$true)][string]$EntryName)
    if ([string]::IsNullOrWhiteSpace($EntryName)) { return $false }
    if ($EntryName -match '(^[\\/]|^[A-Za-z]:|(^|[\\/])\.\.([\\/]|$)|^\\\\)') { return $false }
    return $true
}

function Expand-DevSetupZipSafely {
    param(
        [Parameter(Mandatory=$true)][string]$ZipPath,
        [Parameter(Mandatory=$true)][string]$StagingDirectory
    )
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $root = [IO.Path]::GetFullPath($StagingDirectory).TrimEnd('\') + '\'
    $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach ($entry in $archive.Entries) {
            if (-not (Test-ArchiveEntrySafe $entry.FullName)) { throw "Unsafe ZIP entry rejected: $($entry.FullName)" }
            $destination = [IO.Path]::GetFullPath((Join-Path $StagingDirectory $entry.FullName))
            if (-not $destination.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw "ZIP entry escapes staging directory: $($entry.FullName)" }
            if ($entry.FullName.EndsWith('/')) { [IO.Directory]::CreateDirectory($destination) | Out-Null; continue }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
            $input = $entry.Open(); $output = [IO.File]::Open($destination, [IO.FileMode]::Create, [IO.FileAccess]::Write)
            try { $input.CopyTo($output) } finally { $output.Dispose(); $input.Dispose() }
        }
    } finally { $archive.Dispose() }
}

function Test-DevSetupSha256 {
    param([Parameter(Mandatory=$true)][string]$FilePath, [Parameter(Mandatory=$true)][string]$ExpectedHash)
    if ($ExpectedHash -notmatch '^[a-fA-F0-9]{64}$') { throw 'Expected SHA256 must be a 64-character hexadecimal value.' }
    return ((Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash -eq $ExpectedHash.ToUpperInvariant())
}

function Invoke-OfficialArchiveProvider {
    param([Parameter(Mandatory=$true)]$PackageDef, [switch]$DryRun)
    $p = $PackageDef.provider
    foreach ($key in @('vendor','version','downloadUrl','sha256','archiveType','extractDirectory')) {
        if (-not $p.$key) { return @{ Success=$false; Error="official-archive missing required property '$key'." } }
    }
    if ($p.downloadUrl -notmatch '^https://') { return @{ Success=$false; Error='official-archive requires HTTPS.' } }
    if ($p.version -notmatch '^\d+(\.\d+){0,3}$') { return @{ Success=$false; Error='official-archive requires a pinned numeric version.' } }
    if ($p.archiveType -ne 'zip') { return @{ Success=$false; Error='Only ZIP archives are currently supported.' } }
    if ($DryRun) { return @{ Success=$true; DryRun=$true } }
    return @{ Success=$false; Error='No verified official archive provider is configured for this package.' }
}
