connect-powerbIServiceAccount

#Gets User, workspace, workspaceId 
$capacityIds = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$exportPath = "C:\ExportFabric"
$latestLnkName = "0_latest"

### pas de paramétrage sous cette ligne ###

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss" 

$groups = Get-PowerBIWorkspace -Scope Organization -Include Dataflows -All | Where-Object {$capacityIds -contains $_.CapacityId}
#| Where-Object {$_.CapacityId -eq $CapacityId}

foreach($group in $groups | Where-Object {$($_.Dataflows | Measure-Object).Count -gt 0} )
{
    $groupName = $group.Name
    $groupId = $group.Id

    $groupExportPath = $("$exportPath\$groupName\$timestamp")
        $d = New-Item -ItemType Directory -Path $groupExportPath -Force
        
        if($latestLnkName -ne "")
        {
            $wshShell = New-Object -COMObject WScript.Shell
            $latestLnk = $wshShell.CreateShortcut("$exportPath\$groupName\$latestLnkName.lnk")
            $latestLnk.TargetPath = $d.FullName
            $latestLnk.Save()
        }


    foreach($dataflow in $group.Dataflows)
    {
        $dataflowName = $dataflow.Name
        $dataflowId = $dataflow.Id

        
        Write-Host("Dataflow $dataflowName in workspace $groupName will be exported")
        
        cd $("$exportPath\$groupName\$timestamp").Replace('[', '`[').Replace(']', '`]') 
        try{
            Export-PowerBIDataflow -WorkspaceId $groupId -Id $dataflowId -OutFile ".\$dataflowName.Dataflow.json" -ErrorAction Stop
        }
        catch{ # KO, le dataflow ne peut pas être exporté
            $message = $(Resolve-PowerBIError -Last).Message
            Write-Host("    Export Failed : $message")
        }

    }

}