[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string] $filePath,
	[Parameter(Mandatory = $true)]
	[string] $outputFilePath,
	[Parameter(Mandatory = $true)]
	[string] $environmentName,
	[Parameter(Mandatory = $true)]
	[string] $localAdminPassword
)

#for($bcl = 0; $bcl -lt $localAdminPassword.Length; $bcl++){
#	Write-Verbose -Verbose $localAdminPassword[$bcl]
#}

#Write-Verbose -Verbose "The password is $localAdminPassword"

#$localAdminPassword | Set-Content $outputFilePath