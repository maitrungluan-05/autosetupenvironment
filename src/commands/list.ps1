function Invoke-DevSetupList {
 param($Config)
 Write-DevSetupHeader -Title 'Supported Environments'
 foreach($entry in $Config.Environments.PSObject.Properties){$env=$entry.Value; Write-Host ("  {0,-16} - {1}" -f $env.id,$env.description) -ForegroundColor Green}
}
