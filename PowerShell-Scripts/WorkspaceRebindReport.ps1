## connection au compte Power BI
Connect-PowerBIServiceAccount

#xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/reports/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx


## paramètres 
$workspaceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du Workspace contenant le raport à modifier
$reportIds = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #liste des IDs des raports à modifier
$datasetId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #ID du dataset à connecter au raport à modifier

$uriWorksapcePart = ""
if($workspaceId -match "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
{
    $uriWorksapcePart = "/groups/$workspaceId"
}

## modification du rapport
foreach($reportId in  $reportIds) {
    $report = Get-PowerBIReport -Id $reportId -WorkspaceId $workspaceId
    Write-Output($report.Name)

    $uri = "https://api.powerbi.com/v1.0/myorg$uriWorksapcePart/reports/$reportId/Rebind"

    $body = ([pscustomobject]@{datasetId="$datasetId"} | ConvertTo-Json -Depth 2 -Compress)
    
   Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body
}