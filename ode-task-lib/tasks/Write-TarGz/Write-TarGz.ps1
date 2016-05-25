[CmdletBinding()]
param(
	[string] $TargetFileName,
	[string] $SourceFolder,
	[string] $FilePath
)

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

function Write-TarGz {
    param (
		[string] $TargetFileName,
		[string] $SourceFolder,
		[string] $FilePath
    )

	#($FilePath -split '[\r\n]').Trim() | % {
	#	if([System.IO.Path]::IsPathRooted($_))
	#	{
	#		$Files += $_
	#	}
	#	else
	#	{
	#		$Files += Join-Path $SourceFolder $_
	#	}
	#}
	$Files = ($FilePath -split '[\r\n]').Trim()

	Write-Verbose "TargetFileName        : $TargetFileName"
	Write-Verbose "SourceFolder          : $SourceFolder"
	Write-Verbose "FilePath              : $FilePath"
	Write-Verbose "Files                 : $Files"

	$TargetFileName = $TargetFileName -ireplace ".tar.gz"
	New-Alias -Name 7z -Value (Join-Path $PSScriptRoot "7za.exe")

	$generatedFile = (Join-Path $SourceFolder "$TargetFileName.tar")
	& 7z a -ttar "$generatedFile" "$(Join-Path $SourceFolder "*.*")" -r #$Files
	$generatedFile2 = "$generatedFile.gz"
    & 7z a -tgzip "$generatedFile2" "$generatedFile"
}

Write-TarGz -TargetFileName $TargetFileName -SourceFolder $SourceFolder -FilePath $FilePath
