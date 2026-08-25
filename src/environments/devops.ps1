function Invoke-DevOpsEnvironment {
 param([Parameter(Mandatory=$true)]$Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'DevOps Environment'
 return (Invoke-EnvironmentPipeline -Config $Config -EnvironmentId 'devops' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde)
}
