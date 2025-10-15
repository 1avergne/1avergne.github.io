## connection au compte Power BI
#Connect-PowerBIServiceAccount

## paramètres 
$sourceWorkspaceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du Workspace contenant le raport à modifier
$sourceReportId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du raport à modifier
$targetWorkspaceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du Workspace contenant le raport à modifier
$targetReportId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du raport à modifier

Write-Output($reportId)

$uri = "https://api.powerbi.com/v1.0/myorg/groups/$targetWorkspaceId/reports/$targetReportId/UpdateReportContent"
$body = ([pscustomobject]@{sourceReport=@{sourceReportId="$sourceReportId"; sourceWorkspaceId="$sourceWorkspaceId"}; sourceType="ExistingReport"} | ConvertTo-Json -Depth 2 -Compress)
    
Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body