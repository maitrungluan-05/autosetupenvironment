# ============================================================================
# DevSetup Core - Configuration Module
# ============================================================================
function Get-DevSetupRootPath { return (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) }
function Load-DevSetupConfig {
 param([string]$ConfigDirPath)
 if (-not $ConfigDirPath) { $ConfigDirPath = Join-Path (Get-DevSetupRootPath) 'config' }
 try { $data = Get-Content (Join-Path $ConfigDirPath 'environments.json') -Raw -ErrorAction Stop | ConvertFrom-Json; $defaults = Get-Content (Join-Path $ConfigDirPath 'defaults.json') -Raw -ErrorAction Stop | ConvertFrom-Json } catch { throw "Configuration load failed: $($_.Exception.Message)" }
 Validate-DevSetupConfig $data
 return @{ Environments=$data.environments; Packages=$data.packages; Defaults=$defaults }
}
function Validate-DevSetupConfig {
 param([Parameter(Mandatory=$true)]$ConfigData)
 if (-not $ConfigData.environments -or -not $ConfigData.packages) { throw 'Config Validation Error: environments and packages are required.' }
 $seen=@{}
 foreach($prop in $ConfigData.packages.PSObject.Properties){
  $pkg=$prop.Value; if(-not $pkg.id -or -not $pkg.name -or -not $pkg.executables){throw "Config Validation Error: Package '$($prop.Name)' is incomplete."}
  if($seen[$pkg.id]){throw "Config Validation Error: Duplicate package id '$($pkg.id)'."}; $seen[$pkg.id]=$true
  $type=if($pkg.providerType){$pkg.providerType}else{'winget'}
  if($type -notin @('winget','manual','official-archive')){throw "Config Validation Error: Package '$($pkg.id)' has invalid providerType '$type'."}
  if($type -eq 'winget' -and (($pkg.wingetId -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]+$'))){throw "Config Validation Error: Package '$($pkg.id)' has invalid wingetId."}
  if($pkg.minimumVersion -and $pkg.minimumVersion -notmatch '^\d+(\.\d+){0,3}$'){throw "Config Validation Error: Package '$($pkg.id)' has invalid minimumVersion."}
  if($pkg.installArgs -and $pkg.installArgs -is [string]){throw "Config Validation Error: Package '$($pkg.id)' installArgs must be an array."}
  $dupes=@($pkg.executables | Group-Object | Where-Object Count -gt 1); if($dupes){throw "Config Validation Error: Package '$($pkg.id)' has duplicate executable definitions."}
 }
 foreach($env in $ConfigData.environments.PSObject.Properties){ foreach($id in @($env.Value.packages)){if(-not $ConfigData.packages.$id){throw "Config Validation Error: Environment '$($env.Name)' references undefined package '$id'."}} }
 foreach($prop in $ConfigData.packages.PSObject.Properties){foreach($d in @($prop.Value.dependencies)){if($d -and -not $ConfigData.packages.$d){throw "Config Validation Error: Package '$($prop.Name)' references undefined dependency '$d'."}}}
}
function Get-PackageDefinition { param($Config,[string]$PackageId) return $Config.Packages.$PackageId }
function Get-EnvironmentDefinition { param($Config,[string]$EnvironmentId) return $Config.Environments.$EnvironmentId }
