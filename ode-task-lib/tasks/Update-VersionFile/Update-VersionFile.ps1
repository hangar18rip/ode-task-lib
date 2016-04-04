[CmdletBinding(DefaultParameterSetName = 'None')]
param(
	[string] $sourcePath = $env:BUILD_SOURCESDIRECTORY,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $filePattern,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $buildRegex,
    [string]$replaceRegex,
    [string]$buildNumber = $env:BUILD_BUILDNUMBER
)

function Update-VersionFile
{
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param(
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $sourcePath,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $filePattern,
		[string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $buildRegex,
		[string]$replaceRegex,
		[string]$buildNumber = $env:BUILD_BUILDNUMBER
	)

	if ($replaceRegex -eq '')
	{
		Write-Host "Using $replaceRegex as the replacement regex"
		$replaceRegex = $buildRegex
	}

	[System.Text.RegularExpressions.RegexOptions] $regOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace
	#$tokens = [regex]::Matches($buildNumber, $buildRegex, $regOpts)
	#[Match] $match =  [regex]::Match($buildNumber, $buildRegex, $regOpts)


	if ($buildNumber -imatch $buildRegex -ne $true)
	#if ([regex]::Match($buildNumber, $buildRegex, $regOpts) -ne $true)
	{
		Write-Host "Could not extract a version from [$buildNumber] using pattern [$buildRegex]"
		return
	}

	try
	{

		$extractedBuildNumber = $Matches[0]
		Write-Host "Using version $extractedBuildNumber"

		$files = Get-ChildItem -Path $sourcePath -Filter $filePattern -Recurse

		if(!$files)
		{
			Write-Host "##vso[task.logissue type=warning;]no file to upgrade"
			return
		}

		[int]$fileIndex = 0
		[int]$fileCount = $files.Count
		$files | % {
			$fileIndex++
			$fileToChange = $_.FullName
			Write-Host "Updating version in $($fileToChange)"

			Set-ItemProperty $fileToChange IsReadOnly $false

			(Get-Content $fileToChange) | % { $_ -replace $replaceRegex, $extractedBuildNumber } | Set-Content $fileToChange
			$done = $fileIndex / $fileCount * 100
			Write-Host "##vso[task.setprogress value=$done;]File replacement done on $($_.Name)"
		}

		Write-Host "Replaced version in $($files.count) files"
	}
	catch
	{
		Write-Warning $_
	}
}

Update-VersionFile -sourcePath $sourcePath -filePattern $filePattern -buildRegex $buildRegex -replaceRegex $replaceRegex -buildNumber $buildNumber

