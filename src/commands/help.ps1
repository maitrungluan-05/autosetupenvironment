# DLD Luan Dev Commands - Help & Version Handler
function Invoke-DevSetupHelp {
    Write-DevSetupBanner
    Write-Host 'USAGE:' -ForegroundColor White
    Write-Host '  dlddev [command|environment] [options]' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'COMMANDS / ENVIRONMENTS:' -ForegroundColor White
    foreach ($line in @(
        'dlddev                 Launch interactive setup menu', 'dlddev java            Check & setup Java 21 LTS environment',
        'dlddev python          Check & setup Python 3.13 environment', 'dlddev node            Check & setup Node.js LTS environment',
        'dlddev cpp             Check & setup C/C++ build tools', 'dlddev go              Check & setup Go language toolchain',
        'dlddev rust            Check & setup Rust environment', 'dlddev web             Setup Web Development preset',
        'dlddev devops          Setup DevOps preset', 'dlddev all             Run consolidated setup for all environments',
        'dlddev doctor          Run system diagnostic health check', 'dlddev update          Check and upgrade installed packages',
        'dlddev self-update     Apply a verified DLD Luan Dev update', 'dlddev uninstall       Remove DLD Luan Dev only',
        'dlddev list            List all supported environments', 'dlddev help            Show this help guide', 'dlddev version         Display product version'
    )) { Write-Host "  $line" -ForegroundColor Green }
    Write-Host ''
    Write-Host 'OPTIONS:' -ForegroundColor White
    Write-Host '  --dry-run                Detect and create an installation plan without changing system' -ForegroundColor Cyan
    Write-Host '  --yes                    Bypass confirmation prompts (for CI/automation)' -ForegroundColor Cyan
    Write-Host '  --verbose                Display detailed diagnostic output' -ForegroundColor Cyan
    Write-Host '  --no-ide                 Exclude optional IDEs' -ForegroundColor Cyan
    Write-Host '  --json                   Export machine-readable JSON for doctor' -ForegroundColor Cyan
    Write-Host ''
}
function Invoke-DevSetupVersion { param([Parameter(Mandatory=$true)]$Config) Write-Host "$($Config.Defaults.appName) v$($Config.Defaults.appVersion)" -ForegroundColor Cyan }
