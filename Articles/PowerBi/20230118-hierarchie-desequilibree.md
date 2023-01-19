# Gérer les hiérarchies déséquilibrées

On est habitué à utiliser des hiérarchies où la somme des éléments niveau donne le résultat pour le niveau parent. Par exemple le CA de chaque produit vendu dans une boutique donne le CA de la boutique ; le CA de toutes les boutiques dans un pays donne le CA du pays.
Mais certaine hiérarchie ne fonctionne pas comme ça :
- Si la valeur mesurée est n’est pas additive, c’est-à-dire que la valeur d’un parent ne correspond pas à la somme des valeurs de ses enfants.
- Si la hiérarchie n’est pas équilibrée :  que certaines branches ont plus de niveaux que d’autres.

Dans ces deux cas une agrégation _naturelle_ n’est pas possible, il faut adapter la données ou son traitement.

## Valeurs non-additives

Pour les valeurs non-additives on peut ajouter des valeurs de _régulation_ pour corriger les écarts entre les sous-niveaux et le total.
Par exemple, si j’ai une hiérarchie Pays --> Boutique et je veux afficher les valeurs :
- Pays=FR : CA = 123
- Boutique=Paris : CA = 67
- Boutique=Lyon : CA = 38
- Boutique=Perpignan : CA = 15

Si j’intègre les données correctement :

Pays | Boutique | CA
--- | --- | ---
FR | Paris | 67
FR | Lyon | 38
FR | Perpignan | 15

Dans ce cas le cumulé des boutiques est **120**. Mais je veux afficher **123** (ne me demandez pas pourquoi, c’est le problème du comptable). Je dois donc ajouter une ligne de régulation :

Pays | Boutique | CA
--- | --- | ---
FR | Paris | 67
FR | Lyon | 38
FR | Perpignan | 15
**FR** | **NA** | **3**

```
└───FR = 123
    ├───Paris = 67
    ├───Lyon = 38
    ├───Perpigna = 15
    └───NA = 3
```

Néanmoins la vérification des données et l’ajout de chaque ligne de régulation peuvent être très fastidieux et couteux dès qu’on a plusieurs catégories et plusieurs niveaux. On risque aussi d'ajouter des erreurs dans les données alors qu'elles nous ont toutes été fournie est qu'il ne devrait pas être nécessaire de les recalculer. Enfin, _régulation_ sera visible, ce qui n'est pas toujours souhaité par l'utilisateur.

## Hiérarchie non-équilibrée

Lorsqu'on a un nombre de niveaux différent de niveaux dans une hiérarchie, la solution la plus courante est d'ajouter des niveaux _fictifs_ pour avoir le même nombre par membre.
Si dans ma base de données, j'ai en plus des données de la France, les valeurs d'autres pays mais sans le détail par boutique :
- Pays=ES : CA = 80
- Pays=IT : CA = 55

Pour intégrer les données je vais devoir préciser une boutique pour ses pays :
Pays | Boutique | CA
--- | --- | ---
FR | Paris | 67
FR | Lyon | 38
FR | Perpignan | 15
FR | NA | 3
**ES** | **Boutiques ES** | **80**
**IT** | **Boutiques IT** | **55**

```
├───FR = 123
│   ├───Paris = 67
│   ├───Lyon = 38
│   ├───Perpignan = 15
│   └───NA = 3
├───ES = 80
│   └───Boutiques ES = 80
└───IT = 55
    └───Boutiques IT = 55
```

Cette solution si le nombre de valeurs à compléter est minime. Mais dans le cas où il faut ajouter de nombreuses valeurs, il sera plus compliqué de comprendre la hiérarchie et la navigation va être dégradée.

## La _bonne_ méthode

La méthode idéale (à mon avis) pour traiter les deux situation décrites ci-dessus est d'intégrer l'ensemble des données, sans régulation et sans niveau ajouter, pour recréer la hiérarchie et les mesures en **DAX**.

Par exemple, on souhaite analyser l'efficacité d'une population pour exécuter une tâche quelconque. Les personnes sont rassemblées en _sections_, plusieurs _sections_ forment une _équipe_, plusieurs _équipes_ forment un _groupe_. Mais les _groupes_ peuvent aussi être un ensemble de personnes sans répartition par _équipe_. Et les _équipe_ peuvent être un ensemble de personnes sans répartition par _section_
On a deux mesures : 
- Eff : efficacité dans la tâche, exprimée en pourcentage, la valeur n'est pas additive : le résultat d'une _équipe_ est indépendant des résultats des _sections_ qui la compose.
- Pax : le nombre de personnes, la valeur est additive : le nombre de personnes dans une _équipe_ correspond à la somme du nombre de personnes dans les _sections_ qui la compose.

```
└───Root : Eff = 55% / Pax = 37
    ├───Grp_A : Eff = 60% / Pax = 9
    │   ├───Eqp_A1 : Eff = 40% / Pax = 5
    │   └───Eqp_A2 : Eff = 70% / Pax = 4
    │       ├───Sec_A2_ker : Eff = 75% / Pax = 2
    │       └───Sec_A2_bis : Eff = 55% / Pax = 2
    ├───Grp_B : Eff = 65% / Pax = 16
    │   ├───Eqp_B1 : Eff = 40% / Pax = 6
    │   │   ├───Sec_B1_ker : Eff = 70% / Pax = 2
    │   │   ├───Sec_B1_bis : Eff = 40% / Pax = 2
    │   │   └───Sec_B1_ter : Eff = 20% / Pax = 2
    │   ├───Eqp_B2 : Eff = 35% / Pax = 5
    │   └───Eqp_B3 : Eff = 30% / Pax = 5
    └───Grp_C : Eff = 30% / Pax = 10
```

