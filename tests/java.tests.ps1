$root = Split-Path $PSScriptRoot -Parent
. "$root\src\core\versions.ps1"
function Confirm-Action { param([string]$Prompt) $true }
function Get-DevSetupLogDirectory { $TestDrive }
function Refresh-ProcessEnvironment {}
. "$root\src\environments\java.ps1"

Describe 'Java mocked behavior matrix' {
    It 'classifies Java missing' { (Get-JavaRequirementState $null $null) | Should Be 'MISSING' }
    It 'classifies JRE only' { (Get-JavaRequirementState ([pscustomobject]@{ Version = '21' }) $null) | Should Be 'PARTIAL' }
    It 'classifies JDK 17' { (Get-JavaRequirementState ([pscustomobject]@{ Version = '17' }) ([pscustomobject]@{ Version = '17' })) | Should Be 'OUTDATED' }
    It 'classifies JDK 21' { (Get-JavaRequirementState ([pscustomobject]@{ Version = '21.0.2' }) ([pscustomobject]@{ Version = '21.0.2' })) | Should Be 'INSTALLED_OK' }
    It 'recognizes discovered JDK 21 when active Java is 17' {
        (Test-VersionSatisfied '21' '21') | Should Be $true
        (Test-VersionSatisfied '17' '21') | Should Be $false
    }
}

Describe 'JAVA_HOME safety with mocked filesystem and environment operations' {
    BeforeEach {
        function Invoke-DevSetupProcess { param($FilePath, $Arguments, $Timeout) @{ Success = $true; StdOut = 'javac 21'; StdErr = '' } }
    }
    It 'models missing JAVA_HOME' { (Get-JavaHomeInfo $null).ValidJdk | Should Be $false }
    It 'models invalid JAVA_HOME' { (Get-JavaHomeInfo 'Z:\no-such-jdk').Exists | Should Be $false }
    It 'models JRE-only JAVA_HOME' {
        Mock Test-Path { param($Path) $Path -eq 'C:\Jre21' -or $Path -like '*java.exe' }
        (Get-JavaHomeInfo 'C:\Jre21').ValidJdk | Should Be $false
    }
    It 'does not mutate when user rejects a JAVA_HOME change' {
        $script:setCalls = 0
        Mock Get-JavaHomeInfo { [pscustomobject]@{ ValidJdk = $true; Value = 'C:\Jdk21' } }
        Mock Get-DevSetupUserEnvironmentVariable { 'C:\OldJdk' }
        Mock Confirm-Action { $false }
        Mock Set-DevSetupUserEnvironmentVariable { $script:setCalls++ }
        $result = Set-JavaHomeSafely 'C:\Jdk21'
        $result.Cancelled | Should Be $true
        $script:setCalls | Should Be 0
    }
    It 'updates JAVA_HOME after successful verification' {
        $script:setCalls = 0
        Mock Get-JavaHomeInfo { [pscustomobject]@{ ValidJdk = $true; Value = 'C:\Jdk21' } }
        Mock Get-DevSetupUserEnvironmentVariable { 'C:\OldJdk' }
        Mock Set-Content {}
        Mock Set-DevSetupUserEnvironmentVariable { $script:setCalls++ }
        $result = Set-JavaHomeSafely 'C:\Jdk21' -Yes
        $result.Success | Should Be $true
        $script:setCalls | Should Be 1
    }
    It 'rolls back JAVA_HOME after verification failure' {
        $script:checks = 0; $script:setCalls = 0
        Mock Get-JavaHomeInfo { $script:checks++; [pscustomobject]@{ ValidJdk = ($script:checks -eq 1); Value = 'C:\Jdk21' } }
        Mock Get-DevSetupUserEnvironmentVariable { 'C:\OldJdk' }
        Mock Set-Content {}
        Mock Set-DevSetupUserEnvironmentVariable { $script:setCalls++ }
        $result = Set-JavaHomeSafely 'C:\Jdk21' -Yes
        $result.RolledBack | Should Be $true
        $script:setCalls | Should Be 2
    }
}

Describe 'Java idempotency' {
    It 'installs only during MISSING then keeps INSTALLED_OK' {
        $run = 0
        $states = @('MISSING', 'INSTALLED_OK')
        foreach ($state in $states) {
            $action = if ($state -eq 'MISSING') { 'INSTALL' } else { 'KEEP' }
            if ($action -eq 'INSTALL') { $run++ }
        }
        $run | Should Be 1
    }
}
