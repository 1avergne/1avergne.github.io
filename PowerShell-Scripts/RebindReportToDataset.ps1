## connection au compte Power BI
#Connect-PowerBIServiceAccount

## paramètres 
$sourceDatasetId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID dataset à lier au rapport
$targetWorkspaceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du Workspace contenant le raport à modifier
$targetReportId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du raport à modifier

Write-Output($reportId)

$uri = "https://api.powerbi.com/v1.0/myorg/groups/$targetWorkspaceId/reports/$targetReportId/Rebind"
$body = ([pscustomobject]@{datasetId="$sourceDatasetId"} | ConvertTo-Json -Depth 2 -Compress)
    
Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body