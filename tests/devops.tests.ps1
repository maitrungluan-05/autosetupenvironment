$root=Split-Path $PSScriptRoot -Parent
. "$root\src\core\dependencies.ps1"
. "$root\src\environments\devops.ps1"
Describe 'DevOps cloud plan integration' {
 BeforeEach { $script:config=[pscustomobject]@{ Environments=[pscustomobject]@{devops=[pscustomobject]@{packages=@('git','aws_cli','azure_cli')}}; Packages=[pscustomobject]@{} }; function Get-EnvironmentDefinition { param($Config,$EnvironmentId) $Config.Environments.devops }; function Resolve-DevSetupPackages { param($Config,$PackageIds) @($PackageIds | Select-Object -Unique) } }
 It 'skip includes neither cloud package' { $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @();($ids -contains 'aws_cli')|Should Be $false;($ids -contains 'azure_cli')|Should Be $false }
 It 'AWS includes only AWS' { $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @('aws_cli');($ids -contains 'aws_cli')|Should Be $true;($ids -contains 'azure_cli')|Should Be $false }
 It 'Azure includes only Azure' { $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @('azure_cli');($ids -contains 'azure_cli')|Should Be $true;($ids -contains 'aws_cli')|Should Be $false }
 It 'both includes both without duplicates' { $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @('aws_cli','azure_cli','git');($ids|Group-Object|? Count -gt 1).Count|Should Be 0;($ids -contains 'aws_cli')|Should Be $true;($ids -contains 'azure_cli')|Should Be $true }
 It 'yes defaults to skip' { @(Select-DevOpsCloudPackages -Yes).Count|Should Be 0 }
}
