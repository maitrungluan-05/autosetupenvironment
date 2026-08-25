function Invoke-NodeEnvironment {
 param([Parameter(Mandatory=$true)]$Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'Node.js Environment'
 return (Invoke-EnvironmentPipeline -Config $Config -EnvironmentId 'node' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde)
}
