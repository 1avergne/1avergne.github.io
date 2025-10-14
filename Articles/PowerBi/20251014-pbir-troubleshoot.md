# Rapport au format PBIR - quelques déconvenues

<p style="text-align: right;">2025-10-14</p>

<details><summary><b>TL;DR</b></summary>
<p>Erreur <code>Cannot perform interop call to: ModelAuthoringHostService.UpdateModelExtensions(args:1) wrong arg[0]=extensions</code> dans Power BI Desktop
➔ supprimer toutes les tables sans mesures dans le fichier <i>reportExtension.json</i>.</p>
<p>Erreur <code>Failed to update report content - source report is PBIR and target report is PBIR-Legacy. Versions must be the same.</code> dans l'API Power BI
➔ republier le rapport depuis Power BI Desktop.</p>

</details>

## Power BI Dekstop _WrongArgs: ModelAuthoringHostService.UpdateModelExtensions(args:1) wrong arg[0]=extensions_

Aujourd'hui j'ai eu à modifier un rapport Power BI pour un projet qui dure depuis plus d'un an. 
A cause de quelques correctifs à chaud et autres, ma version de développement au format _Pbip_ était obsolète. Il a donc fallu que je reparte de la version de Recette que j'ai téléchargé depuis le service Power BI Desktop. 

Il s'agit d'un rapport connecté à un modèle de données publié (_live-connexion_), rapport dans lequel j'ai ajouté beaucoup de mesures DAX.

Mais en voulant ouvrir le fichier, je tombe sur un os : le message d'erreur suivant avec ce qui semble être le code de toutes mes mesures DAX.

```
Cannot perform interop call to: ModelAuthoringHostService.UpdateModelExtensions(args:1) wrong arg[0]=extensions
````

![image](/Images/20251014-pbir-troubleshoot/pbir_messag.png)

En cliquant sur "Annuler" j'accède au rapport et je peux modifier les visuels ; mais je ne vois plus les expressions DAX des mesures définies dans le rapport.

Ni StackOverflow, ni les blogs Power BI n'ont l'air de vouloir m'aider donc je dois trouver la solution comme un grand. 

J'enregistre le rapport au format _Pbip_ pour pouvoir regarder ce qui s'y passe. 

En ouvrant le répertoire _.Report_ dans VS Code je constate que mon rapport est enregistré au [nouveau format _Pbir_](https://learn.microsoft.com/fr-fr/power-bi/developer/projects/projects-report). Je retrouve mes mesures DAX dans le fichier _reportExtension.json_ ; c'est littéralement le contenu de ce fichier qui est affiché dans le message d'erreur.

Si on regarde la structure du Json, il y a un bloc :

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/reportExtension/1.0.0/schema.json",
  "name": "extension",
  "entities": [ … ]
}
```

Avec dans ```[ … ]``` la liste des tables dans le modèle et pour chaque table, les mesures qu'elle contient.

Ma stratégie est simple, virer des trucs et voir ce qui se passe. 

Je commence par faire un backup du fichier puis je retire toutes les tables pour ne garder que celle qui contient le plus de mesures.

Je rouvre le rapport dans Power BI Desktop et tout va bien : pas de message d'erreur, le code des mesures (restantes) est accessible. J'ai quelques alertes pour les mesures manquantes mais c'est normal. Le problème est bien dans le fichier _reportExtension.json_.

Je regarde la version originale (et KO) du fichier et je remarque que certaine tables sont présentes sans avoir de mesures de définie. 

```json
,
    {
      "name": "V_PBI_CAMPAIGN"
    },
    {
      "name": "V_PBI_MD_CARTECO"
    }
```

Des trucs qui ne servent à rien dans un Json, ça me semble bizarre. Je rajoute ces tables à la version actuelle du fichier (épuré et OK). A la réouverture du rapport dans Desktop l'erreur est revenue !

Ok on a trouvé le problème ! Je remets le fichier original et je retire toutes les tables sans mesure. Pour ne rien oublier, je fais même une expression régulière qui attrappe toutes les tables à supprimer : ```\{\r\n[ ]*"name": "[^"]+"\r\n[ ]*\},?```

![image](/Images/20251014-pbir-troubleshoot/pbir_regular_exp.png)

J'enregistre et j'ouvre une nouvelle fois le rapport, on y est ! Pas d'erreur et toutes mes mesures sont accessibles !

## Power BI API _source report is PBIR and target report is PBIR-Legacy_

Il faut maintenant mettre ce rapport en production, ce que fait habituellement grâce à la fonction "UpdateReportContent" de l'API Power BI. En effet le rapport doit être déployé dans plusieurs espaces de travail, donc j'utilise cette fonction pour cloner la dernière version du rapport depuis le dernier espace de travail de travail de mon pipeline de déploiement.

Sauf qu'aujourd'hui le script m'a renvoyé cette erreur : 

```
Failed to update report content - source report is PBIR and target report is PBIR-Legacy. Versions must be the same.
```

![image](/Images/20251014-pbir-troubleshoot/pbir_powershell_ko.png)

Effectivement le rapport déjà déployé a quelques mois. Et j'ai développé la nouvelle version avec toutes les options de nouveau format (_pbir_ et _tmdl_) d'activées. D'ailleurs quand je modifie le rapport en ligne, le bandeau suivant apparait :

![image](/Images/20251014-pbir-troubleshoot/pbir_format_online.png)

Mais alors que faire ?

Je suis reparti de Power BI Desktop pour republier le rapport avec le même nom et la même source de données. Et après avoir cliqué sur "Publier", choisi l'espace de travail de destination, et attendu quelques secondes d'inquiétude ; j'ai eu le message me demandant de confirmer l'écrasement de la version actuellement en ligne.

![image](/Images/20251014-pbir-troubleshoot/pbir_pbidesktop_remplace.png)

Je clique sur "Remplacer" et fonce voir sur le service Power BI : ma nouvelle version du rapport est bien là !

![image](/Images/20251014-pbir-troubleshoot/pbir_pbidesktop_publish.png)

Et alors la prochaine fois ? Par curiosité j'ai refait tourner le script PowerShell de copie du rapport.
Cette fois l'exécution est OK ; les versions de mes rapports sont identiques ! 

![image](/Images/20251014-pbir-troubleshoot/pbir_powershell_ok.png)

Mon rapport est corrigé et publié, ma journée est finie !

