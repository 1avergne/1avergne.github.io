# Récupérer le planning de traitement des jeux de données

<p style="text-align: right;">2021-09-15</p>

Lorsqu'on commence à avoir beaucoup de jeux de données déployés sur une instance Power BI, il est intéressant de connaitre la planification des traitements. Cela permet par exemple d'identifier si trop de traitements sont lancés en même temps (ce qui peut poser problème dans une capacité Premium).

Toutes ces infos sont accessibles sur le portail Power BI, et donc depuis l'[API](https://learn.microsoft.com/en-us/rest/api/power-bi/). Mais plutôt consulter le planning de rafraichissement dataset par dataset, on va récupérer l'ensemble des infos grâce à un script _PowerShell_.

Le script utilise les [Cmdlets Power BI](https://learn.microsoft.com/en-us/powershell/power-bi/overview). Il boucle sur l'ensemble des jeux de données d'un espace de travail. Les résultats sont écrits dans un fichier JSON.

```powershell
## connection au compte Power BI
Try{
    $token = Get-PowerBIAccessToken
}
Catch{
    ##save credentials
    #$password = get-content .\MyCred.csv | convertto-securestring
    #$username = "1avergne@corpo.org" 
    #$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
    #Connect-PowerBIServiceAccount -Credential $credentials

    ##don't save credentials
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

$filePath = './refreshSchedule.json'
Add-Content -Path $filePath -Value $($array | ConvertTo-Json)
```

Après il suffit de faire un rapport Power BI alimenté par ce fichier. Mais ça, vous savez le faire 😉.

