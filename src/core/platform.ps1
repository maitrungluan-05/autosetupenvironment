# ============================================================================
# DevSetup Core - Platform Detection & Validation Module
# ============================================================================

function Test-IsWindows {
    return [Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
}

function Get-WindowsVersionInfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        return @{
            Caption = $os.Caption
            Version = $os.Version
            BuildNumber = $os.BuildNumber
            Architecture = $os.OSArchitecture
        }
    }
    return @{
        Caption = "Windows (Unknown)"
        Version = [Environment]::OSVersion.Version.ToString()
        BuildNumber = [Environment]::OSVersion.Version.Build
        Architecture = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
    }
}

function Test-IsAdministrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WingetAvailable {
    $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
    if (-not $winget) {
        return $false
    }
    try {
        $result = & "winget.exe" --version 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Get-WingetVersionString {
    if (-not (Test-WingetAvailable)) {
        return $null
    }
    try {
        $ver = & "winget.exe" --version 2>&1
        return $ver.Trim()
    } catch {
        return $null
    }
}

function Test-NetworkConnectivity {
    try {
        $request = [System.Net.WebRequest]::Create("https://www.microsoft.com")
        $request.Timeout = 3000
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch {
        return $false
    }
}

function Assert-WindowsPlatform {
    if (-not (Test-IsWindows)) {
        Write-Host "DevSetup currently supports Windows only." -ForegroundColor Red
        exit 2
    }
}
