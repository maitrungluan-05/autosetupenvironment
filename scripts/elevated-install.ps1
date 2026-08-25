param([Parameter(Mandatory=$true)][string]$RequestPath,[Parameter(Mandatory=$true)][string]$ResultPath)
$root=Split-Path $PSScriptRoot -Parent
try{
 if(-not ($RequestPath.StartsWith($env:TEMP,[StringComparison]::OrdinalIgnoreCase))){throw 'Request must be in the user temporary directory.'}
 $request=Get-Content $RequestPath -Raw|ConvertFrom-Json
 if(@($request.psobject.Properties.Name)-notcontains 'packageId' -or $request.action -ne 'install'){throw 'Invalid elevated request schema.'}
 . (Join-Path $root 'src\core\config.ps1');. (Join-Path $root 'src\core\process.ps1');. (Join-Path $root 'src\core\winget.ps1')
 $config=Load-DevSetupConfig (Join-Path $root 'config');$pkg=$config.Packages.$($request.packageId)
 if(-not $pkg -or -not $pkg.requiresAdmin -or $pkg.providerType -ne 'winget' -or $pkg.wingetId -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]+$'){throw 'Request package is not an allowed elevated package.'}
 $r=Install-WingetPackage $pkg.wingetId @($pkg.installArgs);@{success=[bool]$r.Success;exitCode=$r.ExitCode;status=if($r.Success){'SUCCESS'}else{'FAILED'};packageId=$pkg.id}|ConvertTo-Json -Compress|Set-Content $ResultPath -Encoding UTF8
}catch{@{success=$false;exitCode=1;status='FAILED';packageId=$null}|ConvertTo-Json -Compress|Set-Content $ResultPath -Encoding UTF8;exit 1}
