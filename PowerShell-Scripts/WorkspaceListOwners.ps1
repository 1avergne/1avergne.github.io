<# 
	Enregistre la liste des jeux de données et des rapports pour un espace de travail choisi
#>

##choix workspace 
write-host "Workspaces disponibles :"
$workspaces = Get-PowerBIWorkspace 
$workspaces | ForEach-Object {
    $_.name
}
$workspaceName = read-host
$workspace = $workspaces | Where-Object {$_.name -like $workspaceName }
$workspaceID = $workspace.id.Guid

##liste les datasets
$datasetsArray = @()
$datasets = Get-PowerBIDataset -WorkspaceId  $workspaceID 
$i = 1
$j = $datasets.Count
$datasets | ForEach-Object {
    $datasetId = $_.id.Guid
    write-host "($i/$j) $datasetId"
    $dataset =$_
    $datasetsArray += $dataset 
    $i++
}

##liste les rapports
$reportsArray = @()
$reports = Get-PowerBIReport -WorkspaceId  $workspaceID 
$i = 1
$j = $reports.Count
$reports | ForEach-Object {
    $reportId = $_.id.Guid
    write-host "($i/$j) $reportId"
    $report =$_
    $reportsArray += $report 
    $i++
}

$workspaceRest = $workspace
Add-Member -InputObject $workspaceRest -Name "datasetsDetails" -MemberType NoteProperty -Value $datasetsArray 
Add-Member -InputObject $workspaceRest -Name "reportsDetails" -MemberType NoteProperty -Value $reportsArray 

$filePath = './powerBiObjectOwners.json'
Add-Content -Path $filePath -Value $($workspaceRest | ConvertTo-Json)

Set-Clipboard -Value $($workspaceRest.datasetsDetails | ConvertTo-Csv )
