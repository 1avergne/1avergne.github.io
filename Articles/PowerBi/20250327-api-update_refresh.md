# API - configurer et rafraichir un modèle

<p style="text-align: right;">2025-03-27</p>

Pour limiter la taille d'un fichier .pbix ou simplement garder le volume de données à charger acceptable par Power BI Desktop, il est habituel d’utiliser des paramètres dans Power Query. Ces paramètres permettent de filtrer les requêtes sources et donc de réduire la volumétrie.

![image](/Images/20250327-api-update_refresh/20250327-api-update_refresh_query_dependances.png)

Après la publication d’un rapport, il est nécessaire de modifier ces paramètres pour charger les données en intégralité.

## Dans les paramètres du modèle

La solution la plus simple est de modifier manuellement les paramètres dans les paramètres du modèle (il y a une certaine logique 😓). 

![image](/Images/20250327-api-update_refresh/20250327-api-update_refresh_param_web.png)

Il ne faut pas oublier d’enregistrer la mise à jour en cliquant sur _Appliquer_ !
Une fois les paramètres modifiés, il suffit de lancer un traitement du modèle.

## Dans le Pipeline de déploiement

Si on utilise un [Pipeline de déploiement](https://learn.microsoft.com/fr-fr/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines), il est possible de définir des paramètres spécifiques à un environnement. Lors de la publication vers un nouvel espace de travail, les paramètres du modèle sémantique seront mis à jour selon la configuration du Pipeline.
Tout ça se configure dans les règles de déploiement ; comme souvent [la documentation Microsoft](https://learn.microsoft.com/fr-fr/fabric/cicd/deployment-pipelines/create-rules) explique très bien la marche à suivre.

[![image](https://learn.microsoft.com/fr-fr/fabric/cicd/deployment-pipelines/media/create-rules/deployment-rules-new.png)](https://learn.microsoft.com/fr-fr/fabric/cicd/deployment-pipelines/create-rules)

## Avec l’API Power BI

L’API Power BI c’est le moyen d’automatiser toutes les actions manuelles que l’on fait habituellement via le portail Power BI.
Avec le bon script, il suffit d’appeler une commande qui indique le nom du jeu de données et les nouveaux paramètres pour avoir en quelques instants un modèle configuré et en cours de rafraichissement !

```powershell
.\UpdateDatasetParameters.ps1 -datasetName "Météo" -paramList '{"Nombre de mois": 36}' -refresheDataset $True
```

Et voici le code du script _UpdateDatasetParameters.ps1_ :

```powershell
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
$datasets = Get-PowerBIDataset
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
```