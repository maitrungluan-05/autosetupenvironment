$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'src\core\providers.ps1')
. (Join-Path $root 'src\core\process.ps1')
Describe 'Archive extraction security' {
 It 'Rejects traversal and rooted archive entries' { @('..\evil.ps1','../../outside.exe','C:\evil.exe','\\server\share\evil.exe') | ForEach-Object { (Test-ArchiveEntrySafe $_) | Should Be $false } }
 It 'Accepts a relative ZIP entry' { (Test-ArchiveEntrySafe 'bin\tool.exe') | Should Be $true }
}
Describe 'Native argument handling' {
 It 'Keeps configured native arguments as discrete values' { $args=@('--installPath','C:\Dev Tools\Example','--add','Microsoft.VisualStudio.Workload.VCTools','--includeRecommended'); $r=Invoke-DevSetupProcess 'cmd.exe' @('/c','exit','0') 5; $args.Count | Should Be 5; $args[1] | Should Be 'C:\Dev Tools\Example'; (ConvertTo-NativeArgumentString $args) | Should Be '--installPath "C:\Dev Tools\Example" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended' }
 It 'Quotes executable paths containing spaces' { (ConvertTo-NativeArgumentString @('C:\Program Files\Test Tool\tool.exe')) | Should Be '"C:\Program Files\Test Tool\tool.exe"' }
}
