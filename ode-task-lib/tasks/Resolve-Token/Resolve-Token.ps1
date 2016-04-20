[CmdletBinding()]
param(
	[string] $sourceFolder,
	[Parameter(Mandatory = $true)]
	[string] $filePath,
	[string] $tokenRegex = '(__([\w]+)__)',
	[string] $warningAsError = 'true',
	[string] $fileEncoding = 'default'
)

Write-Host "sourceFolder ==> $sourceFolder"
Write-Host "filePath ==> $filePath"
Write-Host "tokenRegex ==> $tokenRegex"
Write-Host "warningAsError ==> $warningAsError"
Write-Host "fileEncoding ==> $fileEncoding"

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

function Get-KeyValue{
	param (
		[string] $Key
	)
	$envValue = Get-TaskVariable $distributedTaskContext $key -Global $false -ErrorAction Ignore
	if($envValue -ne $null)
	{
		return $envValue
	}

	$envValue = Get-TaskVariable $distributedTaskContext $key -Global $true -ErrorAction Ignore
	if($envValue -ne $null)
	{
		return $envValue
	}

	$envVars = Get-Item -Path "env:\$key" -ErrorAction Ignore
	return ($envVars.Value)
}

function Resolve-Token {
    param (
		[string] $sourceFolder,
        [Parameter(Mandatory = $true)]
        [String[]]$filePath,
        [String]$tokenRegex,
		[bool] $treatWarningsAsError = $true,
		[Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding] $fileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Default
    )

    [System.Text.RegularExpressions.RegexOptions] $regOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace

    [bool]$paramNotFound = $false
    [int] $lineIndex = 0

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

	$files | % {
		$setParametersFile = $_
		Set-ItemProperty -Path $_ -Name IsReadOnly -Value $false
		Write-Host "Processing file $_"

		( Get-Content -Path $_ -Encoding $fileEncoding) | % {
			$line = $_
			$lineIndex = $lineIndex + 1
			$tokens = [regex]::Matches($line, $tokenRegex, $regOpts)

			$tokens = ($tokens | ? {$_.Length -gt 0})
			foreach($token in $tokens){
				$key = $token.Groups[2].Value

				$envValue = Get-KeyValue -Key $key
				Write-Verbose "$key = $envValue"
				if($envValue -ne $null)
				{
					Write-Host "Replacing key $key"
					$line = $line.Replace($token.Groups[1].Value, $envValue)
				} else {
					$paramNotFound = $true
					if(!$treatWarningsAsError)
					{
						Write-Host "##vso[task.logissue type=warning;sourcepath=$setParametersFile;linenumber=$lineIndex;]No value provided for token '$key', replacing with empty value"
						$line = $line.Replace($token.Groups[1].Value, "")
					} else {
						Write-Host "##vso[task.logissue type=warning;sourcepath=$setParametersFile;linenumber=$lineIndex;]No value provided for token '$key'"
					}
				}
			}
			$line
		} | Set-Content -Path $_ -Encoding $fileEncoding
	}

	if($paramNotFound -and $treatWarningsAsError)
	{
		Write-Host "##vso[task.logissue type=error;]Missing at least one parameter in a file. Check logs for more information"
		throw "Missing at least one parameter in a file. Check logs for more information"
	}
}

#function Get-FileEncoding
#{
#	param
#	(
#		[string] $file
#	)

#	$bom = Get-Content -Path $file -Encoding Byte -ReadCount 4 -TotalCount 4
#	$intBom = [System.BitConverter]::ToUInt32($bom)

#	#https://en.wikipedia.org/wiki/Byte_order_mark
#	$bomValues = @{
#		0xEFBBBF = 'UTF8';
#		0xFEFF = 'UTF-16 Big-Endian';
#		0xFFFE = 'UTF-16 Little-Endian';
#		0x0000FEFF = 'UTF32 Big-Endian';
#		0xFFFE0000 = 'UTF32 Little-Endian';
#		0x2B2F7638 = 'UTF7';
#		0x2B2F7639 = 'UTF7';
#		0x2B2F762B = 'UTF7';
#		0x2B2F762F = 'UTF7';
#		0xF7644C = 'UTF-1';
#		0xDD736673 = 'UTF-EBCDIC';
#		0x0EFEFF = 'SCSU';
#		0xFBEE28 = 'BOCU-1';
#		0x84319533 = 'GB-18030';
#	}
#}

try
{
	[bool] $treatWarningsAsError = [bool]::Parse($warningAsError)
	[string[]] $files = ($filePath -split '[\r\n]')
	Resolve-Token -sourceFolder $sourceFolder -filePath $files -tokenRegex $tokenRegex -treatWarningsAsError $treatWarningsAsError -Verbose -Debug -ErrorAction Stop -fileEncoding $fileEncoding
}
catch
{
	Write-Host "##vso[task.logissue type=error;]$_"
	throw
}
finally
{

}