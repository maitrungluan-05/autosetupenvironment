# ============================================================================
# DevSetup Core - Dependency Resolver
# ============================================================================
function Resolve-DevSetupPackages {
    param([Parameter(Mandatory=$true)]$Config, [Parameter(Mandatory=$true)][string[]]$PackageIds)
    $visiting = @{}; $visited = @{}; $result = New-Object System.Collections.Generic.List[string]
    function Visit-Package([string]$Id, [string[]]$Chain) {
        if ($visiting[$Id]) { throw "Config Validation Error: Circular dependency: $($Chain + $Id -join ' -> ')" }
        if ($visited[$Id]) { return }
        $pkg = Get-PackageDefinition -Config $Config -PackageId $Id
        if (-not $pkg) { throw "Config Validation Error: Undefined dependency '$Id'." }
        $visiting[$Id] = $true
        foreach ($dep in @($pkg.dependencies | Where-Object { $_ })) { Visit-Package $dep ($Chain + $Id) }
        $visiting.Remove($Id); $visited[$Id] = $true; $result.Add($Id)
    }
    foreach ($id in $PackageIds | Sort-Object -Unique) { Visit-Package $id @() }
    return ,$result.ToArray()
}
