##https://learn.microsoft.com/en-us/rest/api/power-bi/pipelines/selective-deploy

$pipelineID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

## https://learn.microsoft.com/en-us/rest/api/power-bi/pipelines/selective-deploy#example-of-deploying-specific-power-bi-items-(such-as-reports-or-dashboards)-from-the-'development'-stage
$requestBody = '{
  "reports": [
    {
      "sourceId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "options": {
        "allowCreateArtifact": true,
        "allowOverwriteArtifact": true
      }
    }
  ],
  "note": "BackwardDeployment"
}'

$uri = "https://api.powerbi.com/v1.0/myorg/pipelines/$pipelineID/stages"
Invoke-PowerBIRestMethod -Url $uri -Method Get

#$uri = "https://api.powerbi.com/v1.0/myorg/pipelines/$pipelineID/deploy"
$uri = "pipelines/$pipelineID/deploy"
$body = ConvertFrom-Json $requestBody | ConvertTo-Json -Depth 5 -Compress


$deployResult = Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body | ConvertFrom-Json
$deployResult 

# Resolve-PowerBIError -Last