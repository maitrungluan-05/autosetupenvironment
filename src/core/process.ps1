# ============================================================================
# DevSetup Core - Process Runner Module
# ============================================================================
function ConvertTo-NativeArgumentString {
 param([Parameter(Mandatory=$true)][string[]]$ArgumentList)
 # Windows CommandLineToArgvW-compatible quoting. Arguments remain an array at
 # all DevSetup call sites; this conversion occurs only at ProcessStartInfo.
 return (($ArgumentList | ForEach-Object {
   $value=[string]$_
   if($value -notmatch '[\s"]'){ return $value }
   '"' + (($value -replace '(\\*)"', '$1$1\"') -replace '(\\*)$', '$1$1') + '"'
 }) -join ' ')
}
function Invoke-DevSetupProcess {
 param([Parameter(Mandatory=$true)][string]$FilePath,[string[]]$ArgumentList=@(),[int]$TimeoutSeconds=300,[string]$WorkingDirectory)
 $psi=New-Object System.Diagnostics.ProcessStartInfo
 $psi.FileName=$FilePath; $psi.Arguments=ConvertTo-NativeArgumentString $ArgumentList
 $psi.UseShellExecute=$false; $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true; $psi.CreateNoWindow=$true
 if($WorkingDirectory){$psi.WorkingDirectory=$WorkingDirectory}
 $p=New-Object System.Diagnostics.Process; $p.StartInfo=$psi; $start=Get-Date
 try {
  if(-not $p.Start()){throw "Could not start '$FilePath'."}
  $stdout=$p.StandardOutput.ReadToEndAsync(); $stderr=$p.StandardError.ReadToEndAsync()
  if(-not $p.WaitForExit($TimeoutSeconds*1000)){try{$p.Kill()}catch{}; return @{Success=$false;ExitCode=-1;StdOut='';StdErr='TIMED_OUT';DurationMs=[int]((Get-Date)-$start).TotalMilliseconds;Arguments=$ArgumentList}}
  $p.WaitForExit(); return @{Success=($p.ExitCode -eq 0);ExitCode=$p.ExitCode;StdOut=$stdout.Result;StdErr=$stderr.Result;DurationMs=[int]((Get-Date)-$start).TotalMilliseconds;Arguments=$ArgumentList}
 } catch { return @{Success=$false;ExitCode=-99;StdOut='';StdErr=$_.Exception.Message;DurationMs=[int]((Get-Date)-$start).TotalMilliseconds;Arguments=$ArgumentList} }
 finally {$p.Dispose()}
}
