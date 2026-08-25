# ============================================================================
# DevSetup CLI Entry Point
# ============================================================================

param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1)]
    [string]$SubCommand,

    [switch]$DryRun,
    [switch]$Yes,
    [switch]$VerboseMode,
    [switch]$NoIde,
    [switch]$Json
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $scriptDir "src\main.ps1"

if (-not (Test-Path $mainScript)) {
    Write-Host "[ERROR] Missing main script: $mainScript" -ForegroundColor Red
    exit 2
}

& $mainScript -Command $Command -SubCommand $SubCommand -DryRun:$DryRun -Yes:$Yes -VerboseMode:$VerboseMode -NoIde:$NoIde -Json:$Json
exit $LASTEXITCODE
