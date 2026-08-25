function Invoke-RustEnvironment {
 param([Parameter(Mandatory=$true)]$Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'Rust Environment'
 return (Invoke-EnvironmentPipeline -Config $Config -EnvironmentId 'rust' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde)
}
