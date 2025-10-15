## connection au compte Power BI
#Connect-PowerBIServiceAccount

## 📖
## https://learn.microsoft.com/fr-fr/rest/api/power-bi/capacities/groups-assign-to-capacity
## https://learn.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspacemigrationstatus?view=powerbi-ps


## paramètres 
$workspaceIds = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #liste des espaces de travail
$capacityId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$proceed = 0
if($workspaceId -eq "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"){ $proceed = 1 }

## modification du rapport
foreach($workspaceId in  $workspaceIds) {
    Write-Output($workspaceId)
    Write-Output("====================================")

    Get-PowerBIWorkspace -Id $workspaceId

    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/CapacityAssignmentStatus"
    $(Invoke-PowerBIRestMethod -Url $uri -Method Get) | ConvertFrom-Json

    if($proceed -eq 1){
        Write-Output("=== assign to specified capacity ===")
        $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/AssignToCapacity"
        $body = ([pscustomobject]@{capacityId="$capacityId"} | ConvertTo-Json -Depth 2 -Compress)
        Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body
        
        Write-Output("==== capacity assignment status ====")
        $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/CapacityAssignmentStatus"
        $(Invoke-PowerBIRestMethod -Url $uri -Method Get) | ConvertFrom-Json
    }


}
