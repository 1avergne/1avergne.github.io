# Tester l'état d'une instance SSAS

Pour un projet avec du SSAS multidimensionnel, j'ai eu besoin de mettre en place une solution de monitoring pour tester si l'instance SSAS est bien accessible aux utilisateurs et si les cubes sont traités. Pour cela j'ai utilisé la commande [Invoke-ASCmd](https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-ascmd) dans PowerShell.

![image](/Images/ssas-etat-instance.png)

Cette commande permet d'exécuter du code [MDX](https://docs.microsoft.com/fr-fr/sql/mdx/mdx-language-reference-mdx) ou [XMLA](https://docs.microsoft.com/fr-fr/analysis-services/xmla/xml-for-analysis-xmla-reference) depuis l'invite de commande.

Idéalement le script est appelé depuis une autre VM que celle qui héberge l'instance SSAS. Cela permet de tester si l'instance est bien accessible à travers le réseau. On teste si le cube est bien traité et utilisable en appelant une mesure qui est renvoie le nombre de lignes dans la table de fait.

```powershell
$server = "localhost"    #SSAS instance name.
$database = "BASE_OLAP"  #SSAS database name.
 
$cubes = "CubeOne", "CubeTwo" #list of cubes to test in the database.
$mesureControl = "[Measures].[Sales Count]" #mesure to be evaluated, a rowcount mesure for instance.
 
$result = @()
Foreach($cube in $cubes){
 
    try {
        [xml]$invoke = Invoke-ASCmd -Server:$server -Database:$database -Query:"select $mesureControl on 0 from [$cube]" -ErrorAction Stop
        $resultSalesCount = $invoke.return.root.CellData.Cell | Where-Object {$_.CellOrdinal -eq "0"}
        if($invoke.return.root.Messages.Error.Description){
            $result += New-Object PSObject -Property @{
                CubeName = $cube
                Etat = "NOK"
                Erreur = $invoke.return.root.Messages.Error.Description
            }
            Write-Host "Query failed" -BackgroundColor Darkred
        }else{
            $result += New-Object PSObject -Property @{
                CubeName = $cube
                LastDataUpdate  = $invoke.return.root.OlapInfo.CubeInfo.Cube.LastDataUpdate.'#text'
                LastSchemaUpdate  = $invoke.return.root.OlapInfo.CubeInfo.Cube.LastSchemaUpdate.'#text'
                MesureControl = $resultSalesCount.FmtValue
                Etat = if($resultSalesCount.FmtValue -gt 0){"OK"}else{"NOK"}
            }
        }
    }
    catch {
        $result += New-Object PSObject -Property @{
            CubeName = $cube
            Etat = "KO"
            Erreur = $Error[0].ToString()
        }
        Write-Host "Error occured" -BackgroundColor Darkred
    }
}
 
$result
```