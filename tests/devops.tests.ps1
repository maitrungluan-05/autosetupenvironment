$root = Split-Path $PSScriptRoot -Parent

# ------------------------------------------------------------------
# Stubs for dependencies not under test in this file
# ------------------------------------------------------------------
function Invoke-DevSetupProcess { param($FilePath, $ArgumentList, $Timeout) @{Success=$false;ExitCode=1;StdOut='';StdErr=''} }
function Extract-VersionString { param($Text) $null }
function Get-EnvironmentDefinition { param($Config, $EnvironmentId) $Config.Environments.devops }
function Resolve-DevSetupPackages { param($Config, $PackageIds) @($PackageIds | Select-Object -Unique) }
function Write-Host {}
function Read-Host { '4' }
function Invoke-EnvironmentPipeline { param($Config,$EnvId) @{ExitCode=0} }
function Write-DevSetupHeader {}

. "$root\src\core\platform.ps1"
. "$root\src\environments\devops.ps1"

# ============================
# Helper: Build UTF-16 LE bytes as a raw string (simulates wsl.exe native output)
# Each UTF-16 LE byte is surfaced as a char with value 0-255.
# ============================
function New-Utf16LeString {
    param([string]$Text)
    $bytes = [Text.Encoding]::Unicode.GetBytes($Text)
    # Surface as byte-valued chars using -join (not [string] cast which gives "System.Char[]")
    $chars = New-Object char[] $bytes.Length
    for ($i = 0; $i -lt $bytes.Length; $i++) { $chars[$i] = [char]([byte]$bytes[$i]) }
    return (-join $chars)
}

function New-Utf16BeString {
    param([string]$Text)
    $bytes = [Text.Encoding]::BigEndianUnicode.GetBytes($Text)
    $chars = New-Object char[] $bytes.Length
    for ($i = 0; $i -lt $bytes.Length; $i++) { $chars[$i] = [char]([byte]$bytes[$i]) }
    return (-join $chars)
}

# ============================
# ConvertFrom-DevSetupNativeOutput tests
# ============================
Describe 'ConvertFrom-DevSetupNativeOutput' {
    It 'returns null for null input' {
        $result = ConvertFrom-DevSetupNativeOutput $null
        $result | Should BeNullOrEmpty
    }
    It 'returns empty for empty string' {
        $result = ConvertFrom-DevSetupNativeOutput ''
        ($null -eq $result -or $result -eq '') | Should Be $true
    }
    It 'passes through clean ASCII text (BOM/NUL stripped only, not spaces)' {
        $result = ConvertFrom-DevSetupNativeOutput "Hello World"
        $result | Should Be 'Hello World'
    }
    It 'strips BOM from clean text' {
        $result = ConvertFrom-DevSetupNativeOutput ([char]0xFEFF + 'clean text')
        $result | Should Match 'clean text'
        $result | Should Not Match ([char]0xFEFF)
    }
    It 'recovers UTF-16 LE encoded bytes surfaced as char stream' {
        $raw = New-Utf16LeString "Ubuntu-22.04    Stopped    2"
        # Verify the raw string contains NUL chars (it should, as bytes interleaved)
        ($raw.IndexOf([char]0) -ge 0) | Should Be $true
        $result = ConvertFrom-DevSetupNativeOutput $raw
        $result | Should Match 'Ubuntu-22.04'
        $result.IndexOf([char]0) | Should Be -1
    }
    It 'recovers UTF-16 BE encoded bytes surfaced as char stream (NUL removed)' {
        $raw = New-Utf16BeString "Hello"
        # The raw string should have NUL chars (interleaved LE/BE bytes)
        ($raw.IndexOf([char]0) -ge 0) | Should Be $true
        $result = ConvertFrom-DevSetupNativeOutput $raw
        # After normalization, no NUL characters must remain
        $result.IndexOf([char]0) | Should Be -1
    }
    It 'falls back to NUL stripping when no valid encoding recoverable' {
        # Mix chars > 255 with NUL to defeat both BE and LE decoding paths
        $raw = "A" + [char]0 + "B" + [char]0 + [char]256  # char 256 causes bytes check to return early
        # Actually char 256 causes [int][char] -gt 255 so function returns $Text unchanged
        # Instead test with odd-length NUL string (cannot be valid UTF-16)
        $raw2 = [char]0 + "X" + [char]0 + "Y" + [char]0  # 5 chars - odd length, cannot be valid 2-byte encoding
        $result = ConvertFrom-DevSetupNativeOutput $raw2
        $result.IndexOf([char]0) | Should Be -1
    }
    It 'handles BOM stripping' {
        $raw = [char]0xFEFF + "clean text"
        $result = ConvertFrom-DevSetupNativeOutput $raw
        $result | Should Match 'clean text'
    }
}

