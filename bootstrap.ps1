param(
    [string]$Version = '0.9.0-rc.2',
    [string]$RepoUrl = 'https://github.com/maitrungluan-05/autosetupenvironment',
    [string]$CustomZipUrl,
    [string]$CustomSha256Url
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'DLD Luan Dev supports Windows only.' }
if ($RepoUrl -ne 'https://github.com/maitrungluan-05/autosetupenvironment') { throw 'Bootstrap only trusts the official DLD Luan Dev repository.' }
$artifactName = "DLD-Luan-Dev-v$Version.zip"
$releaseBase = "$RepoUrl/releases/download/v$Version/$artifactName"
$zipUrl = if ($CustomZipUrl) { $CustomZipUrl } else { $releaseBase }
$shaUrl = if ($CustomSha256Url) { $CustomSha256Url } else { "$releaseBase.sha256" }
foreach ($url in @($zipUrl, $shaUrl)) { if ($url -notmatch '^https://') { throw 'Bootstrap downloads must use HTTPS.' } }
$install = Join-Path $env:LOCALAPPDATA 'DevSetup' # Compatibility location retained for RC.1 users.
$work = Join-Path $env:TEMP ('DLD-Luan-Dev-' + [guid]::NewGuid())
$stage = Join-Path $work 'stage'; $backup = Join-Path $work 'backup'; $zip = Join-Path $work $artifactName; $manifest = "$zip.sha256"
function Test-BootstrapArchiveEntry { param([string]$Name) return $Name -and $Name -notmatch '(^[\\/]|^[A-Za-z]:|(^|[\\/])\.\.([\\/]|$)|^\\\\)' }
function Expand-BootstrapZipSafely {
    param([string]$ZipPath, [string]$Destination)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $root = [IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'; $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try { foreach ($entry in $archive.Entries) {
        if (-not (Test-BootstrapArchiveEntry $entry.FullName)) { throw "Unsafe ZIP entry: $($entry.FullName)" }
        $target = [IO.Path]::GetFullPath((Join-Path $Destination $entry.FullName))
        if (-not $target.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw "ZIP entry escapes staging: $($entry.FullName)" }
        if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) { [IO.Directory]::CreateDirectory($target) | Out-Null; continue }
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null; $input=$entry.Open();$output=[IO.File]::Open($target,[IO.FileMode]::Create)
        try { $input.CopyTo($output) } finally { $output.Dispose(); $input.Dispose() }
    }} finally { $archive.Dispose() }
}
try {
    New-Item -Path $stage -ItemType Directory -Force | Out-Null
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
    Invoke-WebRequest -Uri $shaUrl -OutFile $manifest -UseBasicParsing
    $expected = (Get-Content -LiteralPath $manifest -Raw).Trim().Split(' ')[0]
    if ($expected -notmatch '^[A-Fa-f0-9]{64}$') { throw 'Invalid SHA256 manifest.' }
    if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $expected.ToUpperInvariant()) { throw 'SHA256 checksum mismatch; installation aborted.' }
    Expand-BootstrapZipSafely $zip $stage
    foreach ($required in @('devsetup.ps1','dlddev.cmd','devsetup.cmd','src\main.ps1','config\defaults.json','config\environments.json')) { if (-not (Test-Path -LiteralPath (Join-Path $stage $required))) { throw "Release archive is missing required runtime file: $required" } }
    if (Test-Path $install) { Move-Item -LiteralPath $install -Destination $backup -Force }
    try { Move-Item -LiteralPath $stage -Destination $install -Force } catch { if (Test-Path $backup) { Move-Item -LiteralPath $backup -Destination $install -Force }; throw }
    if (Test-Path $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
    $userPath = [Environment]::GetEnvironmentVariable('PATH','User'); if (($userPath -split ';' | ForEach-Object { $_.TrimEnd('\') }) -notcontains $install.TrimEnd('\')) { [Environment]::SetEnvironmentVariable('PATH', ($userPath.TrimEnd(';') + ';' + $install), 'User'); $env:PATH += ';' + $install }
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '         DLD Luan Dev Installed' -ForegroundColor Yellow
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host 'Installation completed successfully.' -ForegroundColor Green
    Write-Host 'Open a new PowerShell window and run:'; Write-Host '    dlddev' -ForegroundColor Cyan
    Write-Host ''; Write-Host 'Useful commands:'; Write-Host '    dlddev doctor'; Write-Host '    dlddev java -DryRun'; Write-Host '    dlddev web -DryRun'; Write-Host '    dlddev help'
} catch {
    if (-not (Test-Path $install) -and (Test-Path $backup)) { Move-Item -LiteralPath $backup -Destination $install -Force }
    Write-Error $_; exit 4
} finally { if (Test-Path $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } }
