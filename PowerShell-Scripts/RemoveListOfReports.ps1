<# 
	Enregistre la liste des jeux de données et des rapports pour un espace de travail choisi
#>

##choix workspace 
write-host "Workspaces disponibles :"
$workspaces = Get-PowerBIWorkspace 
$workspaces | ForEach-Object {
    $_.name
}
$workspaceName = "WS_XXXXX" ## ✍
$workspace = $workspaces | Where-Object {$_.name -like $workspaceName }
$workspaceID = $workspace.id.Guid

###liste les datasets
#$datasetsArray = @()
#$datasets = Get-PowerBIDataset -WorkspaceId  $workspaceID 
#$i = 1
#$j = $datasets.Count
#$datasets | ForEach-Object {
#    $datasetId = $_.id.Guid
#    write-host "($i/$j) $datasetId"
#    $dataset =$_
#    $datasetsArray += $dataset 
#    $i++
#}

##liste les rapports
$reportsArray = @()

$reports = ("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")

$i = 1
$j = $reports.Count
$reports | ForEach-Object {
    $report = Get-PowerBIReport -WorkspaceId $workspaceID -Id $_
    if($report){
        $reportId = $report.id.Guid
        write-host "($i/$j) $reportId"
        ##
        Remove-PowerBIReport -WorkspaceId $workspaceID -Id $reportId 
        ##
        if(Test-Path $OutFilePath -PathType Leaf){
            $reportsArray += $report 
        }
    }
    $i++
}

#$workspaceRest = $workspace
#Add-Member -InputObject $workspaceRest -Name "datasetsDetails" -MemberType NoteProperty -Value $datasetsArray 
#Add-Member -InputObject $workspaceRest -Name "reportsDetails" -MemberType NoteProperty -Value $reportsArray 

#Set-Clipboard -Value $($workspaceRest.datasetsDetails | ConvertTo-Csv )

Set-Clipboard -Value $($reportsArray | ConvertTo-Csv)