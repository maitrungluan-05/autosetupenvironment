# DevSetup Core - Installer
function Create-InstallationPlan { param([array]$DetectionResults,[switch]$NoIde)
 $plan=@(); foreach($r in $DetectionResults){$p=$r.PackageDef; $action=switch($r.Status){'INSTALLED_OK'{'KEEP'} 'OUTDATED'{'UPGRADE'} 'MISSING'{'INSTALL'} 'OPTIONAL_MISSING'{'INSTALL'} 'PARTIAL'{'INSTALL'} 'MANUAL_REQUIRED'{'SKIP'} default{'SKIP'}}; if($p.providerType -eq 'manual'){$action='SKIP'}; if($NoIde -and $p.optional){$action='SKIP'}; $plan+=@{Id=$p.id;DisplayName=$p.displayName;Action=$action;PackageDef=$p;Reason=if($p.providerType -eq 'manual'){$p.manualGuidance}else{''}}}; return $plan }
function Execute-InstallationPlan { param([array]$PlanItems,[switch]$DryRun,[switch]$Yes)
 Display-InstallationPlan $PlanItems $DryRun
 if($DryRun){Write-Host 'No changes were made.' -ForegroundColor Yellow;return @{Success=$true;DryRun=$true;ExitCode=0}}
 $actions=@($PlanItems|Where-Object Action -in @('INSTALL','UPGRADE')); if(-not $actions){return @{Success=$true;ExitCode=0}}
 if(-not $Yes -and -not(Confirm-Action 'Continue with installation?')){return @{Success=$false;Cancelled=$true;ExitCode=5}}
 $failed=0;$skipped=0; foreach($i in $PlanItems){if($i.Action -eq 'SKIP'){if($i.Reason){Write-Host "[SKIP] $($i.DisplayName): $($i.Reason)" -ForegroundColor Yellow};$skipped++;continue};if($i.Action -eq 'KEEP'){continue};$p=$i.PackageDef
  if($p.providerType -ne 'winget'){$skipped++;continue}; $retry=$true;while($retry){$r=if($i.Action -eq 'UPGRADE'){Upgrade-WingetPackage $p.wingetId}else{Install-WingetPackage $p.wingetId @($p.installArgs)};if($r.Success){Refresh-ProcessEnvironment;$retry=$false}else{if($Yes){$failed++;$retry=$false}else{$c=(Read-Host "Failed $($i.DisplayName). [R]etry [S]kip [A]bort").ToUpper();if($c -eq 'R'){}elseif($c -eq 'A'){return @{Success=$false;ExitCode=5;Cancelled=$true}}else{$skipped++;$retry=$false}}}}
 };return @{Success=($failed -eq 0);ExitCode=if($failed){3}else{0};FailedCount=$failed;SkippedCount=$skipped}
}
