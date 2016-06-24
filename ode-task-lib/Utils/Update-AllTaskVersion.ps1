Clear-Host
$cur = Join-Path $PSScriptRoot "..\tasks" -Resolve
$script = Join-Path $PSScriptRoot "Update-TaskVersion.ps1" -Resolve
Get-ChildItem -Path $cur -Directory | % {
	$command = "& '$script' -taskDirectory `"$($_.FullName)`""
	Write-Host $command
	Invoke-Expression $command

	Write-Host "tfx build tasks upload --task-path ""$($_.FullName)"" --overwrite"
	& tfx build tasks upload --task-path "$($_.FullName)" --overwrite
}
