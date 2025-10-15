<#
Affiche la liste des utilisateurs d'une ou plusieurs source de données.
Le choix de la passerelle et de la source de données sont à saisir.
#>

## connection au compte Power BI
Connect-PowerBIServiceAccount
$token = Get-PowerBIAccessToken

## choix de la Gateway
write-host "Passerelles disponibles :"
$gateways = Invoke-PowerBIRestMethod -Url 'https://api.powerbi.com/v1.0/myorg/gateways' -Method Get | ConvertFrom-Json
$gateways.value.name # | Select-Object name

write-host ""
write-host "Entrer le nom de la passerelle :"
write-host $gateways[0].value.name 
$gatewayName = $gateways[0].value.name # read-host
$gatewayId = $($gateways.value | Where-Object {$_.name -like $gatewayName }).id

## source de reference
write-host ""
write-host "Entrer le nom de la source de reference (en minuscule) :"
$refdatasourceName = read-host #svaazbim021,samfm*
$refdatasource = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources" -Method Get | ConvertFrom-Json).value | Where-Object {$_.datasourceName -eq "$refdatasourceName"} 
$refdatasourceId = $refdatasource.id

## utilisateur source ref
$refdatasourceUsers = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$refdatasourceId/users" -Method Get | ConvertFrom-Json).value

##validation utilisateurs
write-host ""
write-host "Les utilisateurs suivants sont déclarés dans la source de données :"
$refdatasourceUsers | ForEach-Object {
$_.emailAddress
}
