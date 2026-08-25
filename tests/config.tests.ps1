# ============================================================================
# DevSetup Unit Tests - Config Module
# ============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

. (Join-Path $rootDir "src\core\config.ps1")

Describe "DevSetup Config Loader & Validator" {

    Context "Load-DevSetupConfig" {
        It "Loads environments and packages correctly" {
            $configPath = Join-Path $rootDir "config"
            $cfg = Load-DevSetupConfig -ConfigDirPath $configPath

            ($cfg.Environments -ne $null) | Should Be $true
            ($cfg.Packages -ne $null) | Should Be $true
            ($cfg.Defaults -ne $null) | Should Be $true
        }

        It "Validates Java environment package references" {
            $configPath = Join-Path $rootDir "config"
            $cfg = Load-DevSetupConfig -ConfigDirPath $configPath
            $javaEnv = Get-EnvironmentDefinition -Config $cfg -EnvironmentId "java"

            ($javaEnv.packages -contains "jdk21") | Should Be $true
            ($javaEnv.packages -contains "maven") | Should Be $true
        }
    }
}
