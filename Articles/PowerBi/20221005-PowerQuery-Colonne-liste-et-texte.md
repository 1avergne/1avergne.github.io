# PowerQuery - Traiter une colonne avec des valeurs de type _list_ et de type _text_

Lorsqu'on intègre des données venant d'une source _json_ il arrive d'avoir des champs contenant des listes mélangées à du texte :

![image](/Images/20221005-PowerQuery-Colonne-liste-et-texte/Requete-liste-texte.png)

Si on extraie les valeurs de la colonne, on obtient une erreur pour chaque valeur _texte_.

![image](/Images/20221005-PowerQuery-Colonne-liste-et-texte/Requete-liste-erreur.png)

La solution consiste à ajouter une colonne personalisée où l'on teste le type de la valeur :
- s'il s'agit d'une liste, on extrait les données
- sinon on renvoie la valeur telle qu’elle

Le type d'une colonne se récupère avec la fonction [```Value.Type```](https://learn.microsoft.com/fr-fr/powerquery-m/value-type) qui renvoit un objet _type_. Il faut donc utiliser l'instruction dans une fonction [```Type.Is```](https://learn.microsoft.com/fr-fr/powerquery-m/type-is) pour faire la comparaison.
On peut ensuite supprimer la colonne d'origine.

```
if Type.Is(Value.Type([raw expression]), type list)
then Text.Combine(List.Transform([raw expression], Text.From))
else [raw expression]
```

![image](/Images/20221005-PowerQuery-Colonne-liste-et-texte/Requete-texte-texte.png)