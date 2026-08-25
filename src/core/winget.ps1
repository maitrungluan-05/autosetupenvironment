# DevSetup Core - Winget engine
function Test-WingetInstalled { Test-WingetAvailable }
function Get-WingetVersion { Get-WingetVersionString }
function Find-WingetPackage { param([string]$PackageId) $r=Invoke-DevSetupProcess 'winget.exe' @('show','--id',$PackageId,'--exact','--accept-source-agreements') 30; @{Found=$r.Success;Result=$r} }
function Get-WingetInstalledPackage { param([string]$PackageId) $r=Invoke-DevSetupProcess 'winget.exe' @('list','--id',$PackageId,'--exact','--accept-source-agreements') 30; @{Installed=$r.Success;Result=$r} }
function Get-WingetUpgrade { param([string]$PackageId) return (Invoke-DevSetupProcess 'winget.exe' @('upgrade','--id',$PackageId,'--exact','--accept-source-agreements') 30) }
function Install-WingetPackage {
 param([string]$PackageId,[string[]]$InstallArgs=@(),[int]$TimeoutSeconds=600)
 if(-not(Test-WingetInstalled)){return @{Success=$false;ExitCode=-1;ErrorMessage='Windows Package Manager (winget) was not found.'}}
 if($PackageId -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]+$'){return @{Success=$false;ExitCode=-2;ErrorMessage='Invalid Winget package ID.'}}
 $args=@('install','--id',$PackageId,'--exact','--accept-package-agreements','--accept-source-agreements','--disable-interactivity') + @($InstallArgs)
 $r=Invoke-DevSetupProcess 'winget.exe' $args $TimeoutSeconds
 $already=($r.StdOut -match '(?i)already installed' -or $r.StdErr -match '(?i)already installed')
 return @{Success=($r.Success -or $already);AlreadyInstalled=$already;ExitCode=$r.ExitCode;StdOut=$r.StdOut;StdErr=$r.StdErr;DurationMs=$r.DurationMs;Arguments=$r.Arguments}
}
function Upgrade-WingetPackage { param([string]$PackageId,[int]$TimeoutSeconds=600) $r=Invoke-DevSetupProcess 'winget.exe' @('upgrade','--id',$PackageId,'--exact','--accept-package-agreements','--accept-source-agreements','--disable-interactivity') $TimeoutSeconds; @{Success=$r.Success;ExitCode=$r.ExitCode;StdOut=$r.StdOut;StdErr=$r.StdErr;DurationMs=$r.DurationMs} }
