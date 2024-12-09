# Rafraichir un rapport Power BI après la mise à jour du fichier source

<p style="text-align: right;">2022-10-11</p>

A l'agence nous avons un fichier Excel stocké sur [SharePoint](https://www.microsoft.com/fr-fr/microsoft-365/sharepoint/collaboration) où chacun note ses jours de présence ou de télétravail. 
J'ai créé un rapport Power BI connecté à ce fichier et qui affiche le nombre de présents pour les prochains jours ainsi que les personnes qui n'ont pas rempli le fichier.

Je voulais que le rapport soit rafraichi après la mise à jour du fichier source afin d'afficher les informations les plus à jour possible.

## Le rapport

Le rapport est connecté au fichier sur SharePoint. Je n'utilise pas de paramètre ou de connexion dynamique pour ne pas bloquer le rafraichissement depuis le service.

Je charge aussi une table _Info_ d'une seule ligne avec la date de chargement en UTC et le nom du fichier source.

```m
let
    #"Table" = "Planning_présence_site.xlsx",
    #"Converti en table1" = #table(1, { {Table} }),
    #"Colonnes renommées" = Table.RenameColumns(#"Converti en table1",{ {"Column1", "Nom fichier"} }),
    #"Personnalisée ajoutée" = Table.AddColumn(#"Colonnes renommées", "Date traitement", each DateTimeZone.UtcNow()),
    #"Type modifié" = Table.TransformColumnTypes(#"Personnalisée ajoutée",{ {"Date traitement", type datetime}, {"Nom fichier", type text} })
in
    #"Type modifié"
```

![image](/Images/20221011-traiter-un-rapport-apres-maj-sharepoint/flux-requetes-powerquery.png)

Une fois publié sur _app.powerbi.com_ le rapport peut être rafraichi sans passer par une _Gateway_. Je [planifie un traitement](https://learn.microsoft.com/fr-fr/power-bi/connect-data/refresh-scheduled-refresh) tous les matins entre 6h30 et 7h00.

Le rapport est partagé à toute l'équipe Teams.

![image](/Images/20221011-traiter-un-rapport-apres-maj-sharepoint/flux-partager-equipe.png)

## Le flux Power Automate

L'actualisation dynamique sera faite grâce à [Power Automate](https://powerautomate.microsoft.com/fr-fr/) qui permet d'automatiser des processus entre differents services / outils. L'objectif est d'actualiser le rapport Power BI à chaque mise à jour du fichier Excel dans SharePoint.

Pour faire mon flux je dois anticiper les élements suivants : 
- Si une modification est enregistrée, une nouvelle modification peut intervenir juste après. Il ne faut pas déclencher le traitement immédiatement.
- Il faut limiter le nombre de rafraichissements pour ne pas consommer trop vite les 8 rafraichissements autorisés dans une journée (avec une licence Power BI Pro). 

J'ai organisé mon flux ainsi : 

![image](/Images/20221011-traiter-un-rapport-apres-maj-sharepoint/flux-power-automate.png)

### 0. SharePoint / Lors de la modification d’un élément ou d’un fichier

Le flux commence si n'importe quel fichier du répertoire SharePoint est modifié. A cette étape, il n'est pas possible de filtrer sur un fichier précis. Il serait possible de faire un test du fichier immédiatement après le déclencheur, mais on le fera plus tard.

### 1. Délai

On attend 5 minutes avant de continuer le flux. Cela permet de faire plusieurs modifications sur le fichier sans lancer le traitement immédiatement.

### 2. Power BI / Exécuter une requête sur un jeu de données
    
On éxécute une requête _DAX_ sur le modèle de données pour récupérer le nom du fichier et la dernière date de mise à jour. Les deux champs sont dans la table _Info_. J'utilise l'action [_Exécuter une requête sur un jeu de données_](https://learn.microsoft.com/fr-fr/connectors/powerbi/#run-a-query-against-a-dataset) du connecteur Power BI.

![image](/Images/20221011-traiter-un-rapport-apres-maj-sharepoint/flux-execute_dax.png)

### 3- Analyser JSON

Le résultat de la requête est _parsé_ pour pouvoir acceder aux champs. 

### 4- Condition

On va tester le résultat de requête pour verifier que le fichier modifié est bien le fichier source du rapport et que le dernier rafraichissement du jeu de données date de plus de 30 minutes. A cette étape on entre dans une boucle qui parcours toutes les lignes du résultat de requête, ce n'est pas un problème puisque la requête ne renvoi qu'une seule ligne à chaque fois.

![image](/Images/20221011-traiter-un-rapport-apres-maj-sharepoint/flux-appliquer-a-chacun.png)

### 5. Power BI / Actualiser un jeu de données

Si le test est réussi (fichier correct et dernier traitement il y a plus de 30 minutes), on lance l'actualisation du jeu de données dans Power BI. J'utilise l'action [_Actualiser un jeu de données_](https://docs.microsoft.com/connectors/powerbi/#refresh-a-dataset) du connecteur Power BI.

![image](/Images/20221011-traiter-un-rapport-apres-maj-sharepoint/flux_actualiser-jeu.png)

## La même en mieux

Quelques pistes d'améliorations : 
- Tester le nom du fichier dès le début du flux pour sortir tout de suite s'il ne s'agit pas du bon fichier.
- Ajouter un test pour ignorer les erreurs de traitement s'il sagit d'une erreur de type :

```json
"error":{
    "code":"InvalidRequest"
    ,"message":"Invalid dataset refresh request. Another refresh request is already executing"
}
```

- Utiliser un flux planifié (toutes les 30 minutes par exemple) pour ne pas avoir d'éxécution en parallèle du flux. Mais dans ce cas on perd l'aspect "dynamique" du flux.