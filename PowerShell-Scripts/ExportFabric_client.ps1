# Script qui parcourt l'ensemble des espaces de travail pour exporter les objets.
# Le script export vers un répertoire local ou un conteneur Azure. 
# L’API Fabric est utilisée pour les objets de types "Report", "SemanticModel", "DataPipeline", "Notebook". L’API Power BI est utilisée pour l’export des objets "Dataflow" (gen1 et gen2). Les rapports paginés ne sont pas exportés.

## 📖
## https://learn.microsoft.com/en-us/rest/api/fabric/articles/using-fabric-apis
## https://learn.microsoft.com/fr-fr/rest/api/power-bi/
## https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-powershell


#application 
$clientId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # identifiant de l'app Azure
$clientSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # secret de l'app Azure

#blob container 
$containerName = "" # le nom du conteneur Azure. Laisser à vide pour ne pas enregistrer sur Azure.
$storageAccountConnectionString = ""

#powerbi
$tenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"        

#other param
$workspacesToExport = @("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "WK_xxxxxxx") #liste des Workspaces à exporter (nom ou ID), laisser vide "@()" pour tout prendre
$rootPath = 'C:/ExportFabric' # le chemin absolu ("C:/...") vers le repertoire local d'export. Laisser à vide pour ne pas enregistrer en local.
$verbose = 1 # mettre à 1 pour afficher les commentaire lors de l'execution

### pas de paramétrage sous cette ligne ###

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss" 

#api scope
$pbiScope = "https://analysis.windows.net/powerbi/api/.default"
$fabScope = "https://api.fabric.microsoft.com/.default"

#export fabric
$exportableTypes = @("Report", "SemanticModel", "DataPipeline", "Notebook")
$exportableTypes = @("Report", "SemanticModel")
# not supported : "Dashboard", "PaginatedReport", "Eventhouse", "KQLDatabase", "Eventstream", ...
# not supported nor visible in the api : "Dataflows"

#blob container - client
if($containerName -ne ""){
    #Install-Module -Name Azure.Storage.Blobs -Force -AllowClobber    
    #Import-Module Azure.Storage.Blobs #pas nécessaire
    $azStorageContext = New-AzStorageContext -ConnectionString $storageAccountConnectionString # crée un contexte, indispensable pour l'instruction suivante
    $blobServiceClient = [Azure.Storage.Blobs.BlobServiceClient]::new($azStorageContext.ConnectionString) #::new($storageAccountConnectionString) #Create a BlobServiceClient
    $containerClient = $blobServiceClient.GetBlobContainerClient($containerName) #Get a reference to the container
}

#POWER BI CLIENT TOKEN 

$clientHeader = @{ContentType = "application/json"}

$clientUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$clientResponse = @{}
$pbiToken = ""

$clientBody = @{
    ContentType = "application/json"
    grant_type = "client_credentials"
    client_id = $clientId
    client_secret = $clientSecret
    scope = $pbiScope
}
$clientResponse = Invoke-RestMethod -Method 'POST' -Uri $clientUrl -Headers $clientHeader -Body $clientBody
$pbiToken = $clientResponse.access_token

if($pbiToken.Length -eq 0) {
    # exit 1
}

#FABRIC CLIENT TOKEN 

$clientResponse = @{}
$clientBody = @{
    ContentType = "application/json"
    grant_type = "client_credentials"
    client_id = $clientId
    client_secret = $clientSecret
    scope = $fabScope
}
$clientResponse = Invoke-RestMethod -Method 'POST' -Uri $clientUrl -Headers $clientHeader -Body $clientBody
$fabToken = $clientResponse.access_token

#FABRIC API USAGE

$fabHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$fabHeader.Add("Content-Type", "application/json")
$fabHeader.Add("Authorization", "Bearer $fabToken")

## workspaces ######################
$workspacesUrl = "https://api.fabric.microsoft.com/v1/workspaces"
$workspacesResponse = @{}
$workspacesResponse = Invoke-RestMethod -Method 'GET' -Uri $workspacesUrl -Headers $fabHeader

$workspaces = [array]$($workspacesResponse.value | Where-Object{ $workspacesToExport.count -eq 0 -or $_.displayName -in $workspacesToExport -or $_.id -in $workspacesToExport})
if($verbose -gt 0){Write-Output( $workspaces.Count.ToString() + " workspace(s) to export")} # '-_-

foreach($workspace in $workspaces) #test le nom et l'ID des Workspaces
{
    $workspaceId = $workspace.id
    $workspaceName = $workspace.displayName

    if($verbose -gt 0){Write-Output("- Workspace : $workspaceName ($workspaceId)")} # '-_-

### items ######################
    $itemsUrl = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/items"
    $itemsResponse = @{}
    $itemsResponse = Invoke-RestMethod -Method 'GET' -Uri $itemsUrl -Headers $fabHeader

    foreach($item in $($itemsResponse.value | Where-Object{ $_.type -in $exportableTypes} | Where-Object{ $_.displayName -ne 'Report Usage Metrics Model'}) )
    {
        $itemId = $item.id
        $itemName = $item.displayName 
        $itemType = $item.type

        if($verbose -gt 0){Write-Output("-- Item : $itemName ($itemId)")} # '-_-

        $getdefUrl = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/dataPipelines/$itemId/getDefinition"        
        
        $getdefResponse = @{}
        $getdefResponse = Invoke-WebRequest  -Method 'POST' -Uri $getdefUrl -Headers $fabHeader

        $parts = [System.Collections.ArrayList]::new() # liste vide
        if($getdefResponse.StatusCode -eq 200)
        {
            $parts = $($getdefResponse.Content | ConvertFrom-Json).definition.parts
        }
        elseif($getdefResponse.StatusCode -eq 202)
        {

            $opeUrl = $getdefResponse.Headers.Location

            $delayMSec = 800
            do{
                Start-Sleep -Milliseconds $delayMSec
                
                $opeResponse = @{}
                $opeResponse = Invoke-RestMethod -Method 'GET' -Uri $opeUrl -Headers $fabHeader   
                $delayMSec += 1000
                
                if($verbose -gt 0 -and $delayMSec -gt 999){Write-Output("   Operation getDefinition is running. Wait $delayMSec msec")} # '-_-     
            }while($opeResponse.status -eq "Running")

            if($opeResponse.status -eq "Succeeded")
            {
                $resultUrl = "$opeUrl/result"
                $resultResponse = @{}
                $resultResponse = Invoke-RestMethod  -Method 'GET' -Uri $resultUrl -Headers $fabHeader

                $parts = $resultResponse.definition.parts
            }
        }

### parts ######################  
        foreach($part in $parts)
        {  
            if($verbose -gt 0){Write-Output('--- Part : ' + $part.path)} # '-_-
            
            $partBytes = [Convert]::FromBase64String($part.payload) 

            #### local storage 
            if($rootPath -ne "")
            {
                $partPath = $("$rootPath/$workspaceName/$timestamp/$itemName.$itemType/" + $part.path)#.Replace('/', '\').Replace('\\', '\') 
                $null = New-Item -Path $partPath.Substring(0, $partPath.LastIndexOf('/')) -ItemType Directory -Force 
                [IO.File]::WriteAllBytes($partPath, $partBytes)
            }
         
            #### Azure container : temp file
            #$partBytes = [Convert]::FromBase64String($part.payload)  
            #$blobName = $("$workspaceName/$timestamp/$itemName.$itemType/" + $part.path).Replace('/', '\').Replace('\\', '\')   
            #$tempFilePath = [System.IO.Path]::GetTempFileName()
            #[System.IO.File]::WriteAllBytes($tempFilePath, $partBytes)

            #$null = Set-AzStorageBlobContent -File $tempFilePath -Container $containerName -Blob $blobName -Context $storageContext -Force
            #Set-AzStorageBlobContent -Stream $partBytes -Container $containerName -Blob $blobName -Context $storageContext -Force 
            #Remove-Item $tempFilePath

            #### Azure container : stream
            if($containerName -ne "" -and $storageAccountConnectionString -ne "")
            { 
                $fileStream = New-Object -TypeName 'System.IO.MemoryStream' -ArgumentList(,$partBytes)
            
                $blobName = $("$workspaceName/$timestamp/$itemName.$itemType/" + $part.path)#.Replace('/', '\').Replace('\\', '\')   
                $blobClient = $containerClient.GetBlobClient($blobName) #Get a reference to the blob
            
                $null = $blobClient.Upload($fileStream, $true) #Upload the file stream to the blob
                $fileStream.Close() #Close the file stream
            }
            
        }
    }
     
### dataflows ######################
    $dataflowsUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/dataflows"

    $dataflowsResponse = @{}
    $dataflowsResponse = Invoke-RestMethod -Method 'GET' -Uri $dataflowsUrl -Headers $pbiHeader

    foreach($dataflow in $dataflows)
    { 
        $dataflowId = $dataflow.objectId 
        $dataflowName = $dataflow.name
        
        $dataflowUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/dataflows/$dataflowId"

        $dataflowResponse = @{}
        $dataflowResponse = Invoke-RestMethod -Method 'GET' -Uri $dataflowUrl -Headers $pbiHeader
                
        $partBytes = [System.Text.Encoding]::UTF8.GetBytes($($dataflowResponse | ConvertTo-Json -Depth 15))

        #### local storage 
        if($rootPath -ne "")
        {
            $partPath = $("$rootPath/$workspaceName/$timestamp/$dataflowName.Dataflow.json")
            $null = New-Item -Path $partPath.Substring(0, $partPath.LastIndexOf('/')) -ItemType Directory -Force 
            [IO.File]::WriteAllBytes($partPath, $partBytes)
        }
        
        #### Azure container : stream
        if($containerName -ne "" -and $storageAccountConnectionString -ne "")
        {
            $fileStream = New-Object -TypeName 'System.IO.MemoryStream' -ArgumentList(,$partBytes)
                
            $blobName = $("$workspaceName/$timestamp/$dataflowName.Dataflow.json")
            $blobClient = $containerClient.GetBlobClient($blobName) #Get a reference to the blob
            
            $null = $blobClient.Upload($fileStream, $true) #Upload the file stream to the blob
            $fileStream.Close() #Close the file stream
        }
    }
}