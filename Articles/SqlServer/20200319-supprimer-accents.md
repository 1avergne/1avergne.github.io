# Retirer les accents dans un texte

<p style="text-align: right;">2020-02-28</p>

Il est parfois nécessaire de retirer les accents dans des champs d'une requête PowerQuery / M ou dans une table SQL. Par exemple pour faire une jointure sans avoir à passer par un Fuzzy Lookup.

J'avais imaginé il y a quelques années des solutions compliquées pour faire cela en [SQL](https://1avergne.azurewebsites.net/post/2020/02/28/sql-retirer-les-accents-et-caractere-speciaux) et en [PowerQuery](https://1avergne.azurewebsites.net/post/2019/09/05/powerquery-m-retirer-les-accents). Mais même si j'aime beaucoup les solutions compliquées, c'est plus simple de faire des choses simples (à cause de la simplicité) ...

Donc voici comment _simplement_ retirer les accents d'un texte.

## PowerQuery 

La solution consiste à convertir le code en binaire pour ensuite le repasser en code avec un encodage ASCII. 
Pour cela on crée une nouvelle colonne : ```Text.FromBinary(Text.ToBinary ([#"Texte-avec-accent"], 1251), TextEncoding.Ascii))```

![image](/Images/accent-powerquery.png)

```
let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("NYy5TsNAFAB/5ck1QhENdXr+wLhYzCJW2ogo9kqUEIi470NchcMhbO4joAQIFKP9LwwITTPNTBgGzDBLkznmaZHR5pQzzrlgmx122SvZ54AnnunwwitdFllimRVyCq645oEFLtlklTXW2eCGW+6455AjjjmhxxvvfLDFo89823f5ou/7/jOIBsJgRIl1NUPe0EIRW2VKsUriBnlNi3LTkpY6YXUiZGJHXaUyNKzcmBYTG9GpWLLB31XV/VRF3SWxs38TinFjS5+iJzpJ//NJOnWTKhtE0Tc=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Texte-avec-accent" = _t]),
    #"Personnalisée ajoutée" = Table.AddColumn(Source, "Texte-sans-accent", each Text.FromBinary(Text.ToBinary  ([#"Texte-avec-accent"], 1251 ),  TextEncoding.Ascii))
in
    #"Personnalisée ajoutée"
```

_Merci [Denis](https://stackoverflow.com/questions/71969831/power-query-how-to-remove-diacritic-accent-symbols-from-text) !_

## PowerQuery _version alternative_

Une autre méthode est d'établir la liste des caractères de substitution et de les remplacer dans le texte initial.

Liste de réference : *Liste_Correspondance*
```m
let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("RdA5CgJRFETRvbz476j5gYiBiQbSgb0aRxzaoW0HnA3k78vSB97scKGSyjJ7DyxYw2IQh3AEx3ACp7AWu849PMAjPMEznIst5wIuYQkrZjOx6VyJbecabuAWXsTceYU3eIc7sfNj+r7T8/oS+87Hn+kpFhbjBw==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [ori = _t, des = _t]),
    TableToList = Table.ToColumns(Table.Transpose(Source))
in
    TableToList
```

On crée une nouvelle colonne : ```Table.AddColumn(Source, "Personnalisé", each Text.Combine(List.ReplaceMatchingItems(Text.ToList(Text.Lower([#"Texte-avec-accent"])), Liste_Correspondance)))```

```m
let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("NYy5TsNAFAB/5ck1QhENdXr+wLhYzCJW2ogo9kqUEIi470NchcMhbO4joAQIFKP9LwwITTPNTBgGzDBLkznmaZHR5pQzzrlgmx122SvZ54AnnunwwitdFllimRVyCq645oEFLtlklTXW2eCGW+6455AjjjmhxxvvfLDFo89823f5ou/7/jOIBsJgRIl1NUPe0EIRW2VKsUriBnlNi3LTkpY6YXUiZGJHXaUyNKzcmBYTG9GpWLLB31XV/VRF3SWxs38TinFjS5+iJzpJ//NJOnWTKhtE0Tc=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Texte-avec-accent" = _t]),
    #"Added Custom" = Table.AddColumn(Source, "Personnalisé", each Text.Combine(List.ReplaceMatchingItems(Text.ToList(Text.Lower([#"Texte-avec-accent"])), Liste_Correspondance)))
in
    #"Added Custom"
```

## SQL

Il existe en T-SQL la fonction [_TRANSLATE_](https://docs.microsoft.com/fr-fr/sql/t-sql/functions/translate-transact-sql) qui permet de remplacer les caractère d'une liste, par leur equivalents dans une autre liste.

Par exemple ```select TRANSLATE('où fuît-il les éphémères ?', 'àéèùî', 'aeeui')``` renvoit _ou fuit-il les ephemeres ?_ 

On peut donc utiliser la fonction avec la liste de tous les caractères accentués.

```sql
DECLARE @avecAccent VARCHAR(55) = 'àáâãäåòóôõöøèéêëðçìíîïùúûüñšÿýž'
DECLARE @sansAccent VARCHAR(55) = 'aaaaaoooooooeeeedciiiiuuuunsyyz'
SELECT [ProduitDesc]
    ,TRANSLATE([ProduitDesc], @avecAccent, @sansAccent) as [ProduitDescSansAccent]
    ,[GammeDesc]
    ,[TypeProduitDesc]
FROM [dbo].[DimProduit]
WHERE TRANSLATE(ProduitDesc, @avecAccent, @sansAccent) <> [ProduitDesc]
```

![image](/Images/accent-sql.png)

**Attention** : La fonction suit la collation de la base de données. Si la base est configurée comme insensible à la casse ; les caractère seront remplacés par le premier équivalent trouvé majuscules et minuscules confondues. Par exemple ```select TRANSLATE('où fuît-il les ÉPHÉMÈRES ?', 'àéèùÎ', 'aeeuI')``` renvoit _ou fuIt-il les ePHeMeRES ?_ 