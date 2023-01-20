# Gérer les hiérarchies déséquilibrées

On est habitué à utiliser des hiérarchies où la somme des éléments d'un niveau donne le résultat pour le niveau parent. Par exemple le CA de chaque produit vendu dans une boutique donne le CA de la boutique ; le CA de toutes les boutiques dans un pays donne le CA du pays.
Mais certaines hiérarchies ne fonctionnent pas comme ça :
- Si la valeur mesurée n’est pas additive, c’est-à-dire que la valeur d’un parent ne correspond pas à la somme des valeurs de ses enfants.
- Si la hiérarchie n’est pas équilibrée :  que certaines branches ont plus de niveaux que d’autres.

Dans ces deux cas une agrégation _naturelle_ n’est pas possible, il faut adapter la donnée ou son traitement.

## Valeurs non-additives

Pour les valeurs non-additives on peut ajouter des valeurs de _régulation_ pour corriger les écarts entre les sous-niveaux et le total.
Par exemple, si j’ai une hiérarchie Pays --> Boutique et que je veux afficher les valeurs :
- Pays = FR : CA = 123
- Boutique = Paris : CA = 67
- Boutique = Lyon : CA = 38
- Boutique = Perpignan : CA = 15

Si j’intègre les données correctement :

Pays | Boutique | CA
--- | --- | ---
FR | Paris | 67
FR | Lyon | 38
FR | Perpignan | 15

Dans ce cas le cumulé des boutiques est **120**. Mais je veux afficher **123** (_ne me demandez pas pourquoi, c’est le problème du comptable_). Je dois donc ajouter une ligne de régulation :

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

Néanmoins la vérification des données et l’ajout de chaque ligne de régulation peuvent être très fastidieux et couteux dès qu’on a plusieurs catégories et plusieurs niveaux. On risque aussi d'ajouter des erreurs dans les données alors qu'elles nous ont toutes été fournies est qu'il ne devrait pas être nécessaire de les recalculer. Enfin, la _régulation_ sera visible, ce qui n'est pas toujours souhaité par l'utilisateur.

## Hiérarchie non-équilibrée

Lorsqu'on a un nombre de niveaux différent dans les branches d'une hiérarchie, la solution la plus courante est d'ajouter des niveaux _fictifs_ pour égaliser les branches.
Si dans ma base de données, j'ai en plus des données de la France, les valeurs d'autres pays mais sans le détail par boutique :
- Pays = ES : CA = 80
- Pays = IT : CA = 55

Pour intégrer les données je vais devoir préciser une boutique pour ces pays :
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

# La _bonne_ méthode

La méthode idéale (à mon avis) pour traiter les deux situations décrites ci-dessus est d'intégrer l'ensemble des données, sans régulation, pour recréer la hiérarchie et les mesures en **DAX**.

Par exemple, on souhaite analyser l'efficacité d'une population pour exécuter une tâche quelconque. Les personnes sont rassemblées en _sections_, plusieurs _sections_ forment une _équipe_, plusieurs _équipes_ forment un _groupe_. Mais les _groupes_ peuvent aussi être un ensemble de personnes sans répartition par _équipe_. Et les _équipes_ peuvent être un ensemble de personnes sans répartition par _section_
On a deux mesures : 
- **Eff** : efficacité dans la tâche, exprimée en pourcentage, la valeur n'est pas additive : le résultat d'une _équipe_ est indépendant des résultats des _sections_ qui la composent.
- **Pax** : le nombre de personnes, la valeur est additive : le nombre de personnes dans une _équipe_ correspond à la somme du nombre de personnes dans les _sections_ qui la composent.

