[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string] $userName,
	[Parameter(Mandatory = $true)]
	[string] $password,
	[Parameter(Mandatory = $true)]
	[string] $collection,
	[Parameter(Mandatory = $true)]
	[string] $extensionPath,
	[Switch] $overwrite
	#[string] $version,
	#[string] $versionToken
)

function Upload-TfsTask {
    param (
		[Parameter(Mandatory = $true)]
		[string] $userName,
		[Parameter(Mandatory = $true)]
		[string] $password,
		[Parameter(Mandatory = $true)]
		[string] $collection,
		[Parameter(Mandatory = $true)]
		[string] $extensionPath,
		[Switch] $overwrite
		#[string] $version,
		#[string] $versionToken
    )
    
	#if(![System.String]::IsNullOrEmpty($version))
	#{
	#	[System.Version] $goodVersion
	#	$parsed = [System.Version]::TryParse($version, [ref] $goodVersion)
	#	$taskJson = Join-Path $extensionPath "task.json"
	#	$tokenRegEx = "__$versionToken__"
	#	Get-Content $taskJson | % { 
	#		[string]$line = $_
	#		if ($_ -match $tokenRegex) {
	#			$setting = Get-ChildItem -Path env:* | ? { $_.Name -eq $Matches[1]  }
	#			if ($setting) {
	#				Write-Host ("Replacing key {0} with value from environment" -f $setting.Name)
	#				$line = $_ -replace $tokenRegex, $setting.Value
	#			}
	#		}
	#		$line
	#	}
	#}

	#Write-Verbose -Verbose "Version for task : $goodVersion"

	& npm install -g tfx-cli
	& tfx login --auth-type basic --username $userName --password $password --service-url $collection
	
	if($overwrite.IsPresent)
	{
		& tfx build tasks upload --task-path "$extensionPath" --overwrite
	} 
	else 
	{
		& tfx build tasks upload --task-path "$extensionPath"
	}
}

if($overwrite.IsPresent)
{
	Upload-TfsTask -userName $userName -password $password -collection $collection -extensionPath $extensionPath -overwrite
}
else
{
	Upload-TfsTask -userName $userName -password $password -collection $collection -extensionPath $extensionPath -overwrite
}
