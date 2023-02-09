# Moyenne mobile

<p style="text-align: right;">2023-02-06</p>

Il y a plein de méthodes pour calculer une [moyenne mobile](https://fr.wikipedia.org/wiki/Moyenne_mobile).
Dans le cas que j'ai eu à traiter la règle de gestion était la suivante : 
- En considérant une suite temporelle de valeurs : 
  - Pour chaque valeur _Vn_ le résultat affiché est le rapport entre la valeur et la première valeur _V0_. Le premier résultat est donc 100% : _V0 / V0 = 1_

Ce calcul permet de comparer des évolutions en effaçant les écarts de valeurs au départ.

Visuellement, on a une première valeur à 100% et les valeurs suivantes qui évoluent par catégorie.

![image](/Images/20230206-moyenne-mobile/illustration_moyenne_mobile.png)

## Double dimension

Le résultat du calcul est affiché par période (habituellement mois ou année). Mais il faut également laisser la possibilité à l'utilisateur du rapport de sélectionner la période de départ (l'année où le mois qui sera à 100%). 

On prend le cas d'une table de faits _Revenus_ liée à une table de dimension temps _Calendrier_ : 

```
┏━━━━━━━━━┓     ┏━━━━━━━━━━━━┓
┃ Revenus ┣━━━🡺┃ Calendrier ┃
┗━━━━━━━━━┛     ┗━━━━━━━━━━━━┛
```

Si on filtre le calendrier pour sélectionner la période de référence, le graphique qui affiche la moyenne mobile sera également filtré. Pour éviter ça on peut supprimer le filtrage dans la mesure (```ALL('Calendrier')```) et utiliser le champs date de la table de faits. Mais dans ce cas on a plusieurs problèmes :
- On est obligé d'utiliser la granularité de la table de faits ; ou d'ajouter une nouvelle colonne dans la table de faits.
- Les autres visuels de la page sont également filtrés par le calendrier ; ou il faut modifier les interactions entre les visuels.  
- On ne peut peux plus utiliser les [fonctions d'intelligence temporelle](https://learn.microsoft.com/fr-fr/dax/time-intelligence-functions-dax) qui se baseraient sur le calendrier.

Il vaudrait donc mieux avoir une table dédiée à la sélection de la période de référence. La dimension _Calendrier_ reste ainsi disponible pour l'affichage des visuels et les calculs des mesures temporelles.
Cette nouvelle table peut être une copie à l'identique de la dimension originale, ou une sélection de quelques colonnes.

```
┏━━━━━━━━━┓     ┏━━━━━━━━━━━━┓
┃ Revenus ┣━━━🡺┃ Calendrier ┃
┗━━━━━━━━━┛     ┗━━━━━━━━━━━━┛
           ┏━━━━━━━━━━━━━━━┓
           ┃ Choix période ┃
           ┗━━━━━━━━━━━━━━━┛
```

La table n'est pas liée à la table de faits ou aux autres dimensions ; cette table ne sert pas à filtrer les données mais uniquement à connaitre la période de référence. On récupèrera la valeur sélectionnée dans le calcul de la moyenne mobile.  

![image](/Images/20230206-moyenne-mobile/moyenne_mobile_modele.png)

## Mesure DAX 

Une fois ce problème de dimension géré, la mesure DAX est assez simple. Il s'agit de récupérer la valeur pour la période de référence, la valeur pour la période en cours, et d'en faire le rapport.

```dax
revenu_moyenne_mobile = IF(MAX('Calendrier'[annee]) >= MAX('Choix période'[annee]),
VAR _Vn = SUM(Revenus[revenu])
VAR _V0 = CALCULATE(SUM(Revenus[revenu]), FILTER(ALL('Calendrier'), 'Calendrier'[annee] = MAX('Choix période'[annee])))
RETURN IF(MIN(_Vn, _V0) > 0, DIVIDE(_Vn, _V0))
)
```

- La période en cours est récupérée avec ```MAX('Calendrier'[annee])``` et la période de référence avec ```MAX('Choix période'[annee])```.
- La mesure commence par un test, on veut uniquement afficher des valeurs postérieures à la période de référence.
- La valeur courante est enregistrée dans une variable.
- La valeur pour la période de référence est calculée en utilisant la période sélectionnée dans la table _Choix période_.
- On va renvoyer un résultat si les deux valeurs sont positives toutes les deux : ```MIN(_Vn, _V0) > 0```.

![image](/Images/20230206-moyenne-mobile/moyenne-mobile-manipulation.gif)