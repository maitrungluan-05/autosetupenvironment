function Invoke-GoEnvironment {
 param([Parameter(Mandatory=$true)]$Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'Go Environment'
 return (Invoke-EnvironmentPipeline -Config $Config -EnvironmentId 'go' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde)
}
