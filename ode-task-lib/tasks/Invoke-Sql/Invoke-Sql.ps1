[CmdletBinding()]
param(
	[string] $commandSource,
	[string] $scriptFile,
	[string] $script,
	[string] $TargetMethod,
	[string] $SqlInstance,
	[string] $DatabaseName,
	[string] $SqlUsername,
	[string] $SqlPassword,
	[string] $ConnectionString
)

function Invoke-Sql {
    param (
		[string] $commandSource,
		[string] $scriptFile,
		[string] $script,
		[string] $TargetMethod,
		[string] $SqlInstance,
		[string] $DatabaseName,
		[string] $SqlUsername,
		[string] $SqlPassword,
		[string] $ConnectionString
    )

	Write-Host "commandSource       : $commandSource"
	Write-Host "scriptFile          :  $scriptFile"
	Write-Host "script              : $script"
	Write-Host "TargetMethod        : $TargetMethod"
	Write-Host "SqlInstance         : $SqlInstance"
	Write-Host "DatabaseName        : $DatabaseName"
	Write-Host "SqlUsername         : $SqlUsername"
	Write-Host "SqlPassword         : *************"
	Write-Host "ConnectionString    : $ConnectionString"


	if($commadSource -ieq "filePath")
	{
		$script = (Get-Content $scriptFile)
	}

	if($TargetMethod -ieq "server")
	{
		[System.Data.SqlClient.SqlConnectionStringBuilder] $csBuild = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
		$csBuild.psBase.DataSource = $SqlInstance
		$csBuild.psBase.InitialCatalog = $DatabaseName
		if(([string]::IsNullOrEmpty($SqlUserName) -ne $true) -and ([string]::IsNullOrEmpty($SqlPassword) -ne $true))
		{
			$csBuild.psBase.UserID = $SqlUsername
			$csBuild.psBase.Password = $SqlPassword
		} else {
			Write-Host "Using integrated security"
			$csBuild.psBase.IntegratedSecurity = $true;
		}
		$csBuild.psBase.ApplicationName = "PowerShell"

		$ConnectionString = $csBuild.ConnectionString
	}

	try
	{
		$connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
		$command = [System.Data.SqlClient.SqlCommand]::new()
		$command.psbase.Connection = $connection
		$command.psbase.CommandText = $script
		$command.psbase.CommandType = [System.Data.CommandType]::Text

		$connection.Open()
		$res = $command.ExecuteNonQuery()

		Write-Host "Res : $res"
	}
	finally
	{
		if($command -ne $null)
		{
			$command.Dispose()
		}
		if($connection -ne $null)
		{
			$connection.Dispose()
		}
	}

}

Invoke-Sql -commandSource $commandSource -scriptFile $scriptFile -script $script -TargetMethod $TargetMethod -SqlInstance $SqlInstance -DatabaseName $DatabaseName -SqlUsername $SqlUsername -SqlPassword $SqlPassword -ConnectionString $ConnectionString
