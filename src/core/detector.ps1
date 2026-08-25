# DevSetup Core - Detector
function Test-ExecutableExists { param([string]$ExecutableName) return [bool](Get-Command $ExecutableName -ErrorAction SilentlyContinue) }
function Get-ExecutableVersion { param([string]$ExecutableName,[string]$VersionCommand,[string]$VersionRegex)
 $parts=$VersionCommand -split ' '; $r=Invoke-DevSetupProcess $parts[0] @($parts|Select-Object -Skip 1) 10; if(-not $r.Success){return @{Version=$null;Broken=$true}}; @{Version=(Extract-VersionString "$($r.StdOut)`n$($r.StdErr)" $VersionRegex);Broken=$false}
}
function Detect-PackageStatus { param($PackageDef)
 $provider=if($PackageDef.providerType){$PackageDef.providerType}else{'winget'}; $found=@($PackageDef.executables|Where-Object{Test-ExecutableExists $_})
 if($found.Count -eq 0){$status=if($provider -eq 'manual'){'MANUAL_REQUIRED'}elseif($PackageDef.optional){'OPTIONAL_MISSING'}else{'MISSING'};return @{Id=$PackageDef.id;Name=$PackageDef.name;DisplayName=$PackageDef.displayName;Status=$status;CurrentVersion=$null;MinimumVersion=$PackageDef.minimumVersion;PackageDef=$PackageDef;Paths=@()}}
 if($found.Count -lt @($PackageDef.executables).Count){return @{Id=$PackageDef.id;Name=$PackageDef.name;DisplayName=$PackageDef.displayName;Status='PARTIAL';CurrentVersion=$null;MinimumVersion=$PackageDef.minimumVersion;PackageDef=$PackageDef;Paths=$found}}
 if(-not $PackageDef.versionCommand){return @{Id=$PackageDef.id;Name=$PackageDef.name;DisplayName=$PackageDef.displayName;Status='INSTALLED_OK';CurrentVersion='Installed';MinimumVersion=$PackageDef.minimumVersion;PackageDef=$PackageDef;Paths=$found}}
 $v=Get-ExecutableVersion $found[0] $PackageDef.versionCommand $PackageDef.versionRegex
 $status=if($v.Broken){'BROKEN'}elseif(-not $v.Version){'UNKNOWN'}elseif(Test-VersionSatisfied $v.Version $PackageDef.minimumVersion){'INSTALLED_OK'}else{'OUTDATED'}
 return @{Id=$PackageDef.id;Name=$PackageDef.name;DisplayName=$PackageDef.displayName;Status=$status;CurrentVersion=$v.Version;MinimumVersion=$PackageDef.minimumVersion;PackageDef=$PackageDef;Paths=$found}
}