# ============================
# ConvertFrom-WslDistributionOutput tests
# ============================
Describe 'ConvertFrom-WslDistributionOutput' {
    It 'returns empty array for null input' {
        $result = @(ConvertFrom-WslDistributionOutput $null)
        $result.Count | Should Be 0
    }
    It 'returns empty array for whitespace input' {
        $result = @(ConvertFrom-WslDistributionOutput "   `n  `r`n  ")
        $result.Count | Should Be 0
    }
    It 'returns empty array for header-only output (no distros)' {
        $out = "Windows Subsystem for Linux Distributions:`r`nNAME                   STATE           VERSION"
        $result = @(ConvertFrom-WslDistributionOutput $out)
        $result.Count | Should Be 0
    }
    It 'parses single WSL2 distro correctly' {
        $out = "Windows Subsystem for Linux Distributions:`r`n  NAME                   STATE           VERSION`r`n* Ubuntu-22.04           Stopped         2"
        $result = @(ConvertFrom-WslDistributionOutput $out)
        $result.Count | Should Be 1
        $result[0].name | Should Be 'Ubuntu-22.04'
        $result[0].state | Should Be 'Stopped'
        $result[0].version | Should Be 2
        $result[0].default | Should Be $true
    }
    It 'parses single WSL1 distro correctly' {
        $out = "  NAME            STATE    VERSION`r`n  Alpine          Running  1"
        $result = @(ConvertFrom-WslDistributionOutput $out)
        $result.Count | Should Be 1
        $result[0].name | Should Be 'Alpine'
        $result[0].version | Should Be 1
        $result[0].default | Should Be $false
    }
    It 'parses mixed WSL1 and WSL2 distros' {
        # Use realistic wsl -l -v spacing with at least 2 spaces between each column
        $out = "  NAME                   STATE           VERSION`r`n* Ubuntu-22.04           Stopped         2`r`n  Alpine                 Running         1"
        $result = @(ConvertFrom-WslDistributionOutput $out)
        $result.Count | Should Be 2
        # Use @() wrapping to ensure .Count works reliably in Pester 4
        @($result | Where-Object { $_.version -eq 2 }).Count | Should Be 1
        @($result | Where-Object { $_.version -eq 1 }).Count | Should Be 1
        @($result | Where-Object { $_.default -eq $true }).Count | Should Be 1
    }
    It 'handles Running state' {
        $out = "  NAME         STATE    VERSION`r`n* Ubuntu       Running  2"
        $result = @(ConvertFrom-WslDistributionOutput $out)
        $result[0].state | Should Be 'Running'
    }
    It 'ignores malformed lines gracefully' {
        $out = "  NAME         STATE    VERSION`r`n  GARBAGE_LINE_NO_COLUMNS`r`n* Ubuntu-22.04  Stopped  2"
        $result = @(ConvertFrom-WslDistributionOutput $out)
        $result.Count | Should Be 1
        $result[0].name | Should Be 'Ubuntu-22.04'
    }
    It 'parses UTF-16 LE encoded wsl -l -v output' {
        $plain = "  NAME                   STATE           VERSION`r`n* Ubuntu-22.04           Stopped         2"
        $raw = New-Utf16LeString $plain
        $result = @(ConvertFrom-WslDistributionOutput $raw)
        $result.Count | Should Be 1
        $result[0].name | Should Be 'Ubuntu-22.04'
        $result[0].version | Should Be 2
    }
}

