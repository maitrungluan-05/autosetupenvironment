param([string]$Version='1.0.0',[string]$RepoUrl='https://github.com/devsetup/devsetup',[string]$CustomZipUrl,[string]$CustomSha256Url)
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'DevSetup currently supports Windows only.'}
$install=Join-Path $env:LOCALAPPDATA 'DevSetup';$work=Join-Path $env:TEMP ('DevSetup-'+[guid]::NewGuid());$stage=Join-Path $work 'stage';$backup=Join-Path $work 'backup';New-Item $stage -ItemType Directory -Force|Out-Null
$zip=Join-Path $work "DevSetup-v$Version.zip";$sha="$zip.sha256";$base="$RepoUrl/releases/download/v$Version/DevSetup-v$Version.zip"
try{
 [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
 Invoke-WebRequest -Uri $(if($CustomZipUrl){$CustomZipUrl}else{$base}) -OutFile $zip -UseBasicParsing -ErrorAction Stop
 Invoke-WebRequest -Uri $(if($CustomSha256Url){$CustomSha256Url}else{"$base.sha256"}) -OutFile $sha -UseBasicParsing -ErrorAction Stop
 $expected=(Get-Content $sha -Raw).Trim().Split(' ')[0];if($expected -notmatch '^[a-fA-F0-9]{64}$'){throw 'Invalid SHA256 manifest.'};if((Get-FileHash $zip -Algorithm SHA256).Hash -ne $expected.ToUpper()){throw 'SHA256 checksum mismatch; installation aborted.'}
 Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force
 if(-not(Test-Path (Join-Path $stage 'devsetup.ps1'))){throw 'Release archive is missing devsetup.ps1.'}
 if(Test-Path $install){Move-Item $install $backup -Force}
 try{Move-Item $stage $install -Force}catch{if(Test-Path $backup){Move-Item $backup $install -Force};throw}
 if(Test-Path $backup){Remove-Item $backup -Recurse -Force}
 $userPath=[Environment]::GetEnvironmentVariable('PATH','User');if(($userPath -split ';'|ForEach-Object{$_.TrimEnd('\')}) -notcontains $install.TrimEnd('\')){[Environment]::SetEnvironmentVariable('PATH',($userPath.TrimEnd(';')+';'+$install),'User');$env:PATH+=';'+$install}
 Write-Host 'DevSetup installation completed. Open a new PowerShell session, then run devsetup.' -ForegroundColor Green
}catch{Write-Error $_;if(-not(Test-Path $install) -and (Test-Path $backup)){Move-Item $backup $install -Force};exit 4}finally{if(Test-Path $work){Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue}}
