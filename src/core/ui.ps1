# ============================================================================
# DevSetup Core - UI Module
# ============================================================================

function Write-DevSetupHeader {
    param([string]$Title = "DevSetup")
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "               $Title" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-DevSetupBanner {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "               DevSetup" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Windows Development Environment Manager" -ForegroundColor Gray
    Write-Host ""
}

function Show-InteractiveMenu {
    Write-DevSetupBanner
    Write-Host "Select environment:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Java" -ForegroundColor Green
    Write-Host "  [2] Python" -ForegroundColor Green
    Write-Host "  [3] Node.js" -ForegroundColor Green
    Write-Host "  [4] C/C++" -ForegroundColor Green
    Write-Host "  [5] Go" -ForegroundColor Green
    Write-Host "  [6] Rust" -ForegroundColor Green
    Write-Host "  [7] Web Development" -ForegroundColor Green
    Write-Host "  [8] DevOps" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [A] All" -ForegroundColor Cyan
    Write-Host "  [D] Doctor" -ForegroundColor Yellow
    Write-Host "  [U] Update" -ForegroundColor Yellow
    Write-Host "  [H] Help" -ForegroundColor Gray
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Select"
    return $choice.Trim().ToUpper()
}

function Confirm-Action {
    param(
        [string]$PromptMessage = "Continue?",
        [switch]$DefaultYes = $false
    )

    if ($global:DevSetupYes) {
        return $true
    }

    $suffix = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $answer = Read-Host "$PromptMessage $suffix"
    $answer = $answer.Trim().ToLower()

    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $DefaultYes
    }

    return ($answer -eq "y" -or $answer -eq "yes")
}

function Format-StatusTag {
    param([string]$Status)
    switch ($Status) {
        "INSTALLED_OK" { return "[OK]" }
        "MISSING"      { return "[MISSING]" }
        "OUTDATED"     { return "[OUTDATED]" }
        "PARTIAL"      { return "[PARTIAL]" }
        "BROKEN"       { return "[BROKEN]" }
        "WARN"         { return "[WARN]" }
        "SKIP"         { return "[SKIP]" }
        Default        { return "[$Status]" }
    }
}

function Format-StatusColor {
    param([string]$Status)
    switch ($Status) {
        "INSTALLED_OK" { return "Green" }
        "MISSING"      { return "Red" }
        "OUTDATED"     { return "Yellow" }
        "PARTIAL"      { return "Yellow" }
        "BROKEN"       { return "Red" }
        "WARN"         { return "Yellow" }
        "SKIP"         { return "DarkGray" }
        Default        { return "White" }
    }
}

function Format-ActionTag {
    param([string]$Action)
    switch ($Action) {
        "KEEP"    { return "[KEEP]" }
        "INSTALL" { return "[INSTALL]" }
        "UPGRADE" { return "[UPGRADE]" }
        "REPAIR"  { return "[REPAIR]" }
        "SKIP"    { return "[SKIP]" }
        Default   { return "[$Action]" }
    }
}

function Format-ActionColor {
    param([string]$Action)
    switch ($Action) {
        "KEEP"    { return "Green" }
        "INSTALL" { return "Cyan" }
        "UPGRADE" { return "Yellow" }
        "REPAIR"  { return "Red" }
        "SKIP"    { return "DarkGray" }
        Default   { return "White" }
    }
}

function Display-DetectionTable {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    Write-Host ""
    Write-Host ("{0,-18} {1,-14} {2,-14} {3,-12}" -f "Component", "Current", "Required", "Status") -ForegroundColor White
    Write-Host ("-" * 60) -ForegroundColor Gray

    foreach ($res in $Results) {
        $curr = if ($res.CurrentVersion) { $res.CurrentVersion } else { "-" }
        $req = if ($res.MinimumVersion) { ">= " + $res.MinimumVersion } else { "installed" }
        $tag = Format-StatusTag -Status $res.Status
        $color = Format-StatusColor -Status $res.Status

        Write-Host ("{0,-18} {1,-14} {2,-14} " -f $res.Name, $curr, $req) -NoNewline
        Write-Host $tag -ForegroundColor $color
    }
    Write-Host ""
}

function Display-InstallationPlan {
    param(
        [Parameter(Mandatory=$true)]
        [array]$PlanItems,
        [bool]$IsDryRun = $false
    )

    Write-Host ""
    if ($IsDryRun) {
        Write-Host "DevSetup Dry Run" -ForegroundColor Yellow
    } else {
        Write-Host "Installation plan:" -ForegroundColor White
    }
    Write-Host ""

    foreach ($item in $PlanItems) {
        $tag = Format-ActionTag -Action $item.Action
        $color = Format-ActionColor -Action $item.Action
        
        Write-Host ("  {0,-10} {1}" -f $tag, $item.DisplayName) -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "Existing software will not be removed." -ForegroundColor Gray
    Write-Host ""
}
