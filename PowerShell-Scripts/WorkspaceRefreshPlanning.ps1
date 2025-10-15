## connection au compte Power BI
Try{
    $token = Get-PowerBIAccessToken
}
Catch{
    Connect-PowerBIServiceAccount
    $token = Get-PowerBIAccessToken
}

##choix workspace 
write-host "Workspaces disponibles :"
$workspaces = Get-PowerBIWorkspace 
$workspaces | ForEach-Object {
    $_.name
}
$workspaceName = read-host
$workspaceID = ($workspaces | Where-Object {$_.name -like $workspaceName }).id.Guid

##liste les datasets
$array = @()
$datasets = Get-PowerBIDataset -WorkspaceId  $workspaceID 
$i = 1
$j = $datasets.Count
$datasets | ForEach-Object {
    $datasetId = $_.id.Guid
    write-host "($i/$j) $datasetId"
    $dataset =$_
    if($_.IsRefreshable -eq "True") {
        $refreshSchedule = Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/groups/$workspaceID/datasets/$datasetId/refreshSchedule" -Method Get | ConvertFrom-Json
        Add-Member -InputObject $dataset -Name "refreshSchedule" -MemberType NoteProperty -Value $refreshSchedule 

        $refreshHistory = Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/groups/$workspaceID/datasets/$datasetId/refreshes" -Method Get | ConvertFrom-Json
        Add-Member -InputObject $dataset -Name "refreshHistory" -MemberType NoteProperty -Value $refreshHistory 
    }
    $array += $dataset 
    $i++
}

$filePath = './refreshSchedule202403.json'
Add-Content -Path $filePath -Value $($array | ConvertTo-Json)

Set-Clipboard -Value $($workspaceRest.datasetsDetails | ConvertTo-Csv )