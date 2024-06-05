# Les paramètres de champs

<p style="text-align: right;">2023-12-28</p>

Les [paramètres de champ](https://learn.microsoft.com/fr-fr/power-bi/create-reports/power-bi-field-parameters) sont une solution très utiles pour rentre dynamiques des visuels en offrant la possibilité à l'utilisateur de choisir les champs ou les mesures à afficher.  

## Libellés de mesures dynamiques

Je pars d'une mesure *CA* qui me renvoi le chiffre d'affaires pour la période sélectionnée (dans le contexte voulu).
Je crée trois autres mesures qui renvoient le CA pour l'année en cours, l'année précédente, et deux ans auparavant.

```
CA N-0 = VAR _off = DATEDIFF(LASTDATE(Calendrier[Date]), TODAY(), YEAR)
RETURN CALCULATE([CA], DATEADD(Calendrier[Date], _off, YEAR))

CA N-1 = VAR _off = DATEDIFF(LASTDATE(Calendrier[Date]), TODAY(), YEAR) - 1
RETURN CALCULATE([CA], DATEADD(Calendrier[Date], _off, YEAR))

CA N-2 = VAR _off = DATEDIFF(LASTDATE(Calendrier[Date]), TODAY(), YEAR) - 2
RETURN CALCULATE([CA], DATEADD(Calendrier[Date], _off, YEAR))
```

La fonction ```DateAdd``` permet de bien faire la sélection de l'année par rapport au champs *Date* et donc d'avoir toujours un résultat cohérent.

Je crée ensuite un [paramètre de champ](https://learn.microsoft.com/fr-fr/power-bi/create-reports/power-bi-field-parameters) qui utilise ces trois mesures.

![image](/Images/20231228-field-parameters/new-field-parameters.png)

Je vais ensuite modifier la requête DAX qui génère la table des paramètres de champs : je remplace les libellés des mesures par des libellés dynamiques.

```
CA par année = VAR _currYear = YEAR(TODAY())
RETURN {
    ("CA " & FORMAT(_currYear, "0000"), NAMEOF('Vente Detail'[CA N-0]), 0),
    ("CA " & FORMAT(_currYear - 1, "0000"), NAMEOF('Vente Detail'[CA N-1]), 1),
    ("CA " & FORMAT(_currYear - 2, "0000"), NAMEOF('Vente Detail'[CA N-2]), 2)
}
```

J'affiche le paramètre dans un diagramme, avec en axe des X le nom du mois (```Mois Lib = FORMAT([Date], "mmmm")```) et filtré sur la dernière année (```Année en cours = YEAR([Date]) = YEAR(TODAY())```). Je retrouve bien les noms dynamiques associés aux bonnes mesures.

![image](/Images/20231228-field-parameters/diag-ca.png)