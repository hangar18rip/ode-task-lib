[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$taskDirectory
)

function Update-TaskVersion
{
	param (
        [Parameter(Mandatory = $true)]
        [String]$taskDirectory
    )

	$versionFile = Join-Path $taskDirectory "version.txt"

	if(!(Test-Path $versionFile))
	{
		Write-Warning "No version file"
		return
	}
	
	$versionRef = [System.Version]::new((Get-Content $versionFile))
	Write-Host "Current version : $versionRef"

	$taskFile = Join-Path $taskDirectory "task.json"
		if(!(Test-Path $taskFile))
	{
		Write-Warning "No task file"
		return
	}

	$files = Get-ChildItem -Path $taskDirectory -Filter * -Recurse -Exclude "*.md5"
	[bool] $mustVersion = $false
	foreach($file in $files) {
		$md5file = "$($file.FullName).md5"
		if(!(Test-Path $md5file))
		{
			Write-Host "No MD5 for '$file', must version"
			$mustVersion = $true
			break
		}
		$md5last = Get-Content $md5file
		$md5new = (Get-FileHash $file -Algorithm MD5).Hash
		
		if($md5new -ne $md5last)
		{
			Write-Host "MD5 mismatch for '$file', must version"
			$mustVersion = $true
			break
		}
	}

	if(!$mustVersion)
	{
		return
	}

	#Get-FileHash $files -Algorithm MD5

	$versionNew = [System.Version]::new($versionRef.Major, $versionRef.Minor, $versionRef.Build + 1)
	Write-Host "New version : $versionNew"
	$versionNew | Set-Content $versionFile

	$versionRef = $versionRef.ToString()

	(Get-Content $taskFile) | % {
		[System.String] $line = $_
		if($line.IndexOf($versionRef) -gt 0)
		{
			Write-Warning "$line"
			$line = $line.Replace($versionRef, $versionNew)
			Write-Warning "$line"
		}
		if($line.Trim().StartsWith("""Major"":"))
		{
			Write-Warning "$line"
			$line = """Major"": $($versionNew.Major),"
			Write-Warning "$line"
		}
		if($line.Trim().StartsWith("""Minor"":"))
		{
			Write-Warning "$line"
			$line = """Minor"": $($versionNew.Minor),"
			Write-Warning "$line"
		}
		if($line.Trim().StartsWith("""Patch"":"))
		{
			Write-Warning "$line"
			$line = """Patch"": $($versionNew.Build)"
			Write-Warning "$line"
		}
		$line
	} | Set-Content $taskFile

	$files | % {
		$md5file = "$($_.FullName).md5"
		(Get-FileHash $_ -Algorithm MD5).Hash | Set-Content $md5file
	}

}


Update-TaskVersion $taskDirectory
