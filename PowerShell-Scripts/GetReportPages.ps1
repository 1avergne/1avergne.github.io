## paramètres 
$workspaceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du Workspace
$reportId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du raport

$report = Get-PowerBIReport -WorkspaceId $workspaceId -Id $reportId
$reportId = $report.Id


$pages = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/reports/$reportId/pages" -Method Get | ConvertFrom-Json).value
$pages