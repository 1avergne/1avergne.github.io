# Power BI : PowerShell Cmdlets

Power BI propose une API qui permet d'exécuter en ligne de commande la plupart des actions accéssibles depuis le service Power BI. Cette API peut être utilisée de manière simplifiée avec les Cmdlets PowerShell.

<https://docs.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps>

Le plus gros avantage des Cmdlets est de pouvoir intéragir avec le service Power BI et utiliser l'API avec un compte Power BI utilisateur sans avoir à passer par une application enregistrée dans l'Azure AD. La plupart des commandes de l'API ont une fonction équivalente dans la bibliothèque PowerShell.

Plusieurs exemple de scripts utilisant l'API Power BI sont disponibles dans [ce repo](https://github.com/1avergne/1avergne.github.io/tree/d06ba7ce021d5d1fd9f88ce5d8808b3bec29b773/PowerShell-Scripts).

## Installation

### Module _MicrosoftPowerBIMgmt_

La première étape consiste à installer le package sur le poste. 
Dans une instance Powershell avec les droits administrateur, exécuter la commande :

```powershell
Install-Module -Name MicrosoftPowerBIMgmt
```

Ou sans les droits admin pour l'utilisateur courant uniquement : 

```powershell
Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
```

Approuver les différents messages pour terminer l'installation.

