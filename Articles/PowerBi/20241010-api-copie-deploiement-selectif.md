# API : copie de rapport et rétro-déploiement 

<p style="text-align: right;">2024-10-10</p>

Sur un projet Power BI, j’utilise les [pipelines de déploiement](https://learn.microsoft.com/fr-fr/fabric/cicd/deployment-pipelines/get-started-with-deployment-pipelines) pour gérer le cycle de vie de mes rapports. Avec une petite subtilité certains rapports, une fois en production, doivent également être déployés sur d’autres Workspaces (qui ne sont pas dans le pipeline).

![image](/Images/20241010-api-copie-deploiement-selectif/worspaces.png)

## Copie de rapport

Je ne peux pas déployer les rapports depuis Power BI Desktop (ce qui reviendrait à déployer directement une version de développement en production). Je ne souhaite pas faire de copie à la main, et je ne veux surtout pas supprimer les rapports existants car les identifiants ne seraient pas les mêmes à la republication.
Il faut donc que je duplique les rapports en production sur les rapports des Workspaces spécifiques. 
Et comme souvent je vais utiliser un de mes outils préférés : le [PowerShell](https://learn.microsoft.com/en-us/powershell/power-bi/overview) !

```powershell
## paramètres         xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
$sourceWorkspaceId = "4lf412e1-xxxx-xxxx-xxxx-dff4623aca0a" ## ID du workspace contenant le rapport source 
$sourceReportId =    "2arcz3cb-xxxx-xxxx-xxxx-bb2ed1e016e2" ## ID du rapport source
$targetWorkspaceId = "a0ec00e6-xxxx-xxxx-xxxx-fa843bddcee2" ## ID du workspace contenant le rapport à mettre à jour
$targetReportId =    "c25c299d-xxxx-xxxx-xxxx-206gti019d4b" ## ID du à mettre à jour

## connection au compte Power BI
Connect-PowerBIServiceAccount 

## test de l'existance des rapports
(Get-PowerBIReport -Id "$sourceReportId" -WorkspaceId "$sourceWorkspaceId").Name 
(Get-PowerBIReport -Id "$targetReportId" -WorkspaceId "$targetWorkspaceId").Name 

## forge de la requête
$uri = "https://api.powerbi.com/v1.0/myorg/groups/$targetWorkspaceId/reports/$targetReportId/UpdateReportContent"
$body = ([pscustomobject]@{sourceReport=@{sourceReportId="$sourceReportId"; sourceWorkspaceId="$sourceWorkspaceId"}; sourceType="ExistingReport"} | ConvertTo-Json -Depth 2 -Compress)
   
## appel
Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body
```


## Déploiement sélectif 

Deuxième problème, à la suite d’une modification de jeu de données sur les rapports déployés (en dev / recette / production). La publication depuis Power BI Desktop ne fonctionnait plus : les rapports de dev n’étaient pas mis à jour dans le service Power BI. Je ne voulais pas supprimer les rapports et repartir de zéro car cela aurait modifié les identifiants des rapports en recette et production (identifiant déjà utilisé à divers endroits et notamment par les Q&A).

Il a donc fallu que je supprime les rapports déployés en dev et que je redescende la version de recette en utilisant le pipeline.

![image](/Images/20241010-api-copie-deploiement-selectif/worspaces_selective_deploy.png)

On refait chauffer le [PowerShell](https://learn.microsoft.com/en-us/powershell/power-bi/overview). Le script utilise les identifiants du pipeline et des rapports à rétro-déployer. Le paramètre *sourceStageOrder* indique qu'on utilise les rapports en recette (0 = DEV), 1 = REC, 2 = PROD). Et le paramètre *isBackwardDeployment* indique qu'il s'agit d'un déploiement à une étape antérieure.

```powershell
## paramètres
$pipelineID = "1232lol5-xxxx-xxxx-xxxx-b115Abc103ae" ## Identifiant du pipeline

$requestBody = '{
  "sourceStageOrder": 1,
  "isBackwardDeployment": true,
  "reports": [
    {
      "sourceId": "10mib70b-xxxx-xxxx-xxxx-3dd87757145b",
      "options": {
        "allowCreateArtifact": true
      }
    },
    {
      "sourceId": "5d470895-xxxx-xxxx-xxxx-3b00b5e8d559",
      "options": {
        "allowCreateArtifact": true
      }
    }
  ],
  "note": "BackwardDeployment ..."
}'

## connection au compte Power BI
Connect-PowerBIServiceAccount 

## test de l'existance du pipeline
$uri = "https://api.powerbi.com/v1.0/myorg/pipelines/$pipelineID/stages"
Invoke-PowerBIRestMethod -Url $uri -Method Get


## forge de la requête
$uri = "https://api.powerbi.com/v1.0/myorg/pipelines/$pipelineID/deploy"
$body = ConvertFrom-Json $requestBody | ConvertTo-Json -Depth 3 -Compress

## appel
Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body
```
Et pour aller plus loin, la documentation est [là](https://learn.microsoft.com/en-us/rest/api/power-bi/pipelines/selective-deploy).