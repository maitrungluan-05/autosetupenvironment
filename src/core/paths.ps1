# ============================================================================
# DevSetup Core - Path Management Module
# ============================================================================

function Get-UserEnvironmentPath {
    return [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
}

function Get-MachineEnvironmentPath {
    return [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
}

function Normalize-PathString {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    $trimmed = $Path.Trim().TrimEnd('\', '/')
    return $trimmed.ToLowerInvariant()
}

function Backup-UserEnvironmentPath {
    $currentPath = Get-UserEnvironmentPath
    $backupDir = Get-DevSetupLogDirectory
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = Join-Path $backupDir "PATH-User-$timestamp.bak"
    
    Set-Content -Path $backupFile -Value $currentPath -ErrorAction SilentlyContinue
    Log-Info "User PATH environment backed up to '$backupFile'."
    return $backupFile
}

function Add-PathToUserScope {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PathToAdd
    )

    if (-not (Test-Path $PathToAdd)) {
        Log-Warn "Cannot add invalid or non-existent directory to PATH: $PathToAdd"
        return $false
    }

    $normNew = Normalize-PathString -Path $PathToAdd
    $currentPath = Get-UserEnvironmentPath

    $existingEntries = if ($currentPath) { $currentPath -split ';' } else { @() }
    foreach ($entry in $existingEntries) {
        if ((Normalize-PathString -Path $entry) -eq $normNew) {
            Log-Debug "Path '$PathToAdd' already exists in User PATH."
            return $true
        }
    }

    # Backup before modification
    Backup-UserEnvironmentPath | Out-Null

    $updatedPath = if ($currentPath) { "$currentPath;$PathToAdd" } else { $PathToAdd }

    try {
        [Environment]::SetEnvironmentVariable("PATH", $updatedPath, [System.EnvironmentVariableTarget]::User)
        Log-Info "Added '$PathToAdd' to User PATH scope."
        
        # Refresh current process PATH
        Refresh-ProcessEnvironment
        return $true
    } catch {
        Log-Error "Failed to update User PATH environment variable: $_"
        return $false
    }
}
