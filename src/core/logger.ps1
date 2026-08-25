# ============================================================================
# DevSetup Core - Logger Module
# ============================================================================

function Get-DevSetupLogDirectory {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    $logDir = Join-Path $localAppData "DevSetup\Logs"
    if (-not (Test-Path $logDir)) {
        $null = New-Item -Path $logDir -ItemType Directory -Force
    }
    return $logDir
}

function Get-DevSetupLogFilePath {
    $logDir = Get-DevSetupLogDirectory
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    return Join-Path $logDir "devsetup-$dateStr.log"
}

function Write-DevSetupLog {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [switch]$VerboseOnly
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    # Append to file
    try {
        $logPath = Get-DevSetupLogFilePath
        Add-Content -Path $logPath -Value $logLine -ErrorAction SilentlyContinue
    } catch {
        # Silent fallback if log write fails
    }

    # Console output if verbose or error/warn
    if ($global:DevSetupVerbose -or $Level -in @("WARN", "ERROR", "FATAL")) {
        if ($VerboseOnly -and -not $global:DevSetupVerbose) {
            return
        }
        
        $color = switch ($Level) {
            "DEBUG" { "DarkGray" }
            "INFO"  { "Gray" }
            "WARN"  { "Yellow" }
            "ERROR" { "Red" }
            "FATAL" { "DarkRed" }
            Default { "White" }
        }

        if ($host.UI.RawUI.ForegroundColor) {
            Write-Host "[$Level] $Message" -ForegroundColor $color
        } else {
            Write-Host "[$Level] $Message"
        }
    }
}

function Log-Info { param([string]$Message) Write-DevSetupLog -Level "INFO" -Message $Message }
function Log-Debug { param([string]$Message) Write-DevSetupLog -Level "DEBUG" -Message $Message -VerboseOnly }
function Log-Warn { param([string]$Message) Write-DevSetupLog -Level "WARN" -Message $Message }
function Log-Error { param([string]$Message) Write-DevSetupLog -Level "ERROR" -Message $Message }
