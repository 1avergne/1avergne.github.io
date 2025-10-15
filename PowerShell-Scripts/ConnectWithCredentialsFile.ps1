<#
.SYNOPSIS 
Lit les informations d'authentification d'un utilisateur et se connecte à Power BI.

.DESCRIPTION
Utilise les informations d'authentification enregistrées dans le fichier créé par "CreateCredentialsFile.ps1" pour se connecter à Power BI.

.INPUTS
None

.OUTPUTS
Microsoft.PowerBI.Common.Abstractions.Interfaces.IPowerBIProfile

.EXAMPLE
C:\PS> ./CreateCredentialsFile.ps1

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/connect-powerbiserviceaccount

#>

#cd ~

$user = $(whoami).Replace("\", "_")
$credentialsFileName = $credentialsFileName = ".\" + $user + ".cred"

$securedCredentials = Get-Content $credentialsFileName | ConvertFrom-Json
$password = $securedCredentials.SecuredPassword | convertto-securestring
$username = $securedCredentials.UserName
$credentials = new-object -typename system.management.automation.pscredential -argumentlist $username, $password
connect-powerbIServiceAccount -Credential $credentials

# (Get-PowerBIAccessToken).Values
Set-Clipboard -Value $((Get-PowerBIAccessToken).Values)