<#
Permet d'ajouter une liste de comptes comme utilisateurs d'une ou plusieurs sources de données dans une passerelle Power BI.
Le choix de la passerelle et la liste des utilisateurs sont à saisir lors de l'execution du script.
La liste des utiliseurs est stockée dans un fichier plat (un utilisateur par ligne).
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
#write-host $gateways[0].value.name        # ~1
#$gatewayName = $gateways[0].value.name    # ~1
$gatewayName = read-host                 # ~2

write-host ""
write-host "Entrer le masque de nom des sources (en minuscule, * comme caractère d'échappement) :"
$datasourcesMask = read-host #svaazbim021,samfm*

$gatewayId = $($gateways.value | Where-Object {$_.name -like $gatewayName }).id
$datasources = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources" -Method Get | ConvertFrom-Json).value | Where-Object {$_.datasourceName -like "$datasourcesMask"} 

## validation datasources
write-host ""
write-host "Les sources suivantes seront modifiées :"
$datasources.datasourceName 
write-host ""
write-host "Continuer (O/N) ?"
$validation = read-host
if($validation -ne "O") {
    return
}

## recuperation de la liste d'utilisateurs à ajouter
write-host ""
write-host "Entrer le nom du fichier contenant la liste des utilisateurs :"
$filePath = read-host
$users = Get-Content $filePath

##validation utilisateurs
write-host ""
write-host "Les utilisateurs suivants seront ajoutés aux sources de données s'ils n'y sont pas déjà déclarés :"
$users
write-host ""
write-host "Continuer (O/N) ?"
$validation = read-host
if($validation -ne "O") {
    return
}

## parcours les datasources 
$datasources | ForEach-Object {
    $datasourceId = $_.id
    $datasourceName = $_.datasourceName
    write-host ""
    $datasourceName
    ## recuperation de la liste des utilisateurs déjà déclarés dans la passerelle
    $datasourceUsers = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$datasourceId/users" -Method Get | ConvertFrom-Json).value
    
    ## parcours la liste d'utilisateurs à ajouter
    $users | ForEach-Object {
        $currentUser = $_.Trim()
        if(! $($datasourceUsers | Where-Object {$_.emailAddress -like $currentUser}).identifier) {
            ##si l'utilisateur est absent de la passerelle il est ajouté
            Write-Host "<$currentUser> va être ajouté comme utilisateur de la passerelle $datasourceName <$datasourceId>"
          
            $body = ([pscustomobject]@{emailAddress="$currentUser"; datasourceAccessRight='Read'} | ConvertTo-Json -Depth 2 -Compress)
            Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$datasourceId/users" -Method Post -Body $body
        }
        
    }
}