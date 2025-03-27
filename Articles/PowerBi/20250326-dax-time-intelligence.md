# DAX : Time intelligence et groupes de cacul
<p style="text-align: right;">2025-03-26</p>

## Design-pattern

Les [groupes de calcul](https://1avergne.github.io/Articles/PowerBi/20240425-calculation-group.html) offrent des possibilités énormes en termes de dynamisme et de fonctionnalité du modèle. Et avec elles les fonctions d'intelligence temporelle peuvent être appliquées à tous les calculs d'un modèle.
J’ai essayé de regrouper ici un maximum de calculs qui exploitent les fonctions de time intelligence.

```C
Standard calculation = SELECTEDMEASURE() // Calcul par défaut : pas d'impact

Previous year = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date])) // Valeur sur la même période mais pour l'année précédente 

Previous month = CALCULATE(SELECTEDMEASURE(), DATEADD('Calendar'[Date], -1, MONTH)  // Valeur sur la même période mais pour le mois précédent

Previous period = CALCULATE(SELECTEDMEASURE(), DATESINPERIOD('Calendar'[Date], MIN('Calendar'[Date]) - 1, DATEDIFF(MAX('Calendar'[Date]), MIN('Calendar'[Date]), DAY) - 1, DAY)) // Valeur sur le même nombre de jours précedents la période observée

YoY Variation = DIVIDE(SELECTEDMEASURE(), CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))) - 1 // Variation entre l'année courante et l'année précédente

MoM Variation = DIVIDE(SELECTEDMEASURE(), CALCULATE(SELECTEDMEASURE(), DATEADD('Calendar'[Date], -1, MONTH))) - 1 // Variation entre le mois courant et le mois précédent

Versus previous year = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date])) - SELECTEDMEASURE()  // Ecart (soustraction) entre l'année courante et l'année précédente

6 rolling month = CALCULATE(SELECTEDMEASURE(), DATESINPERIOD('Calendar'[Date], MAX('Calendar'[Date]), -6, MONTH)) // Cumul sur les six derniers mois glissants

12 rolling month = CALCULATE(SELECTEDMEASURE(), DATESINPERIOD('Calendar'[Date], MAX('Calendar'[Date]), -12, MONTH)) // Cumul sur les douze derniers mois glissants

YTD = CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date])) // Valeurs cumulées du début de l'année jusqu'à la période courante

YTD from june = CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date], "05-31")) // Valeurs cumulées du début du mois de juin jusqu'à la période courante

YTD due month = CALCULATE(SELECTEDMEASURE(), FILTER(DATESYTD('Calendar'[Date]), [Date] <= EOMONTH(MAX('Calendar'[Date]) + 1, -1))) // Valeurs cumulées du début de l'année jusqu'à la fin du dernier mois complet
```

## Edition TMDL

Il peut être fastidieux d'écrire chaque calcul un-à-un. Pour gagner du temps, on peut insérer les calculs directment dans les fichiers sources du modèle.

- Enregistrer le rapport en _.pbip_ au format [TMDL](https://learn.microsoft.com/fr-fr/analysis-services/tmdl/tmdl-overview) (fonctionnalité en prévision à activer)
 
![image](/Images/20250326-dax-time-intelligence/20250326-calculation_group_tmdlOption.png)

- Créer un groupe de calcul ; puis renommer le groupe, la colonne, et le calcul par défaut
 
![image](/Images/20250326-dax-time-intelligence/20250326-calculation_group_init.png)

- Enregistrer et fermer le rapport
- Dans le navigateur de fichier, ouvrir le répertoire **.\ _NomDuRapport_ .SemanticModel\definition\tables** ; ce répertoire contient un fichier par table, dont les groupes de calculs. 
- Ouvrir avec un éditeur de texte le fichier de la table du groupe de calcul : **Time intelligence.tmdl** ; le fichier contient la définition de la table, on retrouve notamment le calcul par défaut qui a été créé dans Power BI Desktop.

![image](/Images/20250326-dax-time-intelligence/20250326-calculation_group_fileV1.png)

- En suivant la même syntaxe, on peut ajouter les autres calculs dans le fichier :

```tmdl
table 'Time intelligence'
	lineageTag: 6a4a2417-7603-414f-92bb-862acf99748a

	calculationGroup

		calculationItem 'Standard calculation' = SELECTEDMEASURE()

		calculationItem 'Previous year' = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date])) // Valeur sur la même période mais pour l'année précédente 

		calculationItem 'Previous month' = CALCULATE(SELECTEDMEASURE(), DATEADD('Calendar'[Date], -1, MONTH)  // Valeur sur la même période mais pour le mois précédent

		calculationItem 'Previous period' = CALCULATE(SELECTEDMEASURE(), DATESINPERIOD('Calendar'[Date], MIN('Calendar'[Date]) - 1, DATEDIFF(MAX('Calendar'[Date]), MIN('Calendar'[Date]), DAY) - 1, DAY)) // Valeur sur le même nombre de jours précedents la période observée

		calculationItem 'YoY Variation' = DIVIDE(SELECTEDMEASURE(), CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date]))) - 1 // Variation entre l'année courante et l'année précédente

		calculationItem 'MoM Variation' = DIVIDE(SELECTEDMEASURE(), CALCULATE(SELECTEDMEASURE(), DATEADD('Calendar'[Date], -1, MONTH))) - 1 // Variation entre le mois courant et le mois précédent

		calculationItem 'Versus previous year' = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR('Calendar'[Date])) - SELECTEDMEASURE()  // Ecart (soustraction) entre l'année courante et l'année précédente

		calculationItem '6 rolling month' = CALCULATE(SELECTEDMEASURE(), DATESINPERIOD('Calendar'[Date], MAX('Calendar'[Date]), -6, MONTH)) // Cumul sur les six derniers mois glissants

		calculationItem '12 rolling month' = CALCULATE(SELECTEDMEASURE(), DATESINPERIOD('Calendar'[Date], MAX('Calendar'[Date]), -12, MONTH)) // Cumul sur les douze derniers mois glissants

		calculationItem 'YTD' = CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date])) // Valeurs cumulées du début de l'année jusqu'à la période courante

		calculationItem 'YTD from june' = CALCULATE(SELECTEDMEASURE(), DATESYTD('Calendar'[Date], "05-31")) // Valeurs cumulées du début du mois de juin jusqu'à la période courante

		calculationItem 'YTD due month' = CALCULATE(SELECTEDMEASURE(), FILTER(DATESYTD('Calendar'[Date]), [Date] <= EOMONTH(MAX('Calendar'[Date]) + 1, -1))) // Valeurs cumulées du début de l'année jusqu'à la fin du dernier mois complet
				
	column 'Time intelligence calculation'
		dataType: string
		lineageTag: 5a250460-66c0-4a3b-a562-23a34d4d9cfe
		summarizeBy: none
		sourceColumn: Name
		sortByColumn: Ordinal

		annotation SummarizationSetBy = Automatic

	column Ordinal
		dataType: int64
		formatString: 0
		lineageTag: eb100106-9f8f-4e9f-80b2-c55b9baf990c
		summarizeBy: sum
		sourceColumn: Ordinal

		annotation SummarizationSetBy = Automatic
```
- A l'ouverture du fichier, il est nécessaire d'actualiser la table _Time Intelligence_ pour prendre en compte les modifications faites sur le modèle.

![image](/Images/20250326-dax-time-intelligence/20250326-calculation_group_refreshNow.png)

Et voila 👍