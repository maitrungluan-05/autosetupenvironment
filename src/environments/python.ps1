function Invoke-PythonEnvironment {
 param([Parameter(Mandatory=$true)]$Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'Python Environment'
 return (Invoke-EnvironmentPipeline -Config $Config -EnvironmentId 'python' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde)
}
