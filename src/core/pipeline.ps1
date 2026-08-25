# DevSetup Core - Generic Environment Pipeline
function Invoke-EnvironmentPipeline {
 param([Parameter(Mandatory=$true)]$Config,[Parameter(Mandatory=$true)][string]$EnvironmentId,[string[]]$PackageIds,[switch]$DryRun,[switch]$Yes,[switch]$NoIde)
 $envDef=Get-EnvironmentDefinition $Config $EnvironmentId; if(-not $envDef){throw "Unknown environment '$EnvironmentId'."}
 $requestedIds = if ($PackageIds) { $PackageIds } else { @($envDef.packages) }
 $ids=Resolve-DevSetupPackages $Config $requestedIds
 $detections=@(); foreach($id in $ids){$detections+=Detect-PackageStatus (Get-PackageDefinition $Config $id)}
 Display-DetectionTable $detections
 $plan=Create-InstallationPlan -DetectionResults $detections -NoIde:$NoIde
 $result=Execute-InstallationPlan -PlanItems $plan -DryRun:$DryRun -Yes:$Yes
 if($DryRun){return $result}
 $verifications=@(); foreach($i in $plan|Where-Object {$_.Action -in @('KEEP','INSTALL','UPGRADE')}){$verifications+=Verify-Package $i.PackageDef}
 $verified=Display-VerificationReport $verifications $envDef.displayName
 if(-not $verified -and $result.Success){$result.Success=$false;$result.ExitCode=4}
 return $result
}
