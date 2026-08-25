# ============================================================================
# DevSetup Core - Platform Detection & Validation Module
# ============================================================================
function Test-IsWindows { return [Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT }
function Get-WindowsVersionInfo { $os=Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue;if($os){return @{Caption=$os.Caption;Version=$os.Version;BuildNumber=$os.BuildNumber;Architecture=$os.OSArchitecture}};return @{Caption='Windows (Unknown)';Version=[Environment]::OSVersion.Version.ToString();BuildNumber=[Environment]::OSVersion.Version.Build;Architecture=if([Environment]::Is64BitOperatingSystem){'64-bit'}else{'32-bit'}} }
function Test-IsAdministrator { $p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent());return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
function Test-WingetAvailable { $winget=Get-Command 'winget.exe' -ErrorAction SilentlyContinue;if(-not $winget){return $false};try{$null=& 'winget.exe' --version 2>&1;return $LASTEXITCODE -eq 0}catch{return $false} }
function Get-WingetVersionString { if(-not(Test-WingetAvailable)){return $null};try{return (& 'winget.exe' --version 2>&1).Trim()}catch{return $null} }
function ConvertFrom-DevSetupNativeOutput {
 param([AllowNull()][string]$Text)
 if($null -eq $Text -or $Text.Length -eq 0){return $Text}
 if($Text.IndexOf([char]0) -lt 0){return $Text.Trim([char]0,[char]0xFEFF)}
 # Some Windows native tools emit UTF-16 bytes that Windows PowerShell surfaces as byte-valued chars.
 $bytes=New-Object byte[] $Text.Length;for($i=0;$i -lt $Text.Length;$i++){if([int][char]$Text[$i] -gt 255){return $Text};$bytes[$i]=[byte][char]$Text[$i]}
 $candidates=@([Text.Encoding]::BigEndianUnicode.GetString($bytes),[Text.Encoding]::Unicode.GetString($bytes))|Where-Object { $_.IndexOf([char]0) -lt 0 }
 if(-not $candidates){return $Text.Replace([string][char]0,'')}
 return @($candidates|Sort-Object @{Expression={@($_.ToCharArray()|Where-Object {[char]::IsControl($_) -and $_ -notin @("`r","`n","`t")}).Count};Ascending=$true},@{Expression={$_.Length};Descending=$true})[0].Trim([char]0,[char]0xFEFF)
}
function Test-NetworkConnectivity {
 param([string]$Uri='https://www.microsoft.com',[int]$TimeoutMilliseconds=3000)
 try {
  $previous=[Net.ServicePointManager]::SecurityProtocol;[Net.ServicePointManager]::SecurityProtocol=$previous -bor [Net.SecurityProtocolType]::Tls12
  try{$request=[Net.HttpWebRequest]::Create($Uri);$request.Method='HEAD';$request.Timeout=$TimeoutMilliseconds;$request.ReadWriteTimeout=$TimeoutMilliseconds;$response=$request.GetResponse();$response.Close();return $true}
  catch [Net.WebException] { if($_.Exception.Response){$_.Exception.Response.Close();return $true};if($_.Exception.Status -in @([Net.WebExceptionStatus]::Timeout,[Net.WebExceptionStatus]::NameResolutionFailure,[Net.WebExceptionStatus]::ConnectFailure,[Net.WebExceptionStatus]::ProxyNameResolutionFailure)){return $false};return $null }
  finally{[Net.ServicePointManager]::SecurityProtocol=$previous}
 } catch { return $null }
}
function Assert-WindowsPlatform { if(-not(Test-IsWindows)){Write-Host 'DevSetup currently supports Windows only.' -ForegroundColor Red;exit 2} }
