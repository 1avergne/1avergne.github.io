# connect-powerbIServiceAccount 

$groupId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$reportId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$format = 'PDF' #PDF #PPTX

# Get report configuration
$report = (Invoke-PowerBIRestMethod -Url "groups/$groupId/reports/$reportId" -Method Get | ConvertFrom-Json)
$reportName = $report.name

## Power BI Report Export Configuration -> https://learn.microsoft.com/en-us/rest/api/power-bi/reports/export-to-file#powerbireportexportconfiguration
##   reportLevelFilters : utiliser la syntaxe des filtresURLS
##   pages : utiliser les noms "ReportSection..." visibles dans l'URL du rapport

#config main
$exportConfiguration_0 = [pscustomobject]@{
    ##reportLevelFilters = @([pscustomobject]@{filter = "V_PBI_MD_ACCOUNT/NAME eq 'Rexel'"})
    pages = @([pscustomobject]@{pageName = "ReportSection123456789"} )
}

$postBody = [pscustomobject]@{format = $format 
    powerBIReportConfiguration = $exportConfiguration_0
} | ConvertTo-Json -Depth 3 -Compress
$postBody 

# Export To File -> https://learn.microsoft.com/en-us/rest/api/power-bi/reports/export-to-file
$export = (Invoke-PowerBIRestMethod -Url "reports/$reportId/ExportTo" -Method Post -Body $postBody) | ConvertFrom-Json
$export 
$exportId = $export.id

Do{
    Start-Sleep -Milliseconds 250
    $export = Invoke-PowerBIRestMethod -Url "reports/$reportId/exports/$exportId" -Method Get | ConvertFrom-Json
    $exportStatus = $export.status
    $exportPct = $export.percentComplete
    Write-Progress -Activity "Export from Power BI" -Status "$exportStatus ($exportPct%)" -PercentComplete $exportPct
    
}
Until($exportStatus -ne 'Running' -and $exportStatus -ne 'NotStarted')

if($exportStatus -ne 'Succeeded'){ break }

$path = $reportName + '.' + $format.ToLower()
Write-Host "download extract and write to file : $path"

$token = (Get-PowerBIAccessToken).Values
Invoke-RestMethod -Method 'GET' -ContentType application/json -Uri "https://api.powerbi.com/v1.0/myorg/reports/$reportId/exports/$exportId/file" -Headers @{ Authorization="$token" } -OutFile $path

& ".\$path"