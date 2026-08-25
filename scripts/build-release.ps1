param([string]$Version)
$root=Split-Path $PSScriptRoot -Parent
if(-not $Version){$Version=(Get-Content (Join-Path $root 'config\defaults.json') -Raw|ConvertFrom-Json).appVersion}
$dist=Join-Path $root 'dist';$name="DLD-Luan-Dev-v$Version.zip";$zip=Join-Path $dist $name;$sha="$zip.sha256";$stage=Join-Path $env:TEMP ('DLD-Luan-Dev-Release-'+[guid]::NewGuid())
$required=@('src','config','devsetup.ps1','dlddev.cmd','devsetup.cmd','bootstrap.ps1','README.md','CHANGELOG.md','LICENSE','docs')
try{if(Test-Path $dist){Remove-Item $dist -Recurse -Force -ErrorAction Stop};New-Item $dist -ItemType Directory -Force|Out-Null;New-Item $stage -ItemType Directory -Force|Out-Null
 foreach($item in $required){$source=Join-Path $root $item;if(-not(Test-Path $source)){throw "Required release item missing: $item"};Copy-Item $source (Join-Path $stage $item) -Recurse -Force}
 Add-Type -AssemblyName System.IO.Compression.FileSystem;[IO.Compression.ZipFile]::CreateFromDirectory($stage,$zip,[IO.Compression.CompressionLevel]::Optimal,$false)
 $hash=(Get-FileHash $zip -Algorithm SHA256).Hash.ToLower();Set-Content $sha "$hash  $name" -Encoding ASCII;Write-Host "Release build successful: $zip" -ForegroundColor Green
}catch{Write-Error "Release build failed: $_";exit 1}finally{if(Test-Path $stage){Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue}}
