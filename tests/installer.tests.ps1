$root = Split-Path $PSScriptRoot -Parent
function Refresh-ProcessEnvironment {}
. "$root\src\core\installer.ps1"

Describe 'Installer state machine and trusted elevation' {
    BeforeEach {
        $script:calls = @()
        function Install-WingetPackage { param($id, $args) $script:calls += $id; @{ Success = $true; ExitCode = 0 } }
        function Upgrade-WingetPackage { param($id) Install-WingetPackage $id @() }
    }
    It 'retries only the failed package' {
        $script:attempt = 0; function Install-WingetPackage { param($id, $args) $script:calls += $id; $script:attempt++; @{ Success = ($script:attempt -ne 2); ExitCode = 1 } }
        $plan = @(@{ Id='A'; Action='INSTALL'; PackageDef=@{ wingetId='A' } }, @{ Id='B'; Action='INSTALL'; PackageDef=@{ wingetId='B' } }, @{ Id='C'; Action='INSTALL'; PackageDef=@{ wingetId='C' } })
        $r = Execute-InstallationPlan $plan -DecisionProvider { param($item, $state) 'R' }
        $r.Success | Should Be $true; ($script:calls | Where-Object { $_ -eq 'B' }).Count | Should Be 2
    }
    It 'supports SKIP, ABORT, and CANCEL' {
        $script:attempt = 0; function Install-WingetPackage { param($id, $args) $script:attempt++; @{ Success=$false; ExitCode=1 } }
        $plan = @(@{ Id='A'; Action='INSTALL'; PackageDef=@{ wingetId='A' } })
        (Execute-InstallationPlan $plan -DecisionProvider { 'S' }).States[0].State | Should Be 'SKIP'
        (Execute-InstallationPlan $plan -DecisionProvider { 'A' }).States[0].State | Should Be 'ABORT'
        (Execute-InstallationPlan $plan -DecisionProvider { 'C' }).States[0].State | Should Be 'CANCEL'
    }
    It 'reports TIMEOUT before decision' {
        function Install-WingetPackage { param($id, $args) @{ Success=$false; ExitCode=-1 } }
        $seen = $null; $plan = @(@{ Id='A'; Action='INSTALL'; PackageDef=@{ wingetId='A' } })
        Execute-InstallationPlan $plan -DecisionProvider { param($item, $state) $script:seen=$state; 'S' } | Out-Null
        $script:seen | Should Be 'TIMEOUT'
    }
    It 'never calls Winget for MANUAL_REQUIRED' {
        function Install-WingetPackage { throw 'Winget must not be called' }
        $plan = Create-InstallationPlan @([pscustomobject]@{ Status='MANUAL_REQUIRED'; PackageDef=[pscustomobject]@{ id='manual'; displayName='Manual'; providerType='manual'; manualGuidance='Do it' } })
        (Execute-InstallationPlan $plan).States[0].State | Should Be 'MANUAL_REQUIRED'
    }
    It 'handles elevated success, failure, denied, and malformed results without UAC' {
        $package = @{ id='VS'; wingetId='Microsoft.VisualStudio.2022.BuildTools'; providerType='winget'; requiresAdmin=$true; installArgs=@() }
        (Invoke-TrustedElevatedPackageInstall $package { param($id,$args) @{ Success=$true } }).State | Should Be 'SUCCESS'
        (Invoke-TrustedElevatedPackageInstall $package { param($id,$args) @{ Success=$false; Error='fail' } }).State | Should Be 'FAILED'
        (Invoke-TrustedElevatedPackageInstall $package { param($id,$args) @{ Success=$false; Denied=$true } }).State | Should Be 'UAC_DENIED'
        (Invoke-TrustedElevatedPackageInstall $package { param($id,$args) @{ unexpected=$true } }).State | Should Be 'FAILED'
    }
}
