# connect-powerbIServiceAccount

$workspaces = Get-PowerBIWorkspace | Where-Object{$_.Name -in ("WS-XXXXX")}

$t = "flowchart LR"
write-host "flowchart LR"

$matchPatern = '.*patern.*'
$notMatchPatern = ''

$staticDeclaration = "subgraph ""WS-XXXX""
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx([patern])
end
end
"

# fin du paramétrage

$t = "$t `r`n$staticDeclaration"

foreach ($ws in $workspaces){

    $workspaceName = $ws.Name

    $reports = Get-PowerBIReport -WorkspaceId $ws.Id | Where-Object{$notMatchPatern -eq '' -or $_.Name -NotMatch $notMatchPatern} | Where-Object{$matchPatern -eq '' -or $_.Name -Match $matchPatern}
    $datasets = Get-PowerBIDataset -WorkspaceId $ws.Id | Where-Object{$notMatchPatern -eq '' -or $_.Name -NotMatch $notMatchPatern} | Where-Object{$matchPatern -eq '' -or $_.Name -Match $matchPatern}

    if($reports.Count -gt 0 -or $datasets.Count -gt 0){

        write-host "subgraph ""$workspaceName"""
        $t = "$t `r`nsubgraph ""$workspaceName"""
    
        foreach ($_ in $datasets){
            $datasetID = $_.Id
            $datasetName = $_.Name
            write-host "$datasetID([""$datasetName""])"
            $t = "$t `r`n$datasetID([""$datasetName""])"
        }

        foreach ($_ in $reports){
            $reportID = $_.Id
            $reportName = $_.Name
            write-host "$reportID[""$reportName""]"
            $t = "$t `r`n$reportID[""$reportName""]"
        }

        write-host "end"
        $t = "$t `r`end"

        foreach ($_ in $reports){
            $reportID = $_.Id
            $datasetID = $_.DatasetId
            write-host "$datasetID-->$reportID"
            $t = "$t `r`n$datasetID-->$reportID"
        }
    }
}

Set-Clipboard -Value $t