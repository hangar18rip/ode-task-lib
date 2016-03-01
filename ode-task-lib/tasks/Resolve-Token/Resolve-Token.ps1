[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string] $filePath,
	[string] $tokenRegex = '(__([\w]+)__)',
	[string] $warningAsError = 'true',
	[string] $fileEncoding = 'default'
)

Write-Host "#######################################################"
Write-Host "filePath ==> $filePath"
Write-Host "tokenRegex ==> $tokenRegex"
Write-Host "warningAsError ==> $warningAsError"
Write-Host "fileEncoding ==> $fileEncoding"
Write-Host "#######################################################"

function Resolve-Token {
    param (
        [Parameter(Mandatory = $true)]
        [String]$filePath,
        [String]$tokenRegex,
		[bool] $treatWarningsAsError = $true,
		[Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding] $fileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Default
    )

    [System.Text.RegularExpressions.RegexOptions] $regOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace
    $envVars = Get-ChildItem -Path env:

    [bool]$paramNotFound = $false
    [int] $lineIndex = 0

	Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $false

	(Get-Content -Path $filePath -Encoding $fileEncoding) | % {
		$line = $_
        $lineIndex = $lineIndex + 1
        $tokens = [regex]::Matches($line, $tokenRegex, $regOpts)

		$tokens = ($tokens | ? {$_.Length -gt 0})
        foreach($token in $tokens){
			$key = $token.Groups[2].Value
			
			$envValue = $envVars | ? { $_.Name -ieq $key}
			if($envValue -ne $null) 
			{
				Write-Host "Replacing key $key"
				$line = $line.Replace($token.Groups[1].Value, $envValue.Value)
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
    } | Set-Content -Path $filePath -Encoding $fileEncoding

	if($paramNotFound -and $treatWarningsAsError)
	{
		Write-Host "##vso[task.logissue type=error;sourcepath=$filePath;]Missing parameters in this file"
		throw "Missing parameter in $filePath"
	}
}

try 
{
	[bool] $treatWarningsAsError = [bool]::Parse($warningAsError)
	Resolve-Token -filePath $filePath -tokenRegex $tokenRegex -treatWarningsAsError $treatWarningsAsError -Verbose -Debug -ErrorAction Stop -fileEncoding $fileEncoding
} 
catch
{
	Write-Host "##vso[task.logissue type=error;]$_"
	throw
}
finally
{

}