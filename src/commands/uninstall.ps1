function Remove-DevSetupPathEntry { param([string]$PathValue,[string]$DevSetupPath)
 $target=$DevSetupPath.TrimEnd('\').ToLowerInvariant(); (($PathValue -split ';'|Where-Object{ $_ -and $_.TrimEnd('\').ToLowerInvariant() -ne $target}) -join ';')
}
function Invoke-DevSetupUninstall { param($Config,[switch]$Yes)
 Write-Host 'This removes DevSetup only.' -ForegroundColor Yellow;Write-Host 'Development tools installed through DevSetup will remain installed.' -ForegroundColor Yellow
 if(-not $Yes -and -not(Confirm-Action 'Continue?')){return 5}
 $install=Split-Path $PSScriptRoot -Parent | Split-Path -Parent;$userPath=[Environment]::GetEnvironmentVariable('PATH','User');$updated=Remove-DevSetupPathEntry $userPath $install
 if($updated -ne $userPath){Backup-UserEnvironmentPath|Out-Null;[Environment]::SetEnvironmentVariable('PATH',$updated,'User');Refresh-ProcessEnvironment}
 # Never calls Winget; only remove the known DevSetup installation when it is not the currently executing source tree.
 $expected=Join-Path $env:LOCALAPPDATA 'DevSetup';if((Test-Path $expected) -and ($expected -ne $install)){Remove-Item $expected -Recurse -Force}
 return 0
}
