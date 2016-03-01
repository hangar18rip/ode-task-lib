Clear-Host
$cur = Join-Path $PSScriptRoot "..\tasks" -Resolve
$script = Join-Path $PSScriptRoot "Update-TaskVersion.ps1" -Resolve
Get-ChildItem -Path $cur -Directory | % {
	"$script $($_.FullName)"
	Invoke-Expression "$script $($_.FullName)"

	Write-Host "tfx build tasks upload --task-path ""$($_.FullName)"" --overwrite"
	& tfx build tasks upload --task-path "$($_.FullName)" --overwrite
}