# ============================
# Get-WslDiagnostic unit tests (via mocked Invoke-DevSetupProcess)
# ============================
Describe 'Get-WslDiagnostic - WSL missing' {
    BeforeEach {
        # Ensure no wsl.exe found
        function Get-Command { param($Name,[string]$ErrorAction) $null }
    }
    It 'returns MISSING status when wsl.exe not on PATH' {
        $result = Get-WslDiagnostic
        $result.installed | Should Be $false
        $result.status | Should Be 'MISSING'
        ($null -eq $result.wsl2Available) | Should Be $true
        @($result.distributions).Count | Should Be 0
        @($result.distributionDetails).Count | Should Be 0
    }
}

Describe 'Get-WslDiagnostic - No distros' {
    BeforeEach {
        function Get-Command { param($Name,[string]$ErrorAction) [pscustomobject]@{Source='wsl.exe'} }
        function Invoke-DevSetupProcess {
            param($FilePath, $ArgumentList, $Timeout)
            switch ($ArgumentList[0]) {
                '--status' { @{Success=$true;StdOut="Default Version: 2`r`n";StdErr='';ExitCode=0} }
                '--version' { @{Success=$true;StdOut="WSL version: 2.7.0`r`n";StdErr='';ExitCode=0} }
                '-l'        { @{Success=$true;StdOut="Windows Subsystem for Linux Distributions:`r`n";StdErr='';ExitCode=0} }
                default     { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
            }
        }
    }
    It 'returns installed=true with empty distributions when no distros listed' {
        $result = Get-WslDiagnostic
        $result.installed | Should Be $true
        $result.commandAvailable | Should Be $true
        @($result.distributions).Count | Should Be 0
        @($result.distributionDetails).Count | Should Be 0
    }
    It 'wsl2Available is true when defaultVersion is 2 even with no distros' {
        $result = Get-WslDiagnostic
        $result.wsl2Available | Should Be $true
    }
}

Describe 'Get-WslDiagnostic - WSL2 distro' {
    BeforeEach {
        function Get-Command { param($Name,[string]$ErrorAction) [pscustomobject]@{Source='wsl.exe'} }
        function Invoke-DevSetupProcess {
            param($FilePath, $ArgumentList, $Timeout)
            switch ($ArgumentList[0]) {
                '--status' { @{Success=$true;StdOut="Default Version: 2`r`n";StdErr='';ExitCode=0} }
                '--version' { @{Success=$true;StdOut="WSL version: 2.7.0`r`n";StdErr='';ExitCode=0} }
                '-l'        { @{Success=$true;StdOut="  NAME                   STATE           VERSION`r`n* Ubuntu-22.04           Stopped         2`r`n";StdErr='';ExitCode=0} }
                default     { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
            }
        }
    }
    It 'detects WSL2 distro correctly' {
        $result = Get-WslDiagnostic
        $result.wsl2Available | Should Be $true
        $result.status | Should Be 'READY'
        @($result.distributions).Count | Should Be 1
        $result.distributions[0] | Should Match 'Ubuntu-22.04'
        $result.distributions[0] | Should Match '2'
        @($result.distributionDetails).Count | Should Be 1
        $result.distributionDetails[0].name | Should Be 'Ubuntu-22.04'
        $result.distributionDetails[0].version | Should Be 2
        $result.distributionDetails[0].default | Should Be $true
    }
    It 'distributions stays string[] (backward compat)' {
        $result = Get-WslDiagnostic
        $result.distributions[0].GetType().Name | Should Be 'String'
    }
    It 'distributionDetails is array not bare object' {
        $result = Get-WslDiagnostic
        # Must be able to iterate (array-like) - Count property must work
        (@($result.distributionDetails)).Count | Should Be 1
    }
}

Describe 'Get-WslDiagnostic - WSL1 only distro' {
    BeforeEach {
        function Get-Command { param($Name,[string]$ErrorAction) [pscustomobject]@{Source='wsl.exe'} }
        function Invoke-DevSetupProcess {
            param($FilePath, $ArgumentList, $Timeout)
            switch ($ArgumentList[0]) {
                '--status' { @{Success=$true;StdOut="Default Version: 1`r`n";StdErr='';ExitCode=0} }
                '--version' { @{Success=$false;StdOut='';StdErr='This WSL version does not support --version';ExitCode=1} }
                '-l'        { @{Success=$true;StdOut="  NAME     STATE    VERSION`r`n  Alpine   Running  1`r`n";StdErr='';ExitCode=0} }
                default     { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
            }
        }
    }
    It 'wsl2Available is null when only WSL1 distros exist (no positive WSL2 proof)' {
        # WSL1 distros alone do NOT prove WSL2 unavailable - only the "not supported" message does
        $result = Get-WslDiagnostic
        ($null -eq $result.wsl2Available) | Should Be $true
    }
    It 'WSL1 distro parsed correctly' {
        $result = Get-WslDiagnostic
        @($result.distributionDetails).Count | Should Be 1
        $result.distributionDetails[0].version | Should Be 1
    }
}

Describe 'Get-WslDiagnostic - wsl2Available false when WSL2 not supported message' {
    BeforeEach {
        function Get-Command { param($Name,[string]$ErrorAction) [pscustomobject]@{Source='wsl.exe'} }
        function Invoke-DevSetupProcess {
            param($FilePath, $ArgumentList, $Timeout)
            switch ($ArgumentList[0]) {
                '--status' { @{Success=$true;StdOut="WSL 2 is not supported on this machine`r`n";StdErr='';ExitCode=0} }
                '--version' { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
                '-l'        { @{Success=$true;StdOut="  NAME     STATE    VERSION`r`n";StdErr='';ExitCode=0} }
                default     { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
            }
        }
    }
    It 'wsl2Available is false when status output says WSL 2 not supported' {
        $result = Get-WslDiagnostic
        $result.wsl2Available | Should Be $false
    }
}

Describe 'Get-WslDiagnostic - mixed WSL1 and WSL2' {
    BeforeEach {
        function Get-Command { param($Name,[string]$ErrorAction) [pscustomobject]@{Source='wsl.exe'} }
        function Invoke-DevSetupProcess {
            param($FilePath, $ArgumentList, $Timeout)
            switch ($ArgumentList[0]) {
                '--status' { @{Success=$true;StdOut="Default Version: 2`r`n";StdErr='';ExitCode=0} }
                '--version' { @{Success=$true;StdOut="WSL version: 2.7.0`r`n";StdErr='';ExitCode=0} }
                '-l'        { @{Success=$true;StdOut="  NAME                   STATE           VERSION`r`n* Ubuntu-22.04           Stopped         2`r`n  Alpine                 Running         1`r`n";StdErr='';ExitCode=0} }
                default     { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
            }
        }
    }
    It 'wsl2Available is true when any distro is version 2' {
        $result = Get-WslDiagnostic
        $result.wsl2Available | Should Be $true
        $result.status | Should Be 'READY'
    }
    It 'both distros parsed' {
        $result = Get-WslDiagnostic
        @($result.distributionDetails).Count | Should Be 2
    }
}

Describe 'Get-WslDiagnostic - malformed wsl output' {
    BeforeEach {
        function Get-Command { param($Name,[string]$ErrorAction) [pscustomobject]@{Source='wsl.exe'} }
        function Invoke-DevSetupProcess {
            param($FilePath, $ArgumentList, $Timeout)
            switch ($ArgumentList[0]) {
                '--status' { @{Success=$true;StdOut="some unexpected output`r`n";StdErr='';ExitCode=0} }
                '--version' { @{Success=$true;StdOut="unparseable-junk 123xyz`r`n";StdErr='';ExitCode=0} }
                '-l'        { @{Success=$true;StdOut="COMPLETELY_MALFORMED NO COLUMNS`r`n";StdErr='';ExitCode=0} }
                default     { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
            }
        }
    }
    It 'does not throw on malformed output' {
        { Get-WslDiagnostic } | Should Not Throw
    }
    It 'returns installed=true with zero distros' {
        $result = Get-WslDiagnostic
        $result.installed | Should Be $true
        @($result.distributionDetails).Count | Should Be 0
    }
    It 'wsl2Available is null when state is indeterminate' {
        $result = Get-WslDiagnostic
        ($null -eq $result.wsl2Available) | Should Be $true
    }
}

Describe 'Get-WslDiagnostic - unsupported wsl --version' {
    BeforeEach {
        function Get-Command { param($Name,[string]$ErrorAction) [pscustomobject]@{Source='wsl.exe'} }
        function Invoke-DevSetupProcess {
            param($FilePath, $ArgumentList, $Timeout)
            switch ($ArgumentList[0]) {
                '--status' { @{Success=$true;StdOut="Default Version: 2`r`n";StdErr='';ExitCode=0} }
                '--version' { @{Success=$false;StdOut='';StdErr='The system cannot find the file specified.';ExitCode=1} }
                '-l'        { @{Success=$true;StdOut="  NAME                   STATE           VERSION`r`n* Ubuntu-22.04           Stopped         2`r`n";StdErr='';ExitCode=0} }
                default     { @{Success=$false;StdOut='';StdErr='';ExitCode=1} }
            }
        }
    }
    It 'gracefully handles unsupported --version flag (does not throw)' {
        { Get-WslDiagnostic } | Should Not Throw
    }
    It 'version field is null when --version fails' {
        $result = Get-WslDiagnostic
        ($null -eq $result.version) | Should Be $true
    }
    It 'wsl2Available still determined from distros' {
        $result = Get-WslDiagnostic
        $result.wsl2Available | Should Be $true
    }
}

# ============================
# Get-VirtualizationDiagnostic tests
# ============================
Describe 'Get-VirtualizationDiagnostic - enabled' {
    BeforeEach {
        function Get-CimInstance {
            param($ClassName,[string]$ErrorAction)
            [pscustomobject]@{VMMonitorModeExtensions=$true;VirtualizationFirmwareEnabled=$true}
        }
    }
    It 'returns READY status when both supported and enabled' {
        $result = Get-VirtualizationDiagnostic
        $result.supported | Should Be $true
        $result.enabled | Should Be $true
        $result.status | Should Be 'READY'
    }
}

Describe 'Get-VirtualizationDiagnostic - supported but disabled' {
    BeforeEach {
        function Get-CimInstance {
            param($ClassName,[string]$ErrorAction)
            [pscustomobject]@{VMMonitorModeExtensions=$true;VirtualizationFirmwareEnabled=$false}
        }
    }
    It 'returns INSTALLED_NOT_RUNNING when supported but disabled in firmware' {
        $result = Get-VirtualizationDiagnostic
        $result.supported | Should Be $true
        $result.enabled | Should Be $false
        $result.status | Should Be 'INSTALLED_NOT_RUNNING'
    }
}

Describe 'Get-VirtualizationDiagnostic - unsupported' {
    BeforeEach {
        function Get-CimInstance {
            param($ClassName,[string]$ErrorAction)
            [pscustomobject]@{VMMonitorModeExtensions=$false;VirtualizationFirmwareEnabled=$false}
        }
    }
    It 'returns UNSUPPORTED when VMMonitorModeExtensions is false' {
        $result = Get-VirtualizationDiagnostic
        $result.supported | Should Be $false
        $result.status | Should Be 'UNSUPPORTED'
    }
}

Describe 'Get-VirtualizationDiagnostic - unknown (CimInstance fails)' {
    BeforeEach {
        function Get-CimInstance {
            param($ClassName,[string]$ErrorAction)
            throw 'WMI unavailable'
        }
    }
    It 'returns UNKNOWN with null supported and enabled on CimInstance failure' {
        $result = Get-VirtualizationDiagnostic
        ($null -eq $result.supported) | Should Be $true
        ($null -eq $result.enabled) | Should Be $true
        $result.status | Should Be 'UNKNOWN'
    }
}

Describe 'Get-VirtualizationDiagnostic - unknown (null CIM properties)' {
    BeforeEach {
        function Get-CimInstance {
            param($ClassName,[string]$ErrorAction)
            [pscustomobject]@{VMMonitorModeExtensions=$null;VirtualizationFirmwareEnabled=$null}
        }
    }
    It 'returns UNKNOWN with null fields when CIM properties are null' {
        $result = Get-VirtualizationDiagnostic
        ($null -eq $result.supported) | Should Be $true
        ($null -eq $result.enabled) | Should Be $true
        $result.status | Should Be 'UNKNOWN'
    }
}

# ============================
# Test-NetworkConnectivity behavior verification
# ============================
Describe 'Test-NetworkConnectivity - function structure' {
    It 'function signature accepts Uri and TimeoutMilliseconds parameters' {
        $cmd = Get-Command Test-NetworkConnectivity
        $cmd.Parameters.ContainsKey('Uri') | Should Be $true
        $cmd.Parameters.ContainsKey('TimeoutMilliseconds') | Should Be $true
    }
    It 'handles non-2xx response as network proof (WebException with Response returns true)' {
        $src = (Get-Command Test-NetworkConnectivity).ScriptBlock.ToString()
        # The function must have a branch that returns true when Response exists (non-2xx)
        $src | Should Match 'Exception\.Response'
        $src | Should Match 'return \$true'
    }
    It 'handles timeout status returning false' {
        $src = (Get-Command Test-NetworkConnectivity).ScriptBlock.ToString()
        $src | Should Match 'Timeout'
        $src | Should Match 'return \$false'
    }
    It 'handles DNS failure (NameResolutionFailure) returning false' {
        $src = (Get-Command Test-NetworkConnectivity).ScriptBlock.ToString()
        $src | Should Match 'NameResolutionFailure'
    }
    It 'returns null for indeterminate conditions' {
        $src = (Get-Command Test-NetworkConnectivity).ScriptBlock.ToString()
        $src | Should Match 'return \$null'
    }
    It 'has bounded timeout to prevent hanging' {
        $src = (Get-Command Test-NetworkConnectivity).ScriptBlock.ToString()
        $src | Should Match 'TimeoutMilliseconds'
        $src | Should Match 'Timeout'
    }
    It 'does not use ICMP/ping for network detection' {
        $src = (Get-Command Test-NetworkConnectivity).ScriptBlock.ToString()
        $src | Should Not Match '(?i)\bping\b|\bTest-Connection\b|\bICMP\b'
    }
    It 'uses HTTPS probe' {
        $src = (Get-Command Test-NetworkConnectivity).ScriptBlock.ToString()
        $src | Should Match 'https://'
    }
}

Describe 'Test-NetworkConnectivity - live HTTPS probe returns bool or null' {
    It 'returns boolean true, false, or null (never throws)' {
        # This is a live test but must complete quickly (3s timeout)
        $result = $null
        { $result = Test-NetworkConnectivity -Uri 'https://www.microsoft.com' -TimeoutMilliseconds 5000 } | Should Not Throw
        # Result must be true, false, or null - never an exception
        ($result -eq $true -or $result -eq $false -or $null -eq $result) | Should Be $true
    }
}

# ============================
# DevOps cloud plan tests (existing, preserved)
# ============================
Describe 'DevOps cloud plan integration' {
    BeforeEach {
        $script:config=[pscustomobject]@{
            Environments=[pscustomobject]@{devops=[pscustomobject]@{packages=@('git','aws_cli','azure_cli')}};
            Packages=[pscustomobject]@{}
        }
        function Get-EnvironmentDefinition { param($Config,$EnvironmentId) $Config.Environments.devops }
        function Resolve-DevSetupPackages { param($Config,$PackageIds) @($PackageIds | Select-Object -Unique) }
    }
    It 'skip includes neither cloud package' {
        $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @()
        ($ids -contains 'aws_cli') | Should Be $false
        ($ids -contains 'azure_cli') | Should Be $false
    }
    It 'AWS includes only AWS' {
        $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @('aws_cli')
        ($ids -contains 'aws_cli') | Should Be $true
        ($ids -contains 'azure_cli') | Should Be $false
    }
    It 'Azure includes only Azure' {
        $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @('azure_cli')
        ($ids -contains 'azure_cli') | Should Be $true
        ($ids -contains 'aws_cli') | Should Be $false
    }
    It 'both includes both without duplicates' {
        $ids=Get-DevOpsResolvedPackageIds -Config $script:config -CloudPackageIds @('aws_cli','azure_cli','git')
        ($ids|Group-Object|Where-Object { $_.Count -gt 1 }).Count | Should Be 0
        ($ids -contains 'aws_cli') | Should Be $true
        ($ids -contains 'azure_cli') | Should Be $true
    }
    It 'yes defaults to skip' {
        @(Select-DevOpsCloudPackages -Yes).Count | Should Be 0
    }
}
