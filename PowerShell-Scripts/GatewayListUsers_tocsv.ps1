<#
Enregistre la liste des utilisateurs d'une source de données dans un fichier plat.
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
$gatewayName = $gateways[0].value.name # $gatewayName = read-host

write-host ""
write-host "Entrer le masque de nom des sources (en minuscule, * comme caractère d'échappement) :"
$datasourcesMask = read-host #svaazbim021,samfm*

$gatewayId = $($gateways.value | Where-Object {$_.name -like $gatewayName }).id
$datasources = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources" -Method Get | ConvertFrom-Json).value | Where-Object {$_.datasourceName -like "$datasourcesMask"} 

## recuperation de la liste d'utilisateurs à ajouter
write-host ""
write-host "Entrer le nom du fichier à écrire. Le fichier contiendra la liste des utilisateurs."
$filePath = ".\GatewayUsersList.csv" # read-host

## validation datasources
write-host ""
write-host "La liste des utilisateurs des sources suivantes sera écrit dans le fichier $filePath :"
$datasources.datasourceName 
write-host ""
write-host "Continuer (O/N) ?"
$validation = read-host
if($validation -ne "O") {
    return
}

##entête du fichier
Set-Content -Path $filePath -Value "gatewayName;datasourceName;userMail;userDisplayName;userPrincipalType"

## parcours les datasources 
$datasources | ForEach-Object {
    $datasourceId = $_.id
    $datasourceName = $_.datasourceName
    write-host ""
    $datasourceName
    ## recuperation de la liste des utilisateurs déjà déclarés dans la passerelle
    $datasourceUsers = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$datasourceId/users" -Method Get | ConvertFrom-Json).value
    
    $datasourceUsers | ForEach-Object {
    $userMail = $_.emailAddress
    $userDisplayName = $_.displayName
    $userPrincipalType = $_.principalType
    Add-Content -Path $filePath -Value "$gatewayName;$datasourceName;$userMail;$userDisplayName;$userPrincipalType"
    }

}