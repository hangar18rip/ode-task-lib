[CmdletBinding(DefaultParameterSetName = 'None')]
param(
	[string] $sourceFolder = $env:BUILD_SOURCESDIRECTORY,
	[Parameter(Mandatory = $true)]
	[string] $filePath,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $buildRegex,
    [string]$replaceRegex,
    [string]$buildNumber = $env:BUILD_BUILDNUMBER
)

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

function Update-VersionFile
{
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param(
		[string][Parameter(Mandatory=$true)] $sourceFolder,
		[string[]][Parameter(Mandatory=$true)] $files,
		[string][Parameter(Mandatory=$true)] $buildRegex,
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

		$foundFiles = @()

		$files | % {
			$file = $_
			if ($file.Contains("*") -or $file.Contains("?"))
			{
				$tmpFiles = (Find-Files -SearchPattern $file -RootFolder $sourceFolder -IncludeFolders $false)
				$tmpFiles | % { $foundFiles+=$_ }
			}
			else
			{
				if([System.IO.Path]::IsPathRooted($file) -eq $true)
				{
					$foundFiles += $file
				}
				else
				{
					$foundFiles += (Join-Path $sourceFolder $file)
				}
			}
		}

		$files = $foundFiles

		if (($files -eq $null) -or ($files.Count -eq 0))
		{
			Write-Host "##vso[task.logissue type=warning;]no file to upgrade"
			return
		}

		[int]$fileIndex = 0
		[int]$fileCount = $files.Count
		$files | % {
			Set-ItemProperty -Path $_ -Name IsReadOnly -Value $false

			$fileIndex++
			$fileToChange = $_
			Write-Host "Updating version in $($fileToChange)"

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

[string[]] $files = ($filePath -split '[\r\n]')
Update-VersionFile -sourceFolder $sourceFolder -files $files -buildRegex $buildRegex -replaceRegex $replaceRegex -buildNumber $buildNumber

