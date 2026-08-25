# ============================================================================
# DevSetup Core - Version Parsing & Engine Module
# ============================================================================

function Extract-VersionString {
    param(
        [string]$RawOutput,
        [string]$CustomRegex = $null
    )

    if ([string]::IsNullOrWhiteSpace($RawOutput)) {
        return $null
    }

    if ($CustomRegex) {
        if ($RawOutput -match $CustomRegex) {
            return $Matches[1]
        }
    }

    # Standard fallbacks for standard version strings
    # Match standard versions like 21, 21.0.2, 3.13.5, v22.14.0, 2.50.1.windows.1
    $patterns = @(
        'v?(\d+\.\d+\.\d+(?:\.\d+)?)',
        'v?(\d+\.\d+)',
        'v?(\d+)'
    )

    foreach ($pat in $patterns) {
        if ($RawOutput -match $pat) {
            return $Matches[1]
        }
    }

    return $null
}

function ConvertTo-NormalizedVersion {
    param([string]$VersionString)

    if ([string]::IsNullOrWhiteSpace($VersionString)) {
        return $null
    }

    # Strip leading 'v' or quotes
    $clean = $VersionString.Trim().TrimStart('v', 'V').Trim('"').Trim("'")

    # Split by dot or hyphen
    $parts = $clean.Split('.-')
    $numParts = @()

    foreach ($part in $parts) {
        if ($part -match '^\d+$') {
            $numParts += [int]$part
        } else {
            # stop at non-numeric pre-release segment
            break
        }
    }

    if ($numParts.Count -eq 0) {
        return $null
    }

    # Pad to 4 components: major, minor, build, revision
    while ($numParts.Count -lt 4) {
        $numParts += 0
    }

    return New-Object System.Version($numParts[0], $numParts[1], $numParts[2], $numParts[3])
}

function Compare-Versions {
    param(
        [string]$Version1,
        [string]$Version2
    )

    $v1 = ConvertTo-NormalizedVersion -VersionString $Version1
    $v2 = ConvertTo-NormalizedVersion -VersionString $Version2

    if (-not $v1 -or -not $v2) {
        return $null
    }

    return $v1.CompareTo($v2)
}

function Test-VersionSatisfied {
    param(
        [string]$CurrentVersion,
        [string]$MinimumVersion
    )

    if ([string]::IsNullOrWhiteSpace($MinimumVersion)) {
        return $true
    }
    if ([string]::IsNullOrWhiteSpace($CurrentVersion)) {
        return $false
    }

    $cmp = Compare-Versions -Version1 $CurrentVersion -Version2 $MinimumVersion
    if ($null -eq $cmp) {
        # Fallback to loose string comparison if normalization failed
        Log-Warn "Version parsing warning: Could not normalize version strings ($CurrentVersion, $MinimumVersion)."
        return $false
    }

    return ($cmp -ge 0)
}