```
└───Root : Eff = 55% / Pax = 35
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

## Les données en entrée

On récupère les données au format tabulaire : ```Elément | Parent | ValeurA | ValeurB | ...``` 

Elément | Parent | Eff | Pax
--- | --- | --- | ---
Root | _null_ | 55 | _null_
Grp_A | Root | 60 | _null_
Eqp_A1 | Grp_A | 40 | 5
Eqp_A2 | Grp_A | 70 | _null_
Sec_A2_ker | Eqp_A2 | 75 | 2
Sec_A2_bis | Eqp_A2 | 55 | 2
Grp_B | Root | 65 | _null_
Eqp_B1 | Grp_B | 40 | _null_
Sec_B1_ker | Eqp_B1 | 70 | 2
Sec_B1_bis | Eqp_B1 | 40 | 2
Sec_B1_ter | Eqp_B1 | 20 | 2
Eqp_B2 | Grp_B | 35 | 5
Eqp_B3 | Grp_B | 30 | 5
Grp_C | Root | 30 | 10

Il est important que la racine de la hiérarchie (_Root_) soit une valeur nulle comme parent (et pas une valeur vide).
Il est possible d'avoir plusieurs racines qui sont chacunes au début d'une hiérarchie.

On ajoute également une colonne d'index.

![image](/Images/20230118-hierarchie-desequilibree/analysePerf-initial.png)

## Colonnes calculées

Un fois la table chargée dans le modèle, on va créer plusieurs colonnes et mesures pour rendre la hiérarchie facilement utilisable.
Pour cela on va notamment utiliser les [fonctions parents et enfants](https://learn.microsoft.com/fr-fr/dax/parent-and-child-functions-dax).

- **Path** : Crée le _chemin_ de l'élément à partir de la racine. Les niveaux sont séparés par des tubes.
```
Path = PATH(AnalysePerf[Elément], AnalysePerf[Parent])
``` 

- **Depth** : Enregistre la profondeur de l'élément : 1 pour la racine, 2 pour les groupes, 3 pour les équipes ...
```
Depth = PATHLENGTH(AnalysePerf[Path])
```

- **Leaf** : Indique si l'élément est une feuille dans la hiérarchie (s'il n'a pas d'enfant). Pour une utilisation plus simple dans les filtres, la colonne est de type entier plutôt que booléen.
```
Leaf = IF(COUNTROWS(FILTER(AnalysePerf, PATHCONTAINS(AnalysePerf[Path], EARLIER(AnalysePerf[Elément])))) = 1, 1, 0)
```

On va à présent recomposer la hiérarchie en ajoutant une colonne par niveau. Il y a 4 niveaux dans notre exemple, il faut donc ajouter 4 colonnes.

```
Niveau 1 = PATHITEM(AnalysePerf[Path], 1)
Niveau 2 = PATHITEM(AnalysePerf[Path], 2)
Niveau 3 = PATHITEM(AnalysePerf[Path], 3)
Niveau 4 = PATHITEM(AnalysePerf[Path], 4)
```

Les colonnes créées peuvent être réunies dans une hiérarchie.

![image](/Images/20230118-hierarchie-desequilibree/analysePerf-colonnes_calculees.png)

_NB : La méthode pour répéter les niveaux à la place de valeurs vides est décrite plus bas._

### Champs calculés

La table est prète à être utilisée, on va créer les mesures qui vont gérer les valeurs non-additives et additives.

- **RowDepth** : la profondeur de la ligne dans la table source.
```
RowDepth = MIN(AnalysePerf[Depth])
```

- **BrowseDepth** : la profondeur dans la hiérarchie du niveau affiché.
```
BrowseDepth = SWITCH(TRUE()
, ISINSCOPE(AnalysePerf[Niveau 4]), 4
, ISINSCOPE(AnalysePerf[Niveau 3]), 3
, ISINSCOPE(AnalysePerf[Niveau 2]), 2
, ISINSCOPE(AnalysePerf[Niveau 1]), 1
)
```

- **RowPath** : le chemin de la ligne en cours dans la hiérarchie.
```
RowPath = FIRSTNONBLANK(AnalysePerf[Path], TRUE())
```
