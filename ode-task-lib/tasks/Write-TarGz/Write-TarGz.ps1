[CmdletBinding()]
param(
	[string] $TargetFileName,
	[string] $SourceFolder
)

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

function Write-TarGz {
    param (
		[string] $TargetFileName,
		[string] $SourceFolder
    )

	Write-Verbose "TargetFileName        : $TargetFileName"
	Write-Verbose "SourceFolder          : $SourceFolder"

	$TargetFileName = $TargetFileName -ireplace ".tar.gz"
	New-Alias -Name 7z -Value (Join-Path $PSScriptRoot "7za.exe")

	$generatedFile = (Join-Path $SourceFolder "$TargetFileName.tar")
	& 7z a -ttar "$generatedFile" "$(Join-Path $SourceFolder "*.*")" -r
	$generatedFile2 = "$generatedFile.gz"
    & 7z a -tgzip "$generatedFile2" "$generatedFile"
	Remove-Item $generatedFile -Force
}

Write-TarGz -TargetFileName $TargetFileName -SourceFolder $SourceFolder -FilePath $FilePath
