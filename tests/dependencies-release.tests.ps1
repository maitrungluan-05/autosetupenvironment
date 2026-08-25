$root=Split-Path $PSScriptRoot -Parent
. "$root\src\core\config.ps1";. "$root\src\core\dependencies.ps1";. "$root\src\core\release.ps1"
function New-TestConfig($packages){@{Packages=$packages}}
Describe 'Dependency resolver behaviors' {
 It 'orders simple dependencies' {$p=[pscustomobject]@{a=[pscustomobject]@{id='a';dependencies=@('b')};b=[pscustomobject]@{id='b';dependencies=@()}};(Resolve-DevSetupPackages (New-TestConfig $p) @('a')) -join ',' | Should Be 'b,a'}
 It 'deduplicates shared dependencies deterministically' {$p=[pscustomobject]@{web=[pscustomobject]@{id='web';dependencies=@('git')};devops=[pscustomobject]@{id='devops';dependencies=@('git')};git=[pscustomobject]@{id='git';dependencies=@()}};(Resolve-DevSetupPackages (New-TestConfig $p) @('web','devops','web')) -join ',' | Should Be 'git,devops,web'}
 It 'rejects unknown dependencies' {$p=[pscustomobject]@{a=[pscustomobject]@{id='a';dependencies=@('missing')}};{Resolve-DevSetupPackages (New-TestConfig $p) @('a')} | Should Throw}
 It 'rejects readable circular dependencies' {$p=[pscustomobject]@{a=[pscustomobject]@{id='a';dependencies=@('b')};b=[pscustomobject]@{id='b';dependencies=@('c')};c=[pscustomobject]@{id='c';dependencies=@('a')}};{Resolve-DevSetupPackages (New-TestConfig $p) @('a')} | Should Throw}
}
Describe 'Release transaction rollback' {
 It 'activates a valid stage' {$base=Join-Path $env:TEMP ([guid]::NewGuid());$active="$base\active";$stage="$base\stage";New-Item "$active\src" -ItemType Directory -Force|Out-Null;Set-Content "$active\devsetup.ps1" old;New-Item "$stage\src" -ItemType Directory -Force|Out-Null;Set-Content "$stage\devsetup.ps1" new;Set-Content "$stage\src\main.ps1" main;$r=Invoke-ReleaseActivation $stage $active;try{$r.Success|Should Be $true;(Get-Content "$active\devsetup.ps1")|Should Be new}finally{Remove-Item $base -Recurse -Force}}
 It 'restores active on post swap failure' {$base=Join-Path $env:TEMP ([guid]::NewGuid());$active="$base\active";$stage="$base\stage";New-Item "$active\src" -ItemType Directory -Force|Out-Null;Set-Content "$active\devsetup.ps1" old;New-Item "$stage\src" -ItemType Directory -Force|Out-Null;Set-Content "$stage\devsetup.ps1" new;$r=Invoke-ReleaseActivation $stage $active {param($p) $p -eq $stage};try{$r.Success|Should Be $false;(Get-Content "$active\devsetup.ps1")|Should Be old}finally{Remove-Item $base -Recurse -Force}}
}