### Les données en entrée

On récupère les données au format tabulaire : ```Elément | Parent | ValeurA | ValeurB | ...``` 

Elément | Parent | Eff | Pax
--- | --- | --- | ---
Root | _null_ | 55 | 37
Grp_A | Root | 60 | 9
Eqp_A1 | Grp_A | 40 | 5
Eqp_A2 | Grp_A | 70 | 4
Sec_A2_ker | Eqp_A2 | 75 | 2
Sec_A2_bis | Eqp_A2 | 55 | 2
Grp_B | Root | 65 | 16
Eqp_B1 | Grp_B | 40 | 6
Sec_B1_ker | Eqp_B1 | 70 | 2
Sec_B1_bis | Eqp_B1 | 40 | 2
Sec_B1_ter | Eqp_B1 | 20 | 2
Eqp_B2 | Grp_B | 35 | 5
Eqp_B3 | Grp_B | 30 | 5
Grp_C | Root | 30 | 10

Il est important que la racine de la hiérarchie (_Root_) est une valeur nulle comme parent (et pas une valeur vide).
On ajoute également une colonne d'index.

![image](/Images/20230118-hierarchie-desequilibree/analysePerf-initial.png)

### Colonnes calculées

Un fois la table chargée dans le modèle, on va créer plusieurs colonnes et mesures pour rendre la hiérarchie facilement utilisable.
Pour cela on va notamment utiliser les [fonctions parents et enfants](https://learn.microsoft.com/fr-fr/dax/parent-and-child-functions-dax).

```Path = PATH(AnalysePerf[Elément], AnalysePerf[Parent])``` 
--> Crée le _chemin_ de l'élement à partir de la racine. Les niveaux sont séparés par des tubes.

```Depth = PATHLENGTH(AnalysePerf[Path])```
--> Enregistre la profondeur de l'élement : 1 pour la racine, 2 pour les groupes, 3 pour les équipes ...

```Leaf = IF(COUNTROWS(FILTER(AnalysePerf, PATHCONTAINS(AnalysePerf[Path], EARLIER(AnalysePerf[Elément])))) = 1, 1, 0)```
--> Indique si l'élément est une feuille dans la hiérarchie (s'il n'a pas d'enfant). Pour une utilisation plus simple, la colonne est de type entier plutôt que booléen.

On va à présent recomposer la hiérarchie en ajoutant une colonne par niveau. Il y a 4 niveaux dans notre exemple, il faut donc ajouter 4 colonnes.

```
Niveau 1 = PATHITEM(AnalysePerf[Path], 1)
Niveau 2 = PATHITEM(AnalysePerf[Path], 2)
Niveau 3 = PATHITEM(AnalysePerf[Path], 3)
Niveau 4 = PATHITEM(AnalysePerf[Path], 4)
```

Les colonnes créées peuvent être réunie dans une hiérarchie.

![image](/Images/20230118-hierarchie-desequilibree/analysePerf-colonnes_calculees.png)

### Champs calculés

La table est prète à être utilisée, on va créer les mesures qui vont gérer les valeurs non-additives.

- **RowDepth** : la profondeur maximum des lignes filtrées :
```
RowDepth = MAX(AnalysePerf[Depth])
```

- **BrowseDepth** : la profondeur dans la navigation (par exemple dans une matrice). La valeur est renvoyée uniquement s'il existe bien un niveau.
```
BrowseDepth = VAR _d = SWITCH(TRUE()
, ISINSCOPE(AnalysePerf[Niveau 4]), 4
, ISINSCOPE(AnalysePerf[Niveau 3]), 3
, ISINSCOPE(AnalysePerf[Niveau 2]), 2
, ISINSCOPE(AnalysePerf[Niveau 1]), 1
)
RETURN IF(_d <= [RowDepth], _d)
```

- **Val Eff** : la valeur de la colonne Eff pour l'élément du niveau observé (et pas pour tous ses enfants) :
```
Val Eff = VAR _d = [BrowseDepth]
RETURN CALCULATE(SUM(AnalysePerf[Eff]), FILTER(AnalysePerf, [Depth] = _d))
```

- **Val Pax** : la somme du nombre de personne pour les éléments les plus bas uniquement. _Pax_ est une colonne qui peut être additionné si on ne prend que le niveau le plus fin et pas les valeurs déjà agrégées.
```
Val Pax = IF([BrowseDepth] <= [RowDepth]
    , CALCULATE(SUM(AnalysePerf[Pax]), FILTER(AnalysePerf, AnalysePerf[Leaf] = 1)) 
)
```

![image](/Images/20230118-hierarchie-desequilibree/mesures-table-matrice.png)

### Segments

Le visuel _Segment_ dans Power Bi affiche tous les niveaux d'une hiérarchie. SI on l'utilise pour afficher les 4 niveaux, des valeurs _(Vide)_ seront affichées pour chaque niveau.