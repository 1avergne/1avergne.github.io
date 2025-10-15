<#
.SYNOPSIS 
Enregistre les informations d'authentification d'un utilisateur.

.DESCRIPTION
Enregistre dans un fichier texte le nom et le mot de passe (chiffré) d'un utilisateur. Les droits sont saisis de manière interactive. Le fichier créé peut être lu par "ConnectWithCredentialsFile.ps1".
Le mot de passe peut être déchiffré uniquement par l'utilisateur qui a créé le fichier. Si le script est appelé par un compte de service (dans un ordonnanceur de tâches par exemple), il est donc nécessaire d'exécuter ce script dans les même conditions que lors de l'utilisation du fichier.

.INPUTS
Informations d'authentification saisies manuellement.

.OUTPUTS
Fichier JSON :
{
    "UserName":  "user@domain.com",
    "SecuredPassword":  "01234AZERTY56789"
}

.EXAMPLE
C:\PS> ./CreateCredentialsFile.ps1

#>

$user = $(whoami).Replace("\", "_")
$credentialsFileName = ".\" + $user + ".cred"

$credentials = Get-Credential

<#
$user = $credentials.UserName
if($user.IndexOf("@") -ge 0)
{
    $ia = $user.IndexOf("@")
    $id = $user.Substring($ia).LastIndexOf(".")

    $credentialsFileName = $user.Substring($ia+1, $id-1) + "_" + $user.Substring(0, $ia) + ".cred"
    
}
#>

$securedCredentials = New-Object -TypeName psobject
$securedCredentials | Add-Member -MemberType NoteProperty -Name UserName -Value $credentials.UserName
$securedCredentials | Add-Member -MemberType NoteProperty -Name SecuredPassword -Value $($credentials.Password | convertfrom-securestring)
$securedCredentials | ConvertTo-Json | out-file $credentialsFileName