[CmdletBinding()]
param(
	[string]$ConnectedServiceName,
	[string]$ProjectDirectory
)

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"

Write-Verbose "ConnectedServiceName : $ConnectedServiceName"
Write-Verbose "ProjectDirectory : $ProjectDirectory"

function Invoke-OldSchoolSonar {
	[CmdletBinding()]
	param(
		[string]$ConnectedServiceName,
		[string]$ProjectDirectory
	)

	$scanner = Join-Path $PSScriptRoot "sonarbin\sonar-scanner.bat"
	Write-Verbose "Scanner : $scanner"

	$serviceEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $ConnectedServiceName
	Write-Verbose "serverUrl = $($serviceEndpoint.Url)"

}

Invoke-OldSchoolSonar -ConnectedServiceName $ConnectedServiceName -ProjectDirectory $ProjectDirectory
#sonar-scanner -Dproject.settings=../myproject.properties
# sonar.projectBaseDir