function Invoke-WebEnvironment {
 param([Parameter(Mandatory=$true)]$Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'Web Development'
 return (Invoke-EnvironmentPipeline -Config $Config -EnvironmentId 'web' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde)
}
