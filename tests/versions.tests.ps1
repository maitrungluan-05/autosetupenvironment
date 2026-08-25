# ============================================================================
# DevSetup Unit Tests - Version Engine
# ============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

. (Join-Path $rootDir "src\core\logger.ps1")
. (Join-Path $rootDir "src\core\versions.ps1")

Describe "DevSetup Version Comparison Engine" {

    Context "Extract-VersionString" {
        It "Extracts standard SemVer from string" {
            $ver = Extract-VersionString -RawOutput "v22.14.0"
            $ver | Should Be "22.14.0"
        }

        It "Extracts version from git output" {
            $ver = Extract-VersionString -RawOutput "git version 2.50.1.windows.1"
            $ver | Should Be "2.50.1"
        }

        It "Extracts version from openjdk javac output" {
            $ver = Extract-VersionString -RawOutput 'javac 21.0.8' -CustomRegex '(?:javac|openjdk version) "?(\d+(?:\.\d+)*)'
            $ver | Should Be "21.0.8"
        }

        It "Extracts single major version string" {
            $ver = Extract-VersionString -RawOutput "21"
            $ver | Should Be "21"
        }
    }

    Context "Compare-Versions" {
        It "Correctly evaluates equal versions (21 == 21)" {
            $cmp = Compare-Versions -Version1 "21" -Version2 "21"
            $cmp | Should Be 0
        }

        It "Correctly evaluates newer minor version (21.0.2 > 21)" {
            $cmp = Compare-Versions -Version1 "21.0.2" -Version2 "21"
            $cmp | Should BeGreaterThan 0
        }

        It "Correctly evaluates outdated version (17.0.15 < 21)" {
            $cmp = Compare-Versions -Version1 "17.0.15" -Version2 "21"
            $cmp | Should BeLessThan 0
        }

        It "Prevents lexical comparison error ('9.10' vs '10.2')" {
            $cmp = Compare-Versions -Version1 "9.10" -Version2 "10.2"
            $cmp | Should BeLessThan 0
        }
    }

    Context "Test-VersionSatisfied" {
        It "Returns true when current version meets minimum requirement" {
            $res = Test-VersionSatisfied -CurrentVersion "21.0.8" -MinimumVersion "21"
            $res | Should Be $true
        }

        It "Returns false when current version is lower than minimum" {
            $res = Test-VersionSatisfied -CurrentVersion "17.0.1" -MinimumVersion "21"
            $res | Should Be $false
        }
    }
}
