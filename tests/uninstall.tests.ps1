$root = Split-Path $PSScriptRoot -Parent
function Confirm-Action { param($Prompt) $true }
. "$root\src\commands\uninstall.ps1"

Describe 'DevSetup uninstall safety' {
    It 'removes only the exact DevSetup PATH entry and preserves all others' {
        $path = 'C:\Tools;C:\DevSetup;C:\Tools2;C:\DevSetupExtra'
        $updated = Remove-DevSetupPathEntry $path 'C:\DevSetup'
        $updated | Should Be 'C:\Tools;C:\Tools2;C:\DevSetupExtra'
    }
    It 'makes zero changes when the user rejects' {
        Mock Confirm-Action { $false }
        Mock Remove-Item { throw 'must not remove' }
        Mock Set-ItemProperty { throw 'must not change PATH' }
        (Invoke-DevSetupUninstall @{}).ToString() | Should Be '5'
    }
    It 'contains no developer-package uninstall path' {
        (Get-Content "$root\src\commands\uninstall.ps1" -Raw) | Should Not Match 'winget.*uninstall|Uninstall-WingetPackage'
    }
}
