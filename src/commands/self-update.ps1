function Test-DevSetupReleaseArchive { param([string]$ZipPath,[string]$ExpectedHash)
 if(-not(Test-DevSetupSha256 $ZipPath $ExpectedHash)){throw 'Checksum mismatch; update aborted.'};$stage=Join-Path $env:TEMP ('DevSetupStage-'+[guid]::NewGuid());New-Item $stage -ItemType Directory -Force|Out-Null;try{Expand-DevSetupZipSafely $ZipPath $stage;if(-not(Test-Path (Join-Path $stage 'devsetup.ps1'))){throw 'Release entry point missing.'};return $stage}catch{Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue;throw}
}
function Invoke-DevSetupSelfUpdate { param($Config,[switch]$Yes)
 Write-Host 'Self-update requires a configured pinned HTTPS release URL and SHA256.' -ForegroundColor Yellow
 return 2
}
