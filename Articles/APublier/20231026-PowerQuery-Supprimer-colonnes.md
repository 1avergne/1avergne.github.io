# PowerQuery - Supprimer des colonnes selon une condition

<p style="text-align: right;">2023-10-26</p>

Lorsqu'on charge une source dans Power Query, il arrive que le format de la source change (d'un fichier à l'autre par exemple). Même si on préfèrai refuser le fichier et imposer un format, ce n'est pas toujours possible... Il faut parfois savoir s'adapter.

![image](https://i.kym-cdn.com/entries/icons/original/000/023/987/overcome.jpg)

## Supprimer les colonnes sans en-tête

Disons que je charge un tableau avec les en-têtes en première ligne et que certains en-têtes ne sont pas définis. En utilisant la fonction "Utiliser la première ligne pour les en-têtes", les colonnes avec une valeur vide dans la première lignes seront nommées Column1, Column2, Column3...

Pour supprimer 