![Plusieurs message d'alerte s'affichent lors de l'installation](/Images/20251015-scripts-powershell-powerbi/ReferentielNonApprouve.png)

### Modification de la stratégie d'execution

Les commandes PowerShell sont généralement utilisées dans des scripts pour automatiser des tâches et actions complexes. Par défault PowerShell n'autorise pas l'execution de scripts non-signés. Il faut changer la [stratégie d'execution](https://docs.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/about/about_execution_policies) pour autoriser l'execution de scripts développés par l'utilisateur.

La commande [`Get-ExecutionPolicy`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-executionpolicy?view=powershell-7.2) permet de connaitre la stratégie courante. Par défault il s'agit de "RemoteSigned".

La configuration la moins restrictive est "Unrestricted". Pour l'appliquer on utilise la commande [`Set-ExecutionPolicy`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.2) :

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted 
```

Attention néanmoins, cette stratégie permet d'executer n'importe quel script, y compris du code malvaillant. Il est indisposable de bien verifier son code dans cette configuration.

## Connexion au service Power BI

Comme lorsqu'on utilise le service PowerBI, il est indispensable d'être connecté avec un compte utilisateur pour acceder à son espace de travail et aux ressources déployées sur le serveur. Un script PowerShell qui utilise les Cmdlets Power BI doit donc embarquer une phase d'authentification avant les autres commandes. 
La commande [`Connect-PowerBIServiceAccount`](https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/connect-powerbiserviceaccount) permet de se connecter à Power BI.

### Connexion interactive
Habituellement je commence les scripts exécutés manuellement ainsi : 

```powershell
Try{
    $token = Get-PowerBIAccessToken
}
Catch{
    Connect-PowerBIServiceAccount
    $token = Get-PowerBIAccessToken
}
```

La fonction [`Get-PowerBIAccessToken`](https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/get-powerbiaccesstoken) permet de verifier si l'on est bien authentifié ou s'il faut se connecter. Le [`Try Catch`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally) permet de refaire une authentification uniquement si c'est nécessaire. La commande `Connect-PowerBIServiceAccount` ouvre une page d'authentification interactive.L'inconvéniant de cette méthode est qu'elle ne fonctionne pas pour les scripts automatisés dans la mesure où une intervention humaine est nécessaire pour saisir les informations d'authentification.

### Identifiants enregistrés dans un fichier
Il est possible d'enregistrer (de manière sécurisée) les informations de connexion dans un fichier plat. Pour cela on va stocker au format json le nom de l'utilisateur et le mot de passe (chiffré et converti en texte avec la commande PowerShell [`convertfrom-securestring`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring)).
Le mot de passe peut être déchiffré uniquement par l'utilisateur qui a créé le fichier. Si le script est appelé par un compte de service (dans un ordonnanceur de tâches par exemple) il est nécessaire d'exécuter une première fois le script de création du fichier de droits dans les mêmes conditions.

```powershell
$credentials = Get-Credential
$securedCredentials = New-Object -TypeName psobject
$securedCredentials | Add-Member -MemberType NoteProperty -Name UserName -Value $credentials.UserName
$securedCredentials | Add-Member -MemberType NoteProperty -Name SecuredPassword -Value $($credentials.Password | convertfrom-securestring)
$securedCredentials | ConvertTo-Json
```

La commande [`Get-Credential`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-credential) permet de récuperer le Login et le mot de passe de manière sécurisé. Le mot de passe n'est jamais affiché ni stocké en clair.

Une fois le fichier de droits créé, il peut être utilisé dans les scripts pour s'authentifier.

```powershell
$securedCredentials = cat $credentialsFileName | ConvertFrom-Json
$password = $securedCredentials.SecuredPassword | convertto-securestring
$username = $securedCredentials.UserName
$credentials = new-object -typename system.management.automation.pscredential -argumentlist $username, $password
connect-powerbIServiceAccount -Credential $credentials
```

Puisque la connexion se fait uniquement par Login/mot de passe, cette méthode n'est pas possible avec un compte qui nécessite une authentification multi-facteurs (MFA). Il est donc nécessaire de bien configurer le compte de service utilisé pour se connecter.

### Identifiants enregistrés dans Azure 

Il est possible de stocker le mot de passe du compte Power BI à utiliser dans un [Azure Key Vault](https://docs.microsoft.com/fr-fr/azure/key-vault/general/basic-concepts) (on utilisera cette méthode pour les compte de service plutôt que pour les comptes personels).

```powershell
$subscriptionId = "d49xxxxx-xxxx-xxxx-xxxx-xxxxx2d43b64"
$secretName = "SVC_POWERBI_PWD"

Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId 

$ressources = Get-AzResource -ResourceType "Microsoft.KeyVault/vaults"
$vaultName = $ressources[0].Name

$password = Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -AsPlainText | ConvertTo-SecureString -AsPlainText -Force
```

Cette solution déplace néanmoins le problème de l'authentification à Azure : il faut être connecté au service (dans l'exemple avec la commande `Connect-AzAccount`) pour accéder au service.

## Utiliser les commandes PowerShell

### Utilisation générale

Les Cmdlets permettent de naviguer dans l'arborescence du service Power BI (Espace de travail, rapport, dashboard, jeu de données…).
Les fonctions permettent uniquement de manipuler les objets accessibles à l'utilisateur connectées. Utiliser les commandes Powershell n'octroit pas de droits supplémentaires. Il est donc nécessaire d'avoir les droits suffisants pour acceder au contenu d'un espace de travail.

L'utilisation classique est de récupérer une liste d'objet, de filtrer la liste ou de boucler sur les objets.
Par exemple pour récupérer la liste des espace de travail on utilise l'instruction [`Get-PowerBIWorkspace`](https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspace) : 

```powershell
$workspaces = Get-PowerBIWorkspace
```

Pour récupérer la liste des jeux de données dans un espace de travail précis (ici : *CORPO INTERNE*) :

```powershell
$workspace = Get-PowerBIWorkspace -Name "CORPO INTERNE"
$datasets = Get-PowerBIDataset -WorkspaceId  $workspace.id.Guid 
```

Pour filter une liste on utilise l'instruction [`Where-Object`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/where-object) avec un filtre. Pour parcourir une liste on utilise l'instruction [`ForEach-Object`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/foreach-object). Pour ces deux instructions l'objet en courant est désigné par `$_`. 
Par exemple, si on souhaite télécharger au format Power BI Desktop, l'ensemble des rapports dans un Workspace précis et qui commencent par "CORPO" :

```powershell
$workspace = Get-PowerBIWorkspace -Name "CORPO INTERNE"
Get-PowerBIReport -WorkspaceId  $workspace.id.Guid | Where-Object {$_.name -like "CORPO*" } | ForEach-Object {
    $fileName = ".\" + $_.name + "." + $(Get-Date -Format "yyyy-MM-dd") + ".pbix"
    Export-PowerBIReport -Id $_.id.Guid -OutFile $fileName
}
```

### Fonctions principales

Les fonctions sont regroupées en six catégories en fonction du périmètre traité :

- [Profile](https://docs.microsoft.com/fr-fr/powershell/module/microsoftpowerbimgmt.profile/) : gestion du compte utilisateur et la connexion au service
    - `Connect-PowerBIServiceAccount` : permet de se connecter au service
    - `Get-PowerBIAccessToken` : renvoit un jeton d'authentification au service
    - `Resolve-PowerBIError` : renvoit les détails d'une erreur rencontrée côté Power BI
- [Admin](https://docs.microsoft.com/fr-fr/powershell/module/microsoftpowerbimgmt.admin/) : gestion du service Power BI
    - `Get-PowerBIActivityEvent` : renvoit l'audit d'activité du tenant Power BI
- [Capacities](https://docs.microsoft.com/fr-fr/powershell/module/microsoftpowerbimgmt.capacities/) : gestion des capacités (ne contient qu'une seule fonction)
    - `Get-PowerBICapacity` : renvoit la liste des capacités
- [Workspaces](https://docs.microsoft.com/fr-fr/powershell/module/microsoftpowerbimgmt.data/)
    - `Get-PowerBIWorkspace` : renvoit la liste des espaces de travail
    - `Add-PowerBIWorkspaceUser` : ajoute un utilisateur ou un groupe à un espace de travail
- [Data](https://docs.microsoft.com/fr-fr/powershell/module/microsoftpowerbimgmt.data/) : gestion des jeux de données
    - `Get-PowerBIReport` : renvoit la liste des rapports 
    - `Get-PowerBIDatasource` : renvoit la liste des sources de données
    - `Get-PowerBIDataset` : renvoit la liste des jeux de données
    - `Get-PowerBITable` : renvoit la liste des tables dans un jeu de données précis
    - `Add-PowerBIRow` : ajoute une ligne dans une table d'un jeu de données.
- [Report](https://docs.microsoft.com/fr-fr/powershell/module/microsoftpowerbimgmt.reports/) : gestion des rapports
    - `Invoke-PowerBIRestMethod` : execute une commande REST sur l'API Power BI
    - `Export-PowerBIReport` : télécharge un rapport Power BI en local au format _.pbix_ 
    - `Copy-PowerBIReport` : crée une copie d'un rapport sur le service Power BI

La liste exhaustive des fonctions classées par catégories est disponible dans [la documentation](https://docs.microsoft.com/fr-fr/powershell/power-bi/overview).

## Appeler l'API Power BI

Certaines commandes sont disponibles dans l'[API Rest Power BI](https://docs.microsoft.com/en-us/rest/api/power-bi/) mais n'ont pas d'équivalent en PowerShell. Pour ces fonctions on peut utiliser la commande PowerShell [`Invoke-PowerBIRestMethod`](https://docs.microsoft.com/fr-fr/powershell/module/microsoftpowerbimgmt.profile/Invoke-PowerBIRestMethod) qui permet d'appeler l'API Power BI en utilisant l'authentification courante. Il n'est donc pas nécessaire de préciser un compte ou un jeton d'authentification (token).

### Commandes manquantes principales 

- [Administration des passerelles](https://docs.microsoft.com/en-us/rest/api/power-bi/gateways)
    - __Get Gateways__ : renvoi la liste des passerelles administrées par l'utilisateur connecté
    - __Get Gateway__ : renvoi le détail d'une passerelle
    - __Get Datasources__ : renvoi la liste des sources de données pour une passerelle
    - __Get Datasource Users__ : renvoi la liste des utilisateurs d'une source de données
    - __Add Datasource User__ : ajoute un utilisateur à une source de données
- [Jeux de données](https://docs.microsoft.com/fr-fr/rest/api/power-bi/datasets)
    - __Get Parameters__ / __Get Parameters In Group__ : récupère la liste des paramètres d'un jeu de données
    - __Update Parameters__ / __Update Parameters In Group__ : met à jour les paramètres d'un jeu de données
    - __Refresh Dataset__ / __Refresh Dataset In Group__ : lance le rafraichissement d'un jeu de données ; le rafraichissement est comptabilisé comme un rafraichissement planifié

### Syntaxe de la fonction `Invoke-PowerBIRestMethod`

La fonction `Invoke-PowerBIRestMethod` s'utilise en appellant directement la méthode de l'API voulue et en précisant la méthode (_Get_ ou _Post_). Il n'est pas nécessaire d'indiquer l'URL de l'API.

Par exemple, pour obtenir la liste des espaces de travail disponible on utilise :
    
    Invoke-PowerBIRestMethod -Url 'groups' -Method Get

Cette appel donne le même résultat que `Get-PowerBIWorkspace`

Pour certaines commandes utilisants la méthode _Post_, il faut tout de même préciser une corps de requête (body). Ce corps doit être au format Json. La méthode la plus simple pour créer un body est de construire un objet PowerShell avec la structure attendu et de le convertir en Json.

```powershell
$updatedParameters = @()
$param = New-Object -TypeName psobject
$param | Add-Member -MemberType NoteProperty -Name name -Value "Instance SQL"
$param | Add-Member -MemberType NoteProperty -Name newValue -Value "FR-DI-PRE-SQL"
$updatedParameters += $param 
$body = New-Object -TypeName psobject
$body | Add-Member -MemberType NoteProperty -Name updateDetails -Value $updatedParameters
$body | ConvertTo-Json

Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/datasets/$datasetId/Default.UpdateParameters" -Method Post -Body $($body| ConvertTo-Json)
```


