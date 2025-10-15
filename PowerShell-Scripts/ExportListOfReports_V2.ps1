<# 
	Enregistre la liste des jeux de données et des rapports pour un espace de travail choisi
#>

#connect-powerbIServiceAccount 

##choix workspace 
write-host "Workspaces disponibles :"
$workspaces = Get-PowerBIWorkspace 
$workspaces | ForEach-Object {
    $_.name
}
$workspaceName = "CORPO OUEST" ## ✍
$workspace = $workspaces | Where-Object {$_.name -like $workspaceName }
$workspaceID = $workspace.id.Guid

###reports

$reports = Get-PowerBIReport -WorkspaceId $workspaceId 

$i = 1
$j = $reports.Count
$reportsArray = @()
$reports | ForEach-Object {
    $reportId = $_.Id
    $OutFilePath = ".\" + $_.name + ".pbix"
    write-host "($i/$j) $reportId"
    ##
    Export-PowerBIReport -WorkspaceId $workspaceID -Id $reportId -OutFile $OutFilePath -Verbose
    ##
    if(Test-Path $OutFilePath -PathType Leaf){
        $reportsArray += $_
    }
    $i++
}

#Set-Clipboard -Value $($reportsArray | ConvertTo-Csv)

###dataflows

$dataflows = Get-PowerBIDataflow -WorkspaceId  $workspaceID 

$i = 1
$j = $dataflows.Count
$dataflowsArray = @()
$dataflows | ForEach-Object {
    $dataflowId = $_.id
    $OutFilePath = ".\" + $_.name + ".json"
    write-host "($i/$j) $dataflowId"
    $dataflow =$_

    Export-PowerBIDataflow -WorkspaceId $workspaceID -Id $dataflowId -OutFile $OutFilePath -Verbose
    if(Test-Path $OutFilePath -PathType Leaf){
        $dataflowsArray += $_
    }
    $i++
}




###datasets
$datasets = Get-PowerBIDataset -WorkspaceId  $workspaceID 
$i = 1
$j = $datasets.Count
$datasetsArray = @()
$datasets | ForEach-Object {
    $datasetId = $_.id
    write-host "($i/$j) $datasetId"
    #Export-PowerBIReport -WorkspaceId $workspaceID -Id $datasetId -OutFile "prout" -Verbose

    $datasetsArray += $dataset 
    $i++
}