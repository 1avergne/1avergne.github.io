#application 
$clientId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
             
$clientSecret = "chut"
$scope = "https://analysis.windows.net/powerbi/api/.default"

#powerbi
$tenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$workspaceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$reportId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$paramJson = '{
     "accessLevel": "View",
     "identities": [
       {
         "username": "ziha@corp.fr",
         "customData": "ziha@corp.fr",
         "roles": [
           "RLS GROUPEMENT"
         ],
         "datasets": [
           "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
         ]
       }
     ]
  }'

#CLIENT TOKEN 

$clientHeader = @{ContentType = "application/json"}

$clientBody = @{
    ContentType = "application/json"
    grant_type = "client_credentials"
    client_id = $clientId
    client_secret = $clientSecret
    scope = $scope
}

$clientUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$clientResponse = @{}
$appToken = ""
$clientResponse = Invoke-RestMethod -Method 'POST' -Uri $clientUrl -Headers $clientHeader -Body $clientBody
$appToken = $clientResponse.access_token

if($appToken.Length -eq 0) {
    exit 1
}

#USER TOKEN

$userHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$userHeader.Add("Content-Type", "application/json")
$userHeader.Add("Authorization", "Bearer $appToken")

$userUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/reports/$reportId/GenerateToken"

$userResponse = @{}
$userResponse = Invoke-RestMethod -Method 'POST' -Uri $userUrl -Headers $userHeader -Body $paramJson 

$userResponse.token