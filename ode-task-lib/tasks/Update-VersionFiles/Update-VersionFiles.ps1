[CmdletBinding(DefaultParameterSetName = 'None')]
param(
	[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $sourcePath,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $filePattern,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $buildRegex,
    [string]$replaceRegex,
    [string]$buildNumber = $env:BUILD_BUILDNUMBER
)

function DoJob
{
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param(
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $sourcePath,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $filePattern,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $buildRegex,
		[string]$replaceRegex,
		[string]$buildNumber = $env:BUILD_BUILDNUMBER
	)

	if ($replaceRegex -eq "")
	{
		$replaceRegex = $buildRegex
	}
	Write-Host "Using $replaceRegex as the replacement regex"

	if ($buildNumber -match $buildRegex -ne $true) 
	{
		Write-Host "Could not extract a version from [$buildNumber] using pattern [$buildRegex]"
		return
	} 

	try
	{
		$extractedBuildNumber = $Matches[0]
		Write-Host "Using version $extractedBuildNumber in folder $sourcePath"
  
		$files = Get-ChildItem -Path $sourcePath -Filter $filePattern -Recurse
 
		if(!$files)
		{
			Write-Host "##vso[task.logissue type=warning;]no file to upgrade"

			return
		}

		[int]$fileIndex = 0
		
		$files | % {
			$fileIndex++
			$fileToChange = $_.FullName  
			Write-Host "Updating version in $($fileToChange)"
                 
			Set-ItemProperty $fileToChange IsReadOnly $false
  
			(Get-Content $fileToChange) | % { $_ -replace $replaceRegex, $extractedBuildNumber } | Set-Content $fileToChange
			$done = $fileIndex / $files.Length * 100
			Write-Host "##vso[task.setprogress value=$done;]File replacement done on $($_.Name)"
		}

		Write-Host "Replaced version in $($files.count) files"
	} 
	catch
	{
		Write-Warning $_
	}
}

DoJob -sourcePath $sourcePath -filePattern $filePattern -buildRegex $buildRegex -replaceRegex $replaceRegex -buildNumber $buildNumber
