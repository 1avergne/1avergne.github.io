# Afficher une catégorie _Total_ dans un graphique

<p style="text-align: right;">2023-02-06</p>

Power BI ne permet pas d'afficher un total dans un graphique (courbe ou histogramme par exemple).
On va tout de même pouvoir affichée une telle catégorie en jouant avec les données et le DAX.
Il faudra :
- Ajouter la catégorie _Total_ à la dimension.
- Créer une mesure dédiée pour afficher la catégorie _Total_ lorsque c'est nécessaire.

## Ajouter la catégorie à la dimension

On ajoute la catégorie _Total_ dans la dimension. Il faut créer une ligne avec un identifiant et une valeur qui n'existe pas encore. J'utilise habituellement le terme __TOTAL_ : pour avoir la valeur en premier si la liste est triée par ordre alphabétique.
La catégorie peut être créée directement dans la source ou en PowerQuery. Cependant cela ne sera pas possible en DAX.

![image](/Images/20230206-categorie-total/dim_originale.png)

En PowerQuery, on va créer une table avec les mêmes colonnes que la table d'origine, et une seule ligne : la catégorie _Total_. On y ajoute une colonne _Flag Total_ qui sera _vrai_ pour le total.

![image](/Images/20230206-categorie-total/dim_categorie_total.png)

On fusionne ensuite la table d'origine à la nouvelle table. Les valeurs vide de la colonne _Flag Total_ sont remplacées par _faux_.

![image](/Images/20230206-categorie-total/dim_fusion.png)

### Utilisation d'une fonction

Pour créer la table avec la ligne _Total_ on peut utiliser une fonction PowerQuery. La fonction va reprendre les colonnes de la table passée en deuxième paramètre  et créer une seule ligne avec le libellé passé en premier paramètre. 

![image](/Images/20230206-categorie-total/fonction_ligne_total.png)

```
let
    Source = (#"Libellé TOTAL" as text, Query as any) => let
    Source = Table.FirstN(Query,0),
    #"En-têtes rétrogradés" = Table.DemoteHeaders(Source),
    #"Table transposée" = Table.Transpose(#"En-têtes rétrogradés"),
    #"Personnalisée ajoutée" = Table.AddColumn(#"Table transposée", "Column2", each #"Libellé TOTAL"),
    #"Table transposée1" = Table.Transpose(#"Personnalisée ajoutée"),
    #"En-têtes promus" = Table.PromoteHeaders(#"Table transposée1", [PromoteAllScalars=true]),
    #"Personnalisée ajoutée1" = Table.AddColumn(#"En-têtes promus", "Flag Total", each true),
    #"Type modifié" = Table.TransformColumnTypes(#"Personnalisée ajoutée1",{{"Flag Total", type logical}})
in
    #"Type modifié"
in
    Source
```

![image](/Images/20230206-categorie-total/fonction_ligne_total_appel.png)

## Créer une mesure dédiée

Pour la mesure dédiée, on va identifier lorsque la ligne total est dans le contexte courant en utilisant la colonne _Flag Total_. Pour cette ligne, on calcule la mesure en prenant toutes les catégories (```CALCULATE(... , ALLSELECTED(...```).
Pour les autres lignes, on utilise la mesure d'origine normalement.

```
revenu_moyenne_mobile_tot = IF(FIRSTNONBLANK('Secteur d''activité'[flag_total], HASONEVALUE('Secteur d''activité'[secteur_d_activite]))
, CALCULATE([revenu_moyenne_mobile], ALLSELECTED('Secteur d''activité'[secteur_d_activite]))
, [revenu_moyenne_mobile]
)
```

![image](/Images/20230206-categorie-total/moyenne-mobile-total.png)
