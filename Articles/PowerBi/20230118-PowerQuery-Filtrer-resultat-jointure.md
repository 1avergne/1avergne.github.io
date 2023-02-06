# PowerQuery - Filtrer le résultat d'une jointure

<p style="text-align: right;">2023-01-18</p>

Lorsqu'on utilise la fonctionnalité _Fusionner des requêtes_ dans PowerQuery, le résultat est disponible dans une nouvelle colonne. On va ensuite déployer cette colonne en une ou plusieurs nouvelles lignes pour obtenir un résultat similaire à une jointure en _SQL_. On peut _développer_ la colonne (chaque ligne de la table jointe est ajoutée) ou _agréger_ (une seule valeur par ligne, un comptage ou une somme des colonnes de la table jointe).

![image](/Images/20230118-PowerQuery-Filtrer-resultat-jointure/fusion_agreger.png)

Mais parfois on ne s'intéresse qu'à un sous-ensemble du résultat de la requête. Par exemple : 
- pour chaque ligne **la valeur la plus récente** dans la table jointe
- pour chaque ligne **la valeur avec l'identifiant le plus petit** dans la table jointe
- pour chaque ligne **le nombre de valeur identique** à la ligne en cours et qui apparaissent plus bas dans la table.

Une fois la colonne issue de la fusion développée, on perd la notion de regroupement par ligne : il faut refaire une agrégation pour avoir ces résultats. On va donc plutôt faire les calculs avant le développement de la colonne. 

Il y a deux **méthode** : faire une fonction ou utiliser une **colonne personnalisée**.

## Faire une fonction

La fonction est une solution intéressante si la transformation à faire est complexe (au-delà d'une demi-douzaine d'étapes) mais elle est assez fastidieuse à mettre en place.

La méthode pour créer une fonction est décrite dans [la documentation Microsoft](https://learn.microsoft.com/en-us/power-query/custom-function).

## Colonne personnalisée

Si on a juste à filtrer la table récupérée par la jointure, on peut le faire directement dans une colonne personnalisée. On va utiliser une fonction _M_ qui traite habituellement une table en lui passant à la place la colonne de la jointure.

### Exemple : le taux de change le plus récent

J'ai une liste de contrats avec des valeurs correspondant à des salaires dans des devises différentes. J'ai une seconde table avec les taux de change par devise vers l'USD. Il y a plusieurs valeurs de taux pour chaque devise, je souhaite utiliser la plus récente pour convertir tous les salaires en USD.

- _table Contract_

![image](/Images/20230118-PowerQuery-Filtrer-resultat-jointure/table_contract.png)

- _table Currency Rate_

![image](/Images/20230118-PowerQuery-Filtrer-resultat-jointure/table_currency_rate.png)

1. Je fais la jointure entre la table _Contract_ et _Currency rate_ grâce à la fonctionnalité _fusionner des requêtes_. Il y a donc une nouvelle colonne _Currency rate_.

![image](/Images/20230118-PowerQuery-Filtrer-resultat-jointure/fucion_contract_rate.png)

2. J'ajoute une colonne personalisée. Dans la formule de colonne, j'utilise la fonction ```Table.SelectRows``` qui permet de filtrer une table. Mais dans notre cas, la table utiliser sera la colonne de la jointure :

```Table.SelectRows([Currency rate], let latest = List.Max([Currency rate][rate_date]) in each [rate_date] = latest)```

3. Je peux à présent développer la colonne personnalisée qui ne contient qu'une seule valeur par ligne.

![image](/Images/20230118-PowerQuery-Filtrer-resultat-jointure/developper_current_rate.png)

### Faire une sous-requête

Si la transformation nécessite plusieurs étapes, on utilise une sous-requête au même format qu'une requête _M_ habituelle : ```let ... in ...```
Par exemple je souhaite à présent garder le taux de change le plus récent parmi les taux de changes antérieurs à la date de fin du contrat. Je veux aussi passer l'étape _développer_ en récupérant directement la valeur dans la sous-requête.

```
let 
A = [date_end],
B = Table.SelectRows([Currency rate], each [rate_date] <= A ),
C = Table.SelectRows(B, let latest = List.Max(B[rate_date]) in each [rate_date] = latest),
D = C[rate]{0}
in D
```

![image](/Images/20230118-PowerQuery-Filtrer-resultat-jointure/ajouter_nouvelle_requete_sousrequete.png)

Pour simplifier la création de la sous-requête, on peut utiliser l'option _Ajouter en tant que nouvelle requête_ sur une cellule de la colonne issue de la jointure. Cela crée une nouvelle requête qu'on va pouvoir modifier et ensuite récupérer le code _M_ généré pour l'adapter.

