$root=Split-Path $PSScriptRoot -Parent
function Get-WindowsVersionInfo { [pscustomobject]@{Caption='Windows';Architecture='x64'} }; function Test-IsWindows {$true}; function Test-WingetAvailable {$true}; function Get-WingetVersionString {'1.0'}; function Test-NetworkConnectivity {$true}; function Get-DevOpsDiagnostic {[pscustomobject]@{docker=[pscustomobject]@{status='READY'};wsl=[pscustomobject]@{status='READY'};virtualization=[pscustomobject]@{status='READY'}}}; function Write-DevSetupHeader {}; function Detect-PackageStatus { param($PackageDef) $PackageDef }
. "$root\src\commands\doctor.ps1"
Describe 'Doctor status and JSON contracts' {
 It 'returns 0 for healthy required checks' { (Get-DoctorExitCode @(@{Status='INSTALLED_OK';PackageDef=@{optional=$false}}) (Get-DevOpsDiagnostic))|Should Be 0 }
 It 'returns 1 for optional missing and warnings' { (Get-DoctorExitCode @(@{Status='OPTIONAL_MISSING';PackageDef=@{optional=$true}}) (Get-DevOpsDiagnostic))|Should Be 1 }
 It 'returns 2 for required missing or broken' { (Get-DoctorExitCode @(@{Status='MISSING';PackageDef=@{optional=$false}}) (Get-DevOpsDiagnostic))|Should Be 2;(Get-DoctorExitCode @(@{Status='BROKEN';PackageDef=@{optional=$false}}) (Get-DevOpsDiagnostic))|Should Be 2 }
 It 'emits valid JSON only when requested' { $config=[pscustomobject]@{Packages=[pscustomobject]@{git=[pscustomobject]@{Id='git';Name='Git';DisplayName='Git';Status='INSTALLED_OK';CurrentVersion='1';MinimumVersion='1';PackageDef=@{optional=$false}}}};$out=Invoke-DevSetupDoctor $config -Json 6>&1;$text=($out|Out-String);$text|ConvertFrom-Json|Should Not BeNullOrEmpty;$text|Should Not Match '\[OK\]|\[WARN\]|DevSetup Doctor' }
}
