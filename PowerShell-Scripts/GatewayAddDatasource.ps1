#https://community.powerbi.com/t5/Developer/Power-BI-REST-API-via-Powershell-Create-Datasource/td-p/511934/page/2

function CreateDatasourceForGateway([guid]$GatewayId, 
                                    [string]$DatasourceName, 
                                    [string]$TenantServer, 
                                    [string]$TenantDatabase,
                                    [string]$TenantDataSourceUser,
                                    [string]$TenantDataSourcePassword) {   

    $gateway = Invoke-PowerBIRestMethod `
                -Url "https://api.powerbi.com/v1.0/myorg/gateways/$GatewayId" `
                -Method GET ` | ConvertFrom-Json                

    $datasourceDetails = ConvertTo-Json -Depth 4 -InputObject $(@{
        dataSourceType = "Sql"
        connectionDetails = '{"server":"'+$TenantServer.Replace("\","\\")+'","database":"'+$TenantDatabase+'"}'
        datasourceName = $DatasourceName
        credentialDetails = @{
            credentialType = "Basic"
            credentials = Encript `
                            -Username $TenantDataSourceUser `
                            -Password $TenantDataSourcePassword `
                            -GatewayExponent $gateway.publicKey.exponent `
                            -GatewayModulus $gateway.publicKey.modulus
            encryptedConnection = "Encrypted"
            encryptionAlgorithm = "RSA-OAEP"
            privacyLevel = "Organizational"
        }
    })

    $result = Invoke-PowerBIRestMethod `
            -Url "https://api.powerbi.com/v1.0/myorg/gateways/$GatewayId/datasources" `
            -Method POST `
            -Body $datasourceDetails
}

function Encript([string]$Username,[string]$Password,[string]$GatewayExponent,[string]$GatewayModulus) {
    $segmentLength = 85
    $encryptedLength = 128
    $plaintTxt = '{"credentialData":[{"value":"'+$Username+'","name":"username"},{"value":"'+$Password+'","name":"password"}]}'
    $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider ($encryptedLength * 8)
    $parameters = $rsa.ExportParameters($false)
    $parameters.Exponent = [System.Convert]::FromBase64String($GatewayExponent)
    $parameters.Modulus = [System.Convert]::FromBase64String($GatewayModulus)
    $rsa.ImportParameters($parameters)
    $plainTextArray = [System.Text.Encoding]::UTF8.GetBytes($plaintTxt)    
    $hasIncompleteSegment = $plainTextArray.Length % $segmentLength -ne 0

    $segmentNumber = If (-not $hasIncompleteSegment) {[int]($plainTextArray.Length / $segmentLength)} Else {[int]($plainTextArray.Length / $segmentLength) + 1}
    $encryptedData = [System.Byte[]]::CreateInstance([System.Byte],$segmentNumber * $encryptedLength)
    [int]$encryptedDataPosition = 0;

    For ($i=0; $i -lt $segmentNumber; $i++) {
        $lengthToCopy = If ($i -eq ($segmentNumber - 1) -and $hasIncompleteSegment) {$plainTextArray.Length % $segmentLength} Else {$segmentLength}
        $segment = [System.Byte[]]::CreateInstance([System.Byte],$lengthToCopy)
        [System.Array]::Copy($plainTextArray,$i*$segmentLength,$segment,0,$lengthToCopy)
        $segmentEncryptedResult = $rsa.Encrypt($segment, $true)
        [System.Array]::Copy($segmentEncryptedResult,0,$encryptedData,$encryptedDataPosition,$segmentEncryptedResult.Length)
        $encryptedDataPosition += $segmentEncryptedResult.Length;
    }

    return [System.Convert]::ToBase64String($encryptedData)
}

#read-host -assecurestring | convertfrom-securestring | out-file .\cred.txt

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
$gatewayId = $($gateways.value | Where-Object {$_.name -like $gatewayName }).id

$t = [pscustomobject]@{source='xxx\yyy'
; server='xxxx.database.windows.net' 
; base='yyy'
; user='username'
; password='azerty1234'}

## test existance
$datasource = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources" -Method Get | ConvertFrom-Json).value | Where-Object {$_.datasourceName -eq $t.source} 

if(!$datasource){
    CreateDatasourceForGateway `
        -GatewayId $GatewayId `
        -DatasourceName $t.source `
        -TenantServer $t.server `
        -TenantDatabase $t.base `
        -TenantDataSourceUser $t.user `
        -TenantDataSourcePassword $t.password

    $datasource = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources" -Method Get | ConvertFrom-Json).value | Where-Object {$_.datasourceName -eq $t.source}
    $datasource
}else{
    write-host "Cette source existe déjà"
}

## recuperation de la liste des utilisateurs déjà déclarés dans la passerelle
$datasourceId = $datasource.id
$datasourceUsers = $(Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$datasourceId/users" -Method Get | ConvertFrom-Json).value

$currentUser = "zzz@yyy.fr"
if(! $($datasourceUsers | Where-Object {$_.emailAddress -like $currentUser}).identifier) {
    ##si l'utilisateur est absent de la passerelle il est ajouté
    Write-Host "<$currentUser> va être ajouté comme utilisateur de la connexion <$datasourceId>"
          
    $body = ([pscustomobject]@{emailAddress="$currentUser"; datasourceAccessRight='Read'} | ConvertTo-Json -Depth 2 -Compress)
    Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/gateways/$gatewayId/datasources/$datasourceId/users" -Method Post -Body $body
}