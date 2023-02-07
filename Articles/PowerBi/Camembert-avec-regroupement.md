# Un camembert avec le regroupement des petites catégories

<p style="text-align: right;">2021-07-23</p>

Le problème quand on fait un diagramme en camembert (Piechart) c'est que les toutes petites catégories ne sont pas bien lisibles : on a souvent une série de toutes petites tranches "tassées" et ce qui ne donne pas vraiment d'information pertinente. 

![image](/Images/camembert-sans-categories.png)

C'est pour cela qu'il est parfois mieux de regrouper les valeurs faibles dans une seule catégorie "autres". Certains visuels custom proposent cette option (par exemple celui-là). Mais si comme moi vous préférez utiliser au maximum les visuels standards, voilà comment faire !

![image](/Images/camembert-ouverture-pbi.gif)

J'utilise un modèle simple basé sur la base de démo EchoPilote. Les données de faits sont dans la table "Vente Detail", on va analyser les ventes à travers la dimension "Produit". L'objectif est de faire un Piechart des ventes par produits où tous les produits avec une part de vente inférieure à 2% sont regroupés dans une seul catégorie "Autres produits".

![image](/Images/camembert-modele-echopilote.png) 

## 1. Modification des données :
J'ajoute une nouvelle ligne dans la table des produits, l'agrégation dans le Piechart se fera sur cette valeur.
Dans mon cas j'ajoute la ligne en M dans l'éditeur de requêtes. Mais il est possible de le faire directement au niveau de la source (vue SQL, fichier …).

Je crée une nouvelle table avec uniquement ma ligne de valeur. Il faut faire attention a utiliser un ID qui n'est pas utilisé :

![image](/Images/camembert-create-table.png)

Je désactive le chargement de cette nouvelle table. Je l'ajoute à la requête "Produit" :

![image](/Images/camembert-append-table.png)

![image](/Images/camembert-resultat-table.png)

Mon modèle est donc inchangé, il y a juste une ligne supplémentaire dans ma dimension produit.

## 2. Mesure DAX :

Il y a déjà deux mesures dans mon modèle : CA -> la somme de mes prix de ventes.

```CA = SUM('Vente Detail'[Prix])```

CA % Produits -> le pourcentage du CA pour un produit par rapport à tous les autres produits.

```CA % Produits = DIVIDE([CA], CALCULATE([CA], ALLSELECTED(Produit)))```

Je vais utiliser une nouvelle mesure pour afficher mes valeurs dans le Piechart. La mesure doit appliquer la règle suivante : si le pourcentage du CA pour un produit est supérieur à une valeur seuil ( 2% ), je l'affiche ; sinon la valeur n'est pas affichée pour le produit mais est cumulée à la valeur de la ligne "Autres produits".

Faisons déjà la moitié de la formule, c’est-à-dire filtrer les valeurs inférieures au seuil. Je déclare la valeur seuil dans une variable et je test ma mesure [CA % Produits] ; si je suis en dessous je renvois BLANK().

```
CA (gp) = VAR s = 0.02
RETURN if([CA % Produits] >= s, [CA], BLANK())
```

![image](/Images/camembert-avec-categories.png)

On voit que les parts du camembert les plus petites ne sont plus affichées.

Il faut à présent afficher le regroupement. On va tester l'ID du produit courant, s'il s'agit de l'ID de "Autres produits" (ID = -1) on calcul la part des produits sous le seuil (ligne 2). J'utilise un SUMX pour parcourir la liste des produits, les valeurs sont sommées si [CA % Produits] est inférieur au seuil (ligne 3).

```
CA (gp) = VAR s = 0.02
RETURN if(SELECTEDVALUE(Produit[ProduitID]) = -1
, SUMX(ALLSELECTED(Produit), if([CA % Produits] < s, [CA], BLANK()))
, if([CA % Produits] >= s, [CA], BLANK())
)
```

![image](/Images/camembert-avec-categories2.png)

Avec un seuil de 2%, la catégorie "Autres produits" s'est glissée à la 2e place.

## 3- Seuil dynamique :

Il serai maintenant intéressant de pouvoir changer dynamiquement le seuil.
Pour cela on va utiliser un paramètre "what-if"

![image](/Images/camembert-parametre-whatif-bouton.png)

![image](/Images/camembert-parametre-whatif-config.png)

Dans la mesure, je remplace la variable "s" par la valeur sélectionnée dans le segment :

```
CA (gp) = if(SELECTEDVALUE(Produit[ProduitID]) = -1
, SUMX(ALLSELECTED(Produit), if([CA % Produits] < [Seuil % Value], [CA], BLANK()))
, if([CA % Produits] >= [Seuil % Value], [CA], BLANK())
)
```

La valeur de seuil peut être maintenant sélectionnée directement dans le segment.

![image](/Images/camembert-avec-categories-dyn.gif)