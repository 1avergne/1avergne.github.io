# Validation de données avec menu déroulant à partir d'une formule

<p style="text-align: right;">2021-11-29</p>

![image](/Images/20211129-Excel-validation-liste-formule/outils_donnees.png)

Dans Excel, si on veut faire une validation de données sur un champ avec un menu déroulant il faut utiliser l'option **Autoriser : Liste** et définir un jeu de données de référence.

![image](/Images/20211129-Excel-validation-liste-formule/validation_autoriser_liste.png)

Mais si on souhaite utiliser une formule (pour filtrer ou supprimer les doublons), il faut utiliser l'option **Autoriser : Personnalisé** qui ne propose pas de liste déroulante.

## 0- Par exemple

J'ai une liste d'équipements avec des propriétés (une ligne par propriété, les équipements sont répétés).

![image](/Images/20211129-Excel-validation-liste-formule/liste_equipements.png)

Je souhaite pouvoir choisir mon équipement dans un second tableau. Si je met une référence directe vers la colonne "Equipement" j'aurai des valeurs en double. De plus Je suis obligé de prendre plus de lignes en compte pour anticiper les nouvelles lignes dans mon tableau. J'ai donc des doublons et des lignes vides dans le menu déroulant ...

![image](/Images/20211129-Excel-validation-liste-formule/validation_autoriser_liste2.png)

Pour faire une validation qui prend en compte une formule, je procède ainsi :

## 1- Créer une liste dédoublonnée dans un nouvel onglet

Dans un nouvel onglet j'ajoute la liste des équipements avec la formule :

```
=TRIER(UNIQUE(FILTRE(tEquipement[Equipement];NBCAR(tEquipement[Equipement])>0)))
```

ou avec les noms de cellules :

```
=TRIER(UNIQUE(FILTRE(Feuil1!$A$2:$A$99;NBCAR(Feuil1!$A$2:$A$99)>0)))
```

- ```FILTRE / NBCAR > 0``` : filtre les valeurs vides
- ```UNIQUE``` : retire les doublons
- ```TRIER``` : trie les valeurs par ordre alphabétique

![image](/Images/20211129-Excel-validation-liste-formule/trier-unique-filtre.png)

## 2- Ajouter la validation de données

![image](/Images/20211129-Excel-validation-liste-formule/validation-donnees.png)

Dans l'option validation de données je définie comme source la colonne créée précédemment :

![image](/Images/20211129-Excel-validation-liste-formule/validation_autoriser_liste3.png)

Si on ne veux pas adresser toute la colonne mais uniquement pointer sur les cellules non vides, il est possible de limiter dynamiquement l'ensemble de cellules. J'utilise la fonction ```INDIRECT``` pour faire un adressage dynamique : 

```
=INDIRECT("Feuil3!$B$1:$B$" & 0 + NBVAL(Feuil3!$B1:$B99))
```

- ```0``` : le décalage de nombre de ligne (ici zéro, les données commencent à la première ligne)
- ```NBVAL``` : compte le nombre de valeurs dans la table
- ```INDIRECT``` : renvoie la plage de valeur en fonction de l'adresse stockée en texte
Dans le menu déroulant, j'ai bien une liste de valeurs uniques et triées :

![image](/Images/20211129-Excel-validation-liste-formule/validation_autoriser_liste4.png)

 