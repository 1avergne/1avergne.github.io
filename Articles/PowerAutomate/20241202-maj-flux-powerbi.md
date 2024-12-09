# Mettre un jour un flux avec un déclencheur Power BI

<p style="text-align: right;">2024-12-02</p>

Le visuel Power Automate dans Power BI est un super outil pour permettre aux utilisateurs de déclencher des actions depuis un rapport. 
Une fois configuré, le flux récupère les paramètres envoyés par Power BI. Mais problème, il arrive que le paramétrage du déclencheur soit effacé lors de la modification du flux.

Pour rétablir le paramétrage, voici la marche à suivre :
 
- Ouvrir le flux en modification depuis PBI Desktop.
- Modifier le paramétrage du Trigger : changer le nombre d'exécutions concurrentes.
- Enregistrer le flux.
- Sortir de l'édition du flux, puis l'ouvrir à nouveau en édition toujours depuis PBI Desktop.
- Sélectionner une tâche et y ajouter comme 'contenu dynamique' une valeur 'Données Power BI ...' (j'ai ajouté une tâche 'Message' pour ça).
- La mesure utilisée apparait à présent dans le code du Trigger, 
- Sélectionner 'Enregistrer et appliquer', bien attendre le message de validation de l'enregistrement.
- Le flux est utilisable **\o/**

![image](/Images/20241202-maj-flux-powerbi/Declencheur-flux.png)

Et afin d'être sûr de pouvoir ajouter tous les paramètres dont j'ai besoin dans le visuel Power Automate, j'utilise une mesure qui renvoie systématiquement une valeur. Cette mesure permet alors d'avoir un produit cartésien de tous les axes d'analyses passés an paramètre du visuel. 
```dax
KPI_LAST_REFRESH_DATE_EPOCH = DATEDIFF(DATE(1970, 1, 1), LASTDATE(LAST_REFRESH_DATE[LAST_REFRESH_DATE]), SECOND)
```