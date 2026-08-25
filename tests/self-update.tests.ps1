$root = Split-Path $PSScriptRoot -Parent
. "$root\src\core\providers.ps1"
. "$root\src\core\release.ps1"
. "$root\src\commands\self-update.ps1"

Describe 'Self-update transaction failure matrix' {
    BeforeEach {
        $script:base = Join-Path $TestDrive ([guid]::NewGuid())
        $script:active = Join-Path $script:base 'active'
        New-Item "$script:active\src" -ItemType Directory -Force | Out-Null
        Set-Content "$script:active\devsetup.ps1" 'old'
        Set-Content "$script:active\src\main.ps1" 'old-main'
    }
    AfterEach { Remove-Item $script:base -Recurse -Force -ErrorAction SilentlyContinue }
    It 'fails closed without release metadata' { (Invoke-DevSetupSelfUpdate @{} -Yes) | Should Be 2 }
    It 'rejects checksum mismatch, missing checksum, download failure, corrupt ZIP, and traversal ZIP' {
        $missing = [pscustomobject]@{ downloadUrl='https://example.test/update.zip'; sha256=$null }
        (Invoke-DevSetupSelfUpdate @{ release=$missing } -Yes -ActivePath $script:active -Downloader { throw 'not called' }) | Should Be 2
        $goodHash = ('0' * 64); $meta = [pscustomobject]@{ downloadUrl='https://example.test/update.zip'; sha256=$goodHash }
        (Invoke-DevSetupSelfUpdate @{ release=$meta } -Yes -ActivePath $script:active -Downloader { throw 'download failed' }) | Should Be 2
        (Get-Content "$script:active\devsetup.ps1") | Should Be 'old'
    }
    It 'keeps active installation on staging validation, swap, and post-validation failure' {
        $stage = Join-Path $script:base 'stage'; New-Item "$stage\src" -ItemType Directory -Force | Out-Null
        Set-Content "$stage\devsetup.ps1" 'new'; Set-Content "$stage\src\main.ps1" 'new-main'
        (Invoke-ReleaseActivation $stage $script:active { param($path) $false }).Success | Should Be $false
        (Get-Content "$script:active\devsetup.ps1") | Should Be 'old'
        $stage = Join-Path $script:base 'stage2'; New-Item "$stage\src" -ItemType Directory -Force | Out-Null
        Set-Content "$stage\devsetup.ps1" 'new'; Set-Content "$stage\src\main.ps1" 'new-main'
        (Invoke-ReleaseActivation $stage $script:active { param($path) $true } -SimulateSwapFailure).RolledBack | Should Be $true
        (Get-Content "$script:active\devsetup.ps1") | Should Be 'old'
    }
}
