param([Parameter(Position=0)][string]$Command,[Parameter(Position=1)][string]$SubCommand,[switch]$DryRun,[switch]$Yes,[switch]$VerboseMode,[switch]$NoIde,[switch]$Json)
$global:DevSetupVerbose=[bool]$VerboseMode;$global:DevSetupYes=[bool]$Yes;$global:DevSetupJson=[bool]$Json
$scriptDir=$PSScriptRoot;$rootDir=Split-Path $scriptDir -Parent
@('logger','platform','ui','config','process','paths','environment','versions','providers','dependencies','winget','detector','installer','verifier','pipeline')|ForEach-Object{. (Join-Path $scriptDir "core\$_.ps1")}
@('java','python','node','cpp','go','rust','web','devops')|ForEach-Object{. (Join-Path $scriptDir "environments\$_.ps1")}
@('doctor','update','list','help','install','uninstall','self-update')|ForEach-Object{. (Join-Path $scriptDir "commands\$_.ps1")}
Assert-WindowsPlatform
try{$config=Load-DevSetupConfig (Join-Path $rootDir 'config')}catch{[Console]::Error.WriteLine("[FATAL] $_");exit 2}
$cmd=if($Command){$Command.ToLower()}else{''}
switch($cmd){
 'java'{$r=Invoke-JavaEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'python'{$r=Invoke-PythonEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'node'{$r=Invoke-NodeEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'cpp'{$r=Invoke-CppEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'go'{$r=Invoke-GoEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'rust'{$r=Invoke-RustEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'web'{$r=Invoke-WebEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'devops'{$r=Invoke-DevOpsEnvironment $config -DryRun:$DryRun -Yes:$Yes -NoIde:$NoIde;exit $r.ExitCode}
 'all'{Invoke-DevSetupAll -Config $config -DryRun:$DryRun -Yes:$Yes;exit $LASTEXITCODE}
 'doctor'{$c=Invoke-DevSetupDoctor -Config $config -Json:$Json;exit $c}
 'list'{Invoke-DevSetupList -Config $config;exit 0}
 'help'{Invoke-DevSetupHelp;exit 0}
 'version'{Invoke-DevSetupVersion $config;exit 0}
 'uninstall'{exit (Invoke-DevSetupUninstall $config -Yes:$Yes)}
 'self-update'{exit (Invoke-DevSetupSelfUpdate $config -Yes:$Yes)}
 default{Invoke-DevSetupHelp;exit 0}
}
