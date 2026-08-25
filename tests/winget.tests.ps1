# ============================================================================
# DevSetup Unit Tests - Winget Engine (Mocked)
# ============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

. (Join-Path $rootDir "src\core\logger.ps1")
. (Join-Path $rootDir "src\core\process.ps1")
. (Join-Path $rootDir "src\core\platform.ps1")
. (Join-Path $rootDir "src\core\winget.ps1")

Describe "DevSetup Winget Wrapper" {

    Context "Install-WingetPackage Mocked" {
        It "Handles successful package installation" {
            Mock Invoke-DevSetupProcess {
                return @{
                    Success = $true
                    ExitCode = 0
                    StdOut = "Successfully installed"
                    StdErr = ""
                    DurationMs = 1500
                }
            } -ModuleName $null

            Mock Test-WingetInstalled { return $true }

            $res = Install-WingetPackage -PackageId "Git.Git"
            $res.Success | Should Be $true
            $res.ExitCode | Should Be 0
        }

        It "Handles already installed exit code" {
            Mock Invoke-DevSetupProcess {
                return @{
                    Success = $false
                    ExitCode = 0x8A150009
                    StdOut = "Already installed"
                    StdErr = ""
                    DurationMs = 100
                }
            }

            Mock Test-WingetInstalled { return $true }

            $res = Install-WingetPackage -PackageId "Git.Git"
            $res.Success | Should Be $true
            $res.AlreadyInstalled | Should Be $true
        }
    }
}
