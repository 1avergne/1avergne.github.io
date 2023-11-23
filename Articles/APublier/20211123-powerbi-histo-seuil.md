# Un histogramme délimité par un seuil

<p style="text-align: right;">2021-11-23</p>

Hier un collègue m'a envoyé la maquette d'un rapport avec un visuel particulier : 

![image](/Images/20211123-powerbi-histo-seuil/ex1-maquette.png)

Un histogramme avec une ligne horizontale, où la couleur des barres est différente au-dessus et en-dessous de cette ligne.

Et forcément je me suis demandé comment le reproduire dans Power BI !

Je repars d'un jeu de données *démo* (une base retail ventes par produit) et je commence par faire un histogramme simple basé sur la mesure *Quantite_* et réparti par catégorie de produit.

![image](/Images/20211123-powerbi-histo-seuil/ex1-histo-simple.png)

## L'histogramme et le seuil

La première chose à faire est de créer un paramètre numérique pour sélectionner le seuil qui va "partitionner" l'histogramme.
Je crée le paramètre *Seuil histogramme* qui va de 0 à 15 000 (on pourra rendre cette valeur dynamique plus tard), et qui évolue par pas de 100.

![image](/Images/20211123-powerbi-histo-seuil/ex1-creation-parametre.png)

Je modifie le type de mon histogramme pour en faire un *Graphique en courbes et histogramme empilé*. Et j'ajoute la mesure *Valeur Seuil histogramme* comme valeur de l'axe Y de la ligne. La ligne apparait en fonction du paramètre.

![image](/Images/20211123-powerbi-histo-seuil/ex1-histo-courbe.png)

## Des sections dans les barres de l'histogramme

Je vais ensuite définir deux mesures DAX, une pour la section de la barre qui est sous le code, et une autre pour la section au-dessus de la ligne. J'utilise les fonction *MIN* et *MAX* avec deux  arguments : la fonction renvoi l'argument le plus petit (*MIN*) ou le plus grand (*MAX*) des deux.

```
Quantite_bornee = MIN([Quantite_], [Valeur Seuil histogramme])
```

```
Quantite_excedant = MAX([Quantite_] - 'Seuil histogramme'[Valeur Seuil histogramme], 0)
```

Dans le visuel, je remplace la mesure *Quantite_* par les mesures *Quantite_bornee* et *Quantite_excedant*.

La ligne horizontal vient à présent séparer les deux mesures matérialisées par deux sections de l'histogramme.

## Synchroniser les échelles

Mais on a un problème, si la valeur du paramètre est très éloignée du maximum de l'histogramme, Le visuel affiche une deuxième échelle à droite de l'histogramme. la ligne n'est plus alignée avec le changement de section.

![image](/Images/20211123-powerbi-histo-seuil/ex1-histo-courbe-ligne2-ecart.png)

Pour corriger cela on va forcer les échelles utilisées dans le visuel.
Je crée une nouvelle mesure qui récupère la quantité maximum parmi les catégories de produit. J'utilise la fonction *CEILING* pour arrondir la valeur au millier immédiatement supérieur.

```
Quantite_max = CEILING(MAXX(ALLSELECTED(Produit[GammeDesc]), [Quantite_]), 1000)
```

Dans les paramètres du visuel, je sélectionne les options suivantes : 

![image](/Images/20211123-powerbi-histo-seuil/ex1-synchro_echelles.png)

A présent les deux échelles des Y sont identiques, la ligne horizontale va rester aligné avec délimitation des barres de l'histogramme.

## La touche finale

Mon visuel ressemble à present à ce que je voulais !

![image](/Images/20211123-powerbi-histo-seuil/ex1-histo-courbe-ligne3-demo.gif)

Pour finaliser le visuel, je peux changer la couleur des colonnes et le format de la ligne (trait simple ou pointillés), ajouter des étiquettes, changer le format.
Je peux également modifier la formule de la table *Seuil histogramme* pour utiliser la mesure *Quantite_max* comme borne haute du paramètre.

```
Seuil histogramme = GENERATESERIES(0, [Quantite_max], 100)
```
