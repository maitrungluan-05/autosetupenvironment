# ============================================================================
# DevSetup Commands - Help & Version Handler
# ============================================================================

function Invoke-DevSetupHelp {
    Write-DevSetupBanner

    Write-Host "USAGE:" -ForegroundColor White
    Write-Host "  devsetup [command|environment] [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "COMMANDS / ENVIRONMENTS:" -ForegroundColor White
    Write-Host "  devsetup                 Launch interactive setup menu" -ForegroundColor Yellow
    Write-Host "  devsetup java            Check & setup Java 21 LTS environment" -ForegroundColor Green
    Write-Host "  devsetup python          Check & setup Python 3.13 environment" -ForegroundColor Green
    Write-Host "  devsetup node            Check & setup Node.js LTS environment" -ForegroundColor Green
    Write-Host "  devsetup cpp             Check & setup C/C++ build tools" -ForegroundColor Green
    Write-Host "  devsetup go              Check & setup Go language toolchain" -ForegroundColor Green
    Write-Host "  devsetup rust            Check & setup Rust environment" -ForegroundColor Green
    Write-Host "  devsetup web             Setup Web Development preset (Git, Node, VS Code, GH)" -ForegroundColor Green
    Write-Host "  devsetup devops          Setup DevOps preset (Git, Docker, kubectl, Helm, Terraform)" -ForegroundColor Green
    Write-Host "  devsetup all             Run consolidated setup for all environments" -ForegroundColor Green
    Write-Host "  devsetup doctor          Run system diagnostic health check" -ForegroundColor Yellow
    Write-Host "  devsetup update          Check and upgrade installed packages" -ForegroundColor Yellow
    Write-Host "  devsetup list            List all supported environments" -ForegroundColor Gray
    Write-Host "  devsetup help            Show this help guide" -ForegroundColor Gray
    Write-Host "  devsetup version         Display DevSetup version" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor White
    Write-Host "  --dry-run                Detect and create installation plan without changing system" -ForegroundColor Cyan
    Write-Host "  --yes                    Bypass confirmation prompts (for CI/automation)" -ForegroundColor Cyan
    Write-Host "  --verbose                Display detailed diagnostic output" -ForegroundColor Cyan
    Write-Host "  --no-ide                 Exclude optional IDEs (IntelliJ IDEA, VS Code)" -ForegroundColor Cyan
    Write-Host "  --json                   Export machine-readable JSON (for doctor command)" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-DevSetupVersion {
    param([Parameter(Mandatory=$true)]$Config)
    Write-Host "DevSetup v$($Config.Defaults.appVersion)" -ForegroundColor Cyan
}
