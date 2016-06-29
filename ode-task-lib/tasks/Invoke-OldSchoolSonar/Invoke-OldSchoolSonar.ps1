[CmdletBinding()]
param(
	[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ConnectedServiceName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectKey,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectVersion,
	[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectDirectory,
	[string] $AdditionalParameters
)

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
Import-Module (Join-Path $PSScriptRoot "ode.TaskLib.Powershell.dll")

function Get-EspacedArgument
{
	[CmdletBinding()]
	param(
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $propertyName,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $propertyValue
	)

	return " -D$($propertyName)=`"$($propertyValue)`""
}

function Invoke-OldSchoolSonar {
	[CmdletBinding()]
	param(
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ConnectedServiceName,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectKey,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectName,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectVersion,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $ProjectDirectory,
		[string] $AdditionalParameters
	)

	Write-Verbose "ConnectedServiceName : $ConnectedServiceName"
	Write-Verbose "ProjectDirectory : $ProjectDirectory"
	Write-Verbose "ProjectKey = $ProjectKey"
	Write-Verbose "projectVersion = $projectVersion"
	Write-Verbose "ProjectName = $ProjectName"
	Write-Verbose "ProjectName = $ProjectName"

	$scanner = Join-Path $PSScriptRoot "scanner\bin\sonar-scanner.bat"
	Write-Verbose "Scanner : $scanner"

	$serviceEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $ConnectedServiceName
	Write-Verbose "serverUrl = $($serviceEndpoint.Url)"

	Push-Location -Path $ProjectDirectory

	[string[]] $command
	$command += "scan"
	$command += (Get-EspacedArgument "sonar.host.url" $serviceEndpoint.Url)
	if(!([string]::IsNullOrEmpty($serviceEndpoint.Authorization.Parameters.UserName)) -and !([string]::IsNullOrEmpty($serviceEndpoint.Authorization.Parameters.Password)))
	{
		Write-Verbose "Run as $($serviceEndpoint.Authorization.Parameters.UserName)"
		$command += (Get-EspacedArgument "sonar.login" $serviceEndpoint.Authorization.Parameters.UserName)
		$command += (Get-EspacedArgument "sonar.password" $serviceEndpoint.Authorization.Parameters.Password)
	}

	$command += (Get-EspacedArgument "sonar.projectKey" $projectKey)
	$command += (Get-EspacedArgument "sonar.projectName" $ProjectName)
	$command += (Get-EspacedArgument "sonar.projectVersion" $ProjectVersion)
	$command += (Get-EspacedArgument "sonar.sources" ".")
	$addArgs = $AdditionalParameters -split "\r\n"
	$addArgs | % {
		if($_){
			Write-Verbose "Additionnal parameter : $_"
			$command += " -D$($_)"
		}
	}

	#if($VerbosePreference)
	#{
	#	$command += "-X"
	#	$command += "-e"
	#}
	#$commandExe = "& `"$scanner`" scan$command"
	#Write-Verbose $commandExe
	#Invoke-Expression "$commandExe"
	#$res = Start-Process -FilePath $scanner -ArgumentList $command -Wait -PassThru -WorkingDirectory $ProjectDirectory -Verbose
	$res = Start-ProcessExtended -FilePath $scanner -Arguments $command -WorkingDirectory $ProjectDirectory -Verbose

	Write-Verbose "Exit code : $($res.ExitCode)"

	Pop-Location
}

Invoke-OldSchoolSonar -ConnectedServiceName $ConnectedServiceName -ProjectDirectory $ProjectDirectory -ProjectKey $ProjectKey -ProjectName $ProjectName -ProjectVersion $ProjectVersion -AdditionalParameters $AdditionalParameters
