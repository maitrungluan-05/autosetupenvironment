$root=Split-Path $PSScriptRoot -Parent
Describe 'DLD Luan Dev branding and bootstrap contract' {
 It 'uses RC.2 DLD Luan Dev metadata' { $d=Get-Content "$root\config\defaults.json" -Raw|ConvertFrom-Json;$d.appName|Should Be 'DLD Luan Dev';$d.appVersion|Should Be '0.9.0-rc.2' }
 It 'pins bootstrap to the official RC.2 release and validates runtime files' { $b=Get-Content "$root\bootstrap.ps1" -Raw;$b|Should Match 'https://github\.com/maitrungluan-05/autosetupenvironment';$b|Should Match "0\.9\.0-rc\.2";foreach($file in @('devsetup.ps1','dlddev.cmd','devsetup.cmd','src\main.ps1','config\defaults.json','config\environments.json')){$pattern=[regex]::Escape($file);$b|Should Match $pattern};$b|Should Match 'Expand-BootstrapZipSafely';$b|Should Not Match 'Invoke-Expression|Set-ExecutionPolicy' }
 It 'keeps the compatibility install directory' { (Get-Content "$root\bootstrap.ps1" -Raw)|Should Match "LOCALAPPDATA 'DevSetup'" }
 It 'provides launchers that forward all arguments' { $primary=Get-Content "$root\dlddev.cmd" -Raw;$compat=Get-Content "$root\devsetup.cmd" -Raw;$primary|Should Match 'devsetup\.ps1" %\*';$compat|Should Match 'dlddev\.cmd" %\*';$compat|Should Match 'DEPRECATED' }
}
