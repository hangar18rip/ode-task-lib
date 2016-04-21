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

# Method based on code found here http://poshcode.org/2059
# if needed, add additional encodings
function Get-FileEncoding
{
	param (
		[string]$Path,
		[Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$FallbackEncoding
    )

    [byte[]]$byte = Get-Content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path

    if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
    {
		return [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::UTF8
	}
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
    {
		return [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Unicode
	}
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
    {
		return [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::UTF32
	}
    elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76)
    {
		return [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::UTF7
	}
    else
    {
		return $FallbackEncoding
	}
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
		$fileEncoding = Get-FileEncoding -Path $_ -FallbackEncoding $fileEncoding
		Write-Host "Detected file encoding : $fileEncoding"
		(Get-Content -Path $_ -Encoding $fileEncoding) | % {
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