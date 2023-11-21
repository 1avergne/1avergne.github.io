# Power Query - Gérer les colonnes dynamiquement

<p style="text-align: right;">2023-11-21</p>

Lorsqu'on charge une source dans Power Query, il arrive que le format de la source change (d'un fichier à l'autre par exemple). Même si on préfèrerait refuser le fichier et imposer un format, ce n'est pas toujours possible... Il faut parfois savoir s'adapter.

![image](https://i.kym-cdn.com/entries/icons/original/000/023/987/overcome.jpg)

## Supprimer les colonnes sans en-tête

Disons que je charge un tableau avec les en-têtes en première ligne et que certains en-têtes ne sont pas définis. En utilisant la fonction "Utiliser la première ligne pour les en-têtes", les colonnes avec une valeur vide dans les premières lignes seront nommées *Column1*, *Column2*, *Column3*...

![image](/Images/20231121-powerquery-columns/Ex1-PromotedHeaders.png)

Pour supprimer les colonnes sans en-tête on va lister ces colonnes et utiliser cette liste dans une fonction *Table.RemoveColumns* :

1. Récupérer la liste des colonnes : avec la fonction M *Table.ColumnNames*. Pour appeler la fonction j'ajoute une étape vide dans la requête : clic-droit sur la dernière étape puis "Insérer l'étape après". Cela crée une étape vide (qui appelle sans modification l'étape précédente). Je peux ensuite écrire mon code dans la barre de formule.

![image](/Images/20231121-powerquery-columns/Ex1-ColumnNames.gif)

2. Filtrer la liste pour ne garder que les noms de colonnes qui commence par "Column" avec la fonction M *List.Select*

![image](/Images/20231121-powerquery-columns/Ex1-ColumnsToRemove.png)

3. Supprimer les colonnes en utilisant la liste comme paramètre de la fonction de suppression. Les colonnes listées sont retirées de la table.

![image](/Images/20231121-powerquery-columns/Ex1-RemovedColumns.png)

```M
let
    Source = TableSource,
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ColumnsToRemove = List.Select(Table.ColumnNames(PromotedHeaders), each Text.StartsWith(_, "Column")),
    RemovedColumns = Table.RemoveColumns(PromotedHeaders,ColumnsToRemove)
in
    RemovedColumns
```
## Supprimer les colonnes selon un filtre

Même méthode ! Mais en modifiant le filtre appliqué. Plutôt que ```each Text.StartsWith(_, "Column")``` on va utiliser un filtre qui correspond au cas d'usage.

Et si on souhaite conserver certaines colonnes plutôt que de les supprimer, on utilisera la fonction *Table.SelectColumns* qui supprime les autres colonnes.


## Renommer des colonnes avec des noms variables

Dans mon exemple les colonnes des valeurs ont une année dans l'en-tête. Cela est contraignant si le libellé change : mes colonnes "Value 2023" et "Value 2022" vont devenir "Value 2024" et "Value 2023" l'année prochaine.
Pour avoir des noms de colonnes constants, on souhaite renommer dynamiquement ces colonnes en "Value N" et "Value N-1".

![image](/Images/20231121-powerquery-columns/Ex2-Source.png)

On va donc une liste dynamique dans la fonction *Table.RenameColumns* pour renommer les colonnes :

1. Comme précédemment, on récupère la liste des colonnes que l'on filtre pour ne Garder que les colonnes à renommer.

![image](/Images/20231121-powerquery-columns/Ex2-ColumnNames.png)

2. La liste est ensuite convertie en table.

![image](/Images/20231121-powerquery-columns/Ex2-ConvertedToTable.png)

3. On ajoute une deuxième colonne qui contient le nom après renommage. Dans mon exemple j'utilise de *Text.Replace* successifs. On peut bien-sûr envisager une règle plus complexe ou l'utilisation de colonnes intermédiaires.

![image](/Images/20231121-powerquery-columns/Ex2-AddedRenamedColumn.png)

4. On ajoute une troisième colonne qui va contenir le contenu des colonnes 1 et 2 sous forme de liste. 

![image](/Images/20231121-powerquery-columns/Ex2-AddListColumn.png)

5. Cette colonne est ensuite convertie en liste.

![image](/Images/20231121-powerquery-columns/Ex2-ConvertToList.png)
 
6. C'est cette liste qui est utilisée dans la fonction *Table.RenameColumns*. On repart de la table *Source* à laquelle on applique le renommage.

![image](/Images/20231121-powerquery-columns/Ex2-RenamedColumns.png)

```M
let
    Source = Faits,
    ColumnNames = List.Select(Table.ColumnNames(Source), each Text.StartsWith(_, "Value")),
    ConvertedToTable = Table.FromList(ColumnNames, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    AddedRenamedColumn = Table.AddColumn(ConvertedToTable, "Column2", each Text.Replace(Text.Replace([Column1], "2023", "N"), "2022", "N-1")),
    AddedListColumn = Table.AddColumn(AddedRenamedColumn, "ColumnL", each Record.ToList(_)),
    ConvertToList = AddedListColumn[ColumnL],
    RenamedColumns = Table.RenameColumns(Source,ConvertToList)
in
    RenamedColumns
```

## Ajouter des colonnes manquantes

Il arrive que certaines colonnes nécessaires au chargement soient absentes du fichier source. Il faut alors les ajouter dans les premières étapes du traitement.
La méthode la plus simple pour faire cela est de définir la liste des colonnes nécessaire au traitement et de la combiner à la requête initiale pour que celle-ci soit complétée avec les colonnes manquantes.

1. Avec la fonctionnalité "Entrer des données", on définit une table vide avec les colonnes souhaitées. On peut supprimer l'étape de typage si elle est ajoutée automatiquement.

![image](/Images/20231121-powerquery-columns/Ex3-Source.png)

2. Dans la requête de la table à compléter, avec l'option "Ajouter des requête", ajouter la requête définie précédemment (celle avec uniquement les en-têtes). 
 
![image](/Images/20231121-powerquery-columns/Ex3-AppendedQuery.gif
