function Invoke-CppEnvironment {
 param([Parameter(Mandatory=$true)]$Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'C/C++ Environment'
 return (Invoke-EnvironmentPipeline -Config $Config -EnvironmentId 'cpp' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde)
}
