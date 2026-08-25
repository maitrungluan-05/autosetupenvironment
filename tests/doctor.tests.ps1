$root=Split-Path $PSScriptRoot -Parent
function Get-WindowsVersionInfo { [pscustomobject]@{Caption='Windows';Architecture='x64'} }
function Test-IsWindows {$true}
function Test-WingetAvailable {$true}
function Get-WingetVersionString {'1.0'}
function Test-NetworkConnectivity {$true}
function Get-DevOpsDiagnostic {
    [pscustomobject]@{
        docker=[pscustomobject]@{status='READY'}
        wsl=[pscustomobject]@{
            status='READY'
            installed=$true
            commandAvailable=$true
            wsl2Available=$true
            distributions=@('Ubuntu-22.04    Stopped    2')
            distributionDetails=@([pscustomobject]@{name='Ubuntu-22.04';state='Stopped';version=2;default=$true})
        }
        virtualization=[pscustomobject]@{status='READY';supported=$true;enabled=$true}
    }
}
function Write-DevSetupHeader {}
function Detect-PackageStatus { param($PackageDef) $PackageDef }
. "$root\src\commands\doctor.ps1"
function New-TestConfig {
    [pscustomobject]@{Packages=[pscustomobject]@{git=[pscustomobject]@{Id='git';Name='Git';DisplayName='Git';Status='INSTALLED_OK';CurrentVersion='1';MinimumVersion='1';PackageDef=@{optional=$false}}}}
}
# Helper to capture Console.Out (used for JSON mode which writes via [Console]::Out.WriteLine)
function Invoke-DoctorCaptureJson {
    param($Config)
    $sw = New-Object System.IO.StringWriter
    $prev = [Console]::Out
    [Console]::SetOut($sw)
    try { [void](Invoke-DevSetupDoctor $Config -Json) } finally { [Console]::SetOut($prev) }
    return $sw.ToString()
}
Describe 'Doctor status and JSON contracts' {
 It 'returns 0 for healthy required checks' {
    (Get-DoctorExitCode @(@{Status='INSTALLED_OK';PackageDef=@{optional=$false}}) (Get-DevOpsDiagnostic)) | Should Be 0
 }
 It 'returns 1 for optional missing and warnings' {
    (Get-DoctorExitCode @(@{Status='OPTIONAL_MISSING';PackageDef=@{optional=$true}}) (Get-DevOpsDiagnostic)) | Should Be 1
 }
 It 'returns 2 for required missing or broken' {
    (Get-DoctorExitCode @(@{Status='MISSING';PackageDef=@{optional=$false}}) (Get-DevOpsDiagnostic)) | Should Be 2
    (Get-DoctorExitCode @(@{Status='BROKEN';PackageDef=@{optional=$false}}) (Get-DevOpsDiagnostic)) | Should Be 2
 }
 It 'emits valid JSON only when requested (no text decorations in output)' {
    $text = Invoke-DoctorCaptureJson (New-TestConfig)
    $parsed = $text | ConvertFrom-Json
    ($null -ne $parsed) | Should Be $true
    $text | Should Not Match '\[OK\]|\[WARN\]|DevSetup Doctor'
 }
 It 'JSON stdout contains no NUL characters' {
    $text = Invoke-DoctorCaptureJson (New-TestConfig)
    ($text.IndexOf([char]0)) | Should Be -1
 }
 It 'JSON wsl.distributions is string array with clean text (backward compat)' {
    $text = Invoke-DoctorCaptureJson (New-TestConfig)
    $text | Should Match '"distributions"'
    $text | Should Match 'Ubuntu-22.04'
    # Verify no NUL in the distributions string
    ($text.IndexOf([char]0)) | Should Be -1
 }
 It 'JSON wsl.distributionDetails is structured object array' {
    $text = Invoke-DoctorCaptureJson (New-TestConfig)
    $text | Should Match '"distributionDetails"'
    $text | Should Match '"name"'
    $text | Should Match '"state"'
    $text | Should Match '"version"'
 }
 It 'JSON wsl2Available is true' {
    $text = Invoke-DoctorCaptureJson (New-TestConfig)
    $text | Should Match '"wsl2Available"'
    # wsl2Available must be true (not null, not false)
    $parsed = $text | ConvertFrom-Json
    ($null -ne $parsed.environments.devops.wsl.wsl2Available) | Should Be $true
 }
}
