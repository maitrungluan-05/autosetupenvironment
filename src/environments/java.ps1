function Get-JavaRequirementState { param($JavaInfo,$JavacInfo,[string]$RequiredVersion='21')
 if(-not $JavaInfo -and -not $JavacInfo){return 'MISSING'}
 if($JavaInfo -and -not $JavacInfo){return 'PARTIAL'}
 if(-not $JavaInfo -or -not $JavacInfo){return 'PARTIAL'}
 if(Test-VersionSatisfied $JavacInfo.Version $RequiredVersion){return 'INSTALLED_OK'}
 return 'OUTDATED'
}
function Get-JavaCommandInfo { param([string]$Command)
 $paths=@();try{$paths=@(& where.exe $Command 2>$null)}catch{};$cmd=Get-Command $Command -ErrorAction SilentlyContinue;if($cmd -and $paths -notcontains $cmd.Source){$paths=@($cmd.Source)+$paths}
 foreach($path in $paths|Select-Object -Unique){$r=Invoke-DevSetupProcess $path @('-version') 8;[pscustomobject]@{Path=$path;Version=(Extract-VersionString "$($r.StdOut)`n$($r.StdErr)");Success=$r.Success}}
}
function Get-JavaHomeInfo { param([string]$Value)
 if([string]::IsNullOrWhiteSpace($Value)){return [pscustomobject]@{Value=$Value;Exists=$false;ValidJdk=$false;JavaPath=$null;JavacPath=$null;Version=$null}}
 if(-not(Test-Path $Value)){return [pscustomobject]@{Value=$Value;Exists=$false;ValidJdk=$false;JavaPath=$null;JavacPath=$null;Version=$null}}
 $javac=Join-Path $Value 'bin\javac.exe';$java=Join-Path $Value 'bin\java.exe';$valid=$false;$version=$null
 if((Test-Path $javac) -and (Test-Path $java)){$r=Invoke-DevSetupProcess $javac @('-version') 8;$version=Extract-VersionString "$($r.StdOut)`n$($r.StdErr)";$valid=$r.Success}
 [pscustomobject]@{Value=$Value;Exists=$true;ValidJdk=$valid;JavaPath=$java;JavacPath=$javac;Version=$version}
}
function Get-DevSetupUserEnvironmentVariable { param([string]$Name) [Environment]::GetEnvironmentVariable($Name, 'User') }
function Set-DevSetupUserEnvironmentVariable { param([string]$Name, [AllowNull()][string]$Value) [Environment]::SetEnvironmentVariable($Name, $Value, 'User') }

function Get-JavaDiagnostic {
 $activeJava=@(Get-JavaCommandInfo 'java.exe');$activeJavac=@(Get-JavaCommandInfo 'javac.exe');$candidateHomes=@()
 foreach($javaHomeValue in @(Get-DevSetupUserEnvironmentVariable 'JAVA_HOME',[Environment]::GetEnvironmentVariable('JAVA_HOME','Machine'))|Where-Object{$_}){$candidateHomes+=$javaHomeValue}
 foreach($root in @('C:\Program Files\Java','C:\Program Files\Microsoft','C:\Program Files\Eclipse Adoptium')){if(Test-Path $root){$candidateHomes+=Get-ChildItem $root -Directory -ErrorAction SilentlyContinue|Select-Object -ExpandProperty FullName}}
 $jdks=@();foreach($candidateHome in $candidateHomes|Where-Object{$_}|Select-Object -Unique){$info=Get-JavaHomeInfo $candidateHome;if($info.ValidJdk){$jdks+=[pscustomobject]@{Home=$candidateHome;JavaPath=$info.JavaPath;JavacPath=$info.JavacPath;Version=$info.Version;Source='known-location'}}}
 $javaHomeInfo=Get-JavaHomeInfo (Get-DevSetupUserEnvironmentVariable 'JAVA_HOME');if(-not $javaHomeInfo.Value){$javaHomeInfo=Get-JavaHomeInfo ([Environment]::GetEnvironmentVariable('JAVA_HOME','Machine'))}
 [pscustomobject]@{ActiveJava=@($activeJava)[0];ActiveJavac=@($activeJavac)[0];DiscoveredJdks=@($jdks);JavaHome=$javaHomeInfo}
}
function Set-JavaHomeSafely { param([string]$Target,[switch]$Yes)
 $candidate=Get-JavaHomeInfo $Target;if(-not $candidate.ValidJdk){return @{Success=$false;Error='Recommended JAVA_HOME is not a verified JDK.'}}
 $old=Get-DevSetupUserEnvironmentVariable 'JAVA_HOME';if($old -and $old -ne $Target -and -not $Yes){if(-not(Confirm-Action 'Update JAVA_HOME?')){return @{Success=$false;Cancelled=$true}}}
 $backup=Join-Path (Get-DevSetupLogDirectory) ('JAVA_HOME-'+(Get-Date -Format yyyyMMddHHmmss)+'.bak');Set-Content $backup $old
 try{Set-DevSetupUserEnvironmentVariable 'JAVA_HOME' $Target;Refresh-ProcessEnvironment;$after=Get-JavaHomeInfo $Target;if(-not $after.ValidJdk){throw 'JAVA_HOME verification failed.'};@{Success=$true;Backup=$backup}}catch{Set-DevSetupUserEnvironmentVariable 'JAVA_HOME' $old;Refresh-ProcessEnvironment;@{Success=$false;Error=$_.Exception.Message;RolledBack=$true}}
}
function Invoke-JavaEnvironment { param($Config,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde)
 Write-DevSetupHeader -Title 'Java Environment';$diag=Get-JavaDiagnostic;if($diag.ActiveJava){Write-Host "Active Java: $($diag.ActiveJava.Version) $($diag.ActiveJava.Path)" -ForegroundColor Gray}
 $jdk21=@($diag.DiscoveredJdks|Where-Object{Test-VersionSatisfied $_.Version '21'})|Select-Object -First 1;if($jdk21 -and $diag.ActiveJava -and -not(Test-VersionSatisfied $diag.ActiveJava.Version '21')){Write-Host "[WARN] JDK 21 is installed, but Java $($diag.ActiveJava.Version) is currently active." -ForegroundColor Yellow}
 Invoke-EnvironmentPipeline $Config 'java' -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde
}
