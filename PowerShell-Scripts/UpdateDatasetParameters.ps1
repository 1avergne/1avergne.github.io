<#
.SYNOPSIS 
Met à jour les paramètres d'un jeu de données

.DESCRIPTION
Modifie la valeur des paramètres d'un jeu de données par les valeurs passées en paramètre du script. 
Si un paramètre indiqué n'existe pas dans le jeu de donnée, il est ignoré.

.PARAMETER datasetName
Specifies the file name.

.PARAMETER paramList
Liste des paramètres avec leurs valeurs au format JSON.

.PARAMETER refresheDataset
Si vrai, lance le traitement du jeu de données après la mise à jour des paramètres.

.INPUTS

.OUTPUTS

.EXAMPLE
C:\PS> UpdateDatasetParameters.ps1 -datasetName "MonRapport" -paramList '{"Instance SQL": "AZER-123", "Base de données": "SourceDb"}'

.EXAMPLE
C:\PS> UpdateDatasetParameters.ps1 -datasetName "MonRapport" -paramList '{"NbAnnéesHisto": 10}' -refresheDataset = $false

.LINK
https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-parameters

.LINK
https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/update-parameters
#>

param(
    [Parameter()] 
    [String]$datasetName
    , [String]$paramList
    , [Bool]$refresheDataset = $true
)

<#
$datasetName = "FormationDAX_EchoPilote"
$paramList = '{"Instance SQL": "AZER-123", "Base de données": "SourceDb"}'
$refresheDataset = $false
#>


##identifier le dataset
$datasets = Get-PowerBIDataset -WorkspaceId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$datasetId = $($datasets | Where-Object {$_.name -like $datasetName }).id.guid

if($datasetId -eq $null){
    Write-Error "Cant find the dataset $datasetName"
}

$currentParameters = Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/datasets/$datasetId/parameters" -Method Get

##changer les paramètre du dataset
$updatedParameters = @()
$paramList | ConvertFrom-Json | Get-Member -MemberType NoteProperty | ForEach-Object { 
    $paramName = $_.name
    $paramValue = $_.ToString().Split("=")[1]
    $paramIsValid = $false
    
    $($currentParameters | ConvertFrom-Json).value | ForEach-Object { 
        if($_.name -eq $paramName){
            $paramIsValid = $true
        }
    }

    if($paramIsValid){
        $param = New-Object -TypeName psobject
        $param | Add-Member -MemberType NoteProperty -Name name -Value $paramName
        $param | Add-Member -MemberType NoteProperty -Name newValue -Value $paramValue
        $updatedParameters += $param 
    }
}

$body = New-Object -TypeName psobject
$body | Add-Member -MemberType NoteProperty -Name updateDetails -Value $updatedParameters

Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/datasets/$datasetId/Default.UpdateParameters" -Method Post -Body $($body| ConvertTo-Json)

##recharger le dataset
if($refresheDataset){
    Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/datasets/$datasetId/refreshes" -Method Post -Body "{}" 
}

#nouveaux parametres 
Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/datasets/$datasetId/parameters" -Method Get