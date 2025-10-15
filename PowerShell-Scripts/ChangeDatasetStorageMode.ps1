## paramètres 
$datasetIds = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$targetStorage = "PremiumFiles" #PremiumFiles or Abf

$verbose = 1

## pas de paramétrage en dessous de cette ligne

$now =  $(get-date -f yyyyMMdd_HHmmss)
$UpdateResult = @()

foreach($datasetId in $datasetIds){
    
    $dataset = $null
    $dataset = Get-PowerBIDataset -Scope Organization -Id $datasetId -Include actualStorage

    if($dataset -eq $null){        #le dataset n'existe pas
            $UpdateResult += [PSCustomObject]@{
            DatasetId = $datasetId
            Action = "Nothing - dataset not found"
            ActualStorage = ""
            Timestamp = $(get-date -f "yyyy-MM-dd hh:mm:ss")
        }
    }
    else{

        $actualStorage = $dataset.ActualStorage.StorageMode

        if($actualStorage -ne $targetStorage){ #le stockage actuel ne correspond pas à la cible, il est modifié
            Write-Output("dataset : $datasetId / previous format : $actualStorage / new format : $targetStorage ")

            try {
                if($verbose -gt 0){Write-Output("try")} # '-_-
        
                Set-PowerBIDataset -Id $datasetId -TargetStorageMode $targetStorage   #migration au nouveau format de stockage

                $UpdateResult += [PSCustomObject]@{
                    DatasetId = $datasetId
                    Action = "Set storage"
                    ActualStorage = $targetStorage
                    Timestamp = $(get-date -f "yyyy-MM-dd hh:mm:ss")
                }

            } catch {
                if($verbose -gt 0){Write-Output("catch")} # '-_-

                $UpdateResult += [PSCustomObject]@{
                    DatasetId = $datasetId
                    Action = "Script failed"
                    ActualStorage = $actualStorage

                    Timestamp = $(get-date -f "yyyy-MM-dd hh:mm:ss")
                }
            } #end catch

        }
        else { #le dataset est déjà au format de destination, on ne fait rien
            if($verbose -gt 0){Write-Output("else")} # '-_-

            $UpdateResult += [PSCustomObject]@{
                DatasetId = $datasetId
                Action = "Workspace skipped"
                ActualStorage = $actualStorage
                Timestamp = $(get-date -f "yyyy-MM-dd hh:mm:ss")
            }
        }
    }
}

if($verbose -gt 0){Write-Output("Export-CSV")} # '-_-
$UpdateResult | Export-CSV ".\DatasetStorageFormatAssignment.$now.csv" -NoTypeInformation

exit 0