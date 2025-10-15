## connection au compte Power BI
#Connect-PowerBIServiceAccount

## 📖
## https://learn.microsoft.com/fr-fr/rest/api/power-bi/capacities/groups-assign-to-capacity
## https://learn.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspacemigrationstatus?view=powerbi-ps


## paramètres 
#CURRENT
$workspaceIds = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" #"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  #"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$capacitySourceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$capacityTargetId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$verbose = 1

## pas de paramétrage en dessous ##
###################################

$AssignementResult = @()
$AssignedWorkspaceIds = @()

$now =  $(get-date -f yyyyMMdd_HHmmss)

$capacities = Get-PowerBICapacity

$capacitySource = $($capacities | Where-Object {$_.Id -like $capacitySourceId }).DisplayName
$capacityTarget = $($capacities | Where-Object {$_.Id -like $capacityTargetId }).DisplayName

if ($capacitySource.Length -eq 0 -or $capacityTarget.Length -eq 0){
    if($verbose -gt 0){Write-Output("Target capacity not found")} # '-_-
    exit 1 
}

## modification du Workspace
foreach($workspaceId in $workspaceIds) {
    $Workspace = Get-PowerBIWorkspace -Scope Organization -Id $workspaceId
    $WorkspaceName = $Workspace.name
    $WorkspaceCapacityId = $Workspace.CapacityId

    $message = "Capacity not matching with the source capacity"

    if($Workspace.State -eq "Active"){ # le Workspace est actif, on teste la capacité.
        $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/CapacityAssignmentStatus"
        try{
            $CapacityAssignmentStatus = $(Invoke-PowerBIRestMethod -Url $uri -Method Get -ErrorAction Stop) | ConvertFrom-Json
        }
        catch{ # le test de capacité est KO, le workspace ne peut pas être migré
            if($verbose -gt 0){Write-Output("Workspace $workspaceId is not accessible")} # '-_-
            $message = $(Resolve-PowerBIError -Last).Message
            $CapacityAssignmentStatus =@{}
        }
    }
    else # le Workspace n'est pas actif
    {
        if($verbose -gt 0){Write-Output("Workspace $workspaceId is not active")} # '-_-
        $message = "Workspace is not active"
        $CapacityAssignmentStatus =@{}
    }
   
    if($CapacityAssignmentStatus.CapacityId -eq $capacitySourceId -and $CapacityAssignmentStatus.status -eq "CompletedSuccessfully"){ #le workspace est bien dans la capacité à migrer

        Write-Output("workspace : $workspaceId / previous capacity : $capacitySourceId / new capacity : $capacityTargetId ")

        if($verbose -gt 0){Write-Output("Try to assign the capacity $capacityTargetId to workspace $workspaceId")} # '-_-

        $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/AssignToCapacity"
        $body = ([pscustomobject]@{capacityId="$capacityTargetId"} | ConvertTo-Json -Depth 2 -Compress)
            
        try{
            #Execution de la migration
            Invoke-PowerBIRestMethod -Url $uri -Method Post -Body $body -ErrorAction Stop

            #Temporise 5 sec
            Start-Sleep -Seconds 5;
            
            # ajouter le workspace à une liste
            $AssignedWorkspaceIds += $workspaceId
        } catch {
            $message = $(Resolve-PowerBIError -Last).Message

            if($verbose -gt 0){Write-Output("Error occurred while trying to assign the capacity $capacityTargetId to workspace $workspaceId")} # '-_-

            #$uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/CapacityAssignmentStatus"
            $CapacityAssignmentStatus = $(Invoke-PowerBIRestMethod -Url $uri -Method Get) | ConvertFrom-Json

            $AssignementResult += [PSCustomObject]@{
                WorkspaceId = $workspaceId
                Action = "Script failed"
                Message = $message
                Status = $CapacityAssignmentStatus.status
                StartTime = $CapacityAssignmentStatus.startTime
                EndTime = $CapacityAssignmentStatus.endTime
                CapacityId = $CapacityAssignmentStatus.capacityId
                ActivityId = $CapacityAssignmentStatus.activityId
            }
        }
    }else{ #le workspace n'est pas migré, on enregistre son état courant
        if($verbose -gt 0){Write-Output("Workspace $workspaceId skipped, $message")} # '-_-

        $AssignementResult += [PSCustomObject]@{
            WorkspaceId = $workspaceId
            Action = "Workspace skipped"
            Message = $message
            Status = $CapacityAssignmentStatus.status
            StartTime = $CapacityAssignmentStatus.startTime
            EndTime = $CapacityAssignmentStatus.endTime
            CapacityId = $CapacityAssignmentStatus.capacityId
            ActivityId = $CapacityAssignmentStatus.activityId
        }
    }

}

if($verbose -gt 0){Write-Output("Wait 90 sec")} # '-_-
Start-Sleep -Seconds 30;
if($verbose -gt 0){Write-Output("Wait 60 sec")} # '-_-
Start-Sleep -Seconds 30;
if($verbose -gt 0){Write-Output("Wait 30 sec")} # '-_-
Start-Sleep -Seconds 30;

foreach($workspaceId in $AssignedWorkspaceIds) { #test du resultat de la migration pour chaque workspace
    if($verbose -gt 0){Write-Output("Check the assignment of the capacity $capacityTargetId to workspace $workspaceId")} # '-_-

    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/CapacityAssignmentStatus"
    $CapacityAssignmentStatus = $(Invoke-PowerBIRestMethod -Url $uri -Method Get) | ConvertFrom-Json

    # ajouter le workspace à une liste
    $AssignementResult += [PSCustomObject]@{
        WorkspaceId = $workspaceId
        Action = "New assignement"
        Message = ""
        Status = $CapacityAssignmentStatus.status
        StartTime = $CapacityAssignmentStatus.startTime
        EndTime = $CapacityAssignmentStatus.endTime
        CapacityId = $CapacityAssignmentStatus.capacityId
        ActivityId = $CapacityAssignmentStatus.activityId
    }
}

$AssignementResult | Export-CSV ".\CapacityAssignment.$capacityTarget.$now.csv" -NoTypeInformation

exit 0