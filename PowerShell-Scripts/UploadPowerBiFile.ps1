<#
Charge un fichier .pbix dans le service Power BI.
#>

param(
    [Parameter()]
    [String]$objectName = "MonRapport"
    ,[String]$filePath = "C:\Users\alavergne\Documents\EchoPilote-sanddata.pbix" 
    ,[String]$uploadOnlyDataset = $true
)

#uploadreport
$newReport = New-PowerBIReport -Path $filePath -Name $objectName

#delete uploaded report
if($uploadOnlyDataset){
    $reportId = $newReport.id.guid
    Remove-PowerBIReport -Id $reportId
}