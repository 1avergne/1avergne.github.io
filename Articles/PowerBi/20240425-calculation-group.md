# Les groupes de calcul

<p style="text-align: right;">2024-04-25</p>

Les groupes de calcul, c'est la meilleure choses qui soit arrivé à Power BI depuis les paramètres de champs ! C'est simplement la dernière fonctionalité qu'il manquait ratraper les capacité du MDX.
Les groupes de calcul permettent de modifier le comportement des mesures ; on va pouvoir "surcharger" les mesures avec des calculs suplémentaires. On retrouve un comportement similaire à la fonctionalité "Scope" des modèles multidimentionnels.

La documentation Microsoft explique déjà très bien comment ça fonctionne, je vais plutôt me concentrer sur des cas d'usages.

## Analyse temporelle

Lorsque l'on crée une mesure, on va souvent avoir besoin de la décliner en plusieurs version pour effectuer des analyses temporelles (YoY, YTD, cumul à date, etc.)
Il est possible de créer une version de l'indicateur pour chaque type d'analyse ; pour ensuite utiliser un paramètre de champ afin de choisir dynamiquement le type d'analyse à restituer.
Mais avec un les groupes de calcul, on peut aussi creer toutes les analyse temporelles de manière abstraites pour qu'elles soit ensuite appliquées à chaque mesures du modèle.

```dax
Standard calculation = SELECTEDMEASURE()

Previous year = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))

YoY Variation = DIVIDE(SELECTEDMEASURE(), CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))) - 1

Versus previous year = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date])) - SELECTEDMEASURE()

YTD = CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date]))
```

Si le calcul revoit un format différent du format initial (par exemple : un pourcentage pour un calcul de ratio), il est nécessaire de préciser le format du résulat du calcul.

![image](/Images/20240425-calculation-group/dynamic-format.png)

Dans la formule de la chaîne de format dynamique, le fonction ```SELECTEDMEASURE``` renvoit la valeur du résultat du calcul.

```dax
IF(ABS(SELECTEDMEASURE()) < 0.01, "0.00\ ‰;-0.00\ ‰;0.00\ ‰", "0.00\ %;-0.00\ %;0.00\ %")
```

## Modèle multi-routes

Comment gérer un modèle comme celui-ci simplement ?

La table de faits **C** est filtrée par la dimension **B** qui dépent elle-même d'une table **A**. Mais entre **A** et **B** il existe plusieurs relations *many-to-many*. Selon le contexte, on voudra utiliser telle ou telle table de jointure (**A1B**, **A2B** ou **A3B**).
Il faut que le filtrage d'une seule relation entre la table de brige et B soit à double sens pour que le modèle soit valide et que **A** filtre bien **B** et **C**.

![image](/Images/20240425-calculation-group/multiroute-diagram.png)

Dans le modèle, on définie le filtrage de toute les relation à sens unique. 
Puis on crée un groupe avec un élement de calcul pour chaque table de jointure. On peut ensuite indiquer quelle relation utiliser à double sens pour filtrer de la table **A** vers la table **C**

```dax
Pont 1 = CALCULATE(SELECTEDMEASURE(), CROSSFILTER('A1B'[Id_B], 'B'[Id_B], Both))

Pont 2 = CALCULATE(SELECTEDMEASURE(), CROSSFILTER('A2B'[Id_B], 'B'[Id_B], Both))

Pont 3 = CALCULATE(SELECTEDMEASURE(), CROSSFILTER('A3B'[Id_B], 'B'[Id_B], Both))
```