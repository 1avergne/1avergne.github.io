# DAX Design pattern

<p style="text-align: right;">2026-05-22</p>

*Ceci est un article perpétuel, qui sera compété au fil du temps et des idées.*

## Syntaxe et convention de nommage

Lorsque j'écris du code DAX, je suis quelques règles de syntaxe afin d'avoir un code propre et lisible. Pour autant je ne m'impose pas une indentation stricte ; pour les instructions les plus simples j'écrit mon code sur une seule ligne.

- virgules en début de ligne
- fonctions en majuscule
- pas d'espace après les nom de fonction ou les parenthèses, un espace après les virgules : ```t_cal = CALENDAR(DATE(2020, 1, 1), TODAY())```
- si l'instruction est assez longue, je rajoute une espace avant la parenthèse fermante de la première fonction : ```t_cal = CALENDAR(DATE(2020, 1, 1), EOMONTH(MAX(t_fact[date_fact]), 0) )```
- nom de variable en *CamelCase* précedé d'un tiret-bas : ```VAR _varDate = MAX(dim_calendrier[jour])```

Pour mettre en forme rapidement le code DAX ; je ne peux que conseiller le très utile [DAX Formatter](https://www.daxformatter.com/).

## Optimisation et choix des fonctions

Comme pour beaucoup de choses, il existe de nombreuses méthodes pour arriver au même résultat. Mes certains chemins sont plus courts que d'autres. Voici quelques astuces pour avoir un code performant et maintenable.

- Au delà de deux appels de la même mesure dans le même contexte, utiliser une variable.
- Au delà de deux [*IF*](https://learn.microsoft.com/fr-fr/dax/if-function-dax) imbriqués, utiliser la fonction [*SWITCH*](https://learn.microsoft.com/fr-fr/dax/switch-function-dax) : 
```sql (dax)
IF([mesure_test], 0, IF([mesure_test_2] > 1000), -1, [mesure_test_2])
```

<p style="text-align: center;">🡻 devient 🡻</p>

```sql (dax)
VAR _mesure_test_2 = [mesure_test_2]
RETURN SWITCH(TRUE()
    , NOT(ISBLANK([mesure_test])), 0
    , _mesure_test_2 > 1000), -1
    , _mesure_test_2
)
```

- Certaines fonctions permettent d'éviter l'utilisation de condition : [*COALESCE*](https://learn.microsoft.com/fr-fr/dax/coalesce-function-dax) pour remplacer une valeur vide, [*MAX*](https://learn.microsoft.com/fr-fr/dax/max-function-dax) et [*MIN*](https://learn.microsoft.com/fr-fr/dax/min-function-dax) pour borner des une valeur, [*SELECTEDVALUE*](https://learn.microsoft.com/fr-fr/dax/selectedvalue-function-dax) renvoie la valeur sélectionnée dans un champ uniquement si elle est unique.
```sql (dax)
VAR _mesure_test = [mesure_test]
RETURN IF(ISBLANK(_mesure_test), 0, IF(_mesure_test > 1000, 1000, _mesure_test))
```

<p style="text-align: center;">🡻 devient 🡻</p>

```sql (dax)
MIN(COALESCE([mesure_test], 0), 1000)
```

## *Design pattern* de mesures

### Date et temps

Voici quelques exemple de mesures pour des cas d'usages génériques : 

#### Convertir une durée en seconde vers un le type *time*

La mesure revoit un valeur de type *DateTime* correspondant au nombre de secondes donné par la mesure source.
Si la durée dépasse 24 heures (86 400 secondes) la mesure renvoie le modulo à la journée.

```sql (dax)
ValTime = VAR _v = [ValSelected]
    VAR _h = FLOOR(DIVIDE(_v, 3600), 1)
    VAR _m = FLOOR(DIVIDE(MOD(_v, 3600), 60), 1)
    VAR _s = MOD(_v, 60)
RETURN TIME(_h, _m, _s)
```

## Comptage



### Compter le nombre d'utilisateurs sur une période 

```sql (dax)
user_nb = DISTINCTCOUNT(t_fact_app_usage[user_principal_name])
```

### Compte le nombre de nouveaux utilisateurs

Le nombre d'utilisateurs enregistrés pour la première fois sur la période observée.

```sql (dax)
user_new_nb = VAR _current = DISTINCT(t_fact_app_usage[user_principal_name])
    VAR _previous = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] < MIN(t_dim_calendrier[dt_date]))
    )
RETURN COUNTROWS(EXCEPT(_current, _previous))
```

### Compter le nombre d'utilisateurs régulier

Le nombre d'utilisateurs enregistrés sur la période observée et qui ont au moins un autre enregistrement avant le début de la période observée.

```sql (dax)
user_old_nb = VAR _current = DISTINCT(t_fact_app_usage[user_principal_name])
    VAR _previous = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] < MIN(t_dim_calendrier[dt_date]))
    )
RETURN COUNTROWS(INTERSECT(_current, _previous))
```

### Compter le nombre d'utilisateurs perdus

Le nombre d'utilisateurs avec au moins un enregitrement avant le début de la période observée et n'ont plus aucun enregistrement à partir du début de la période observée.

```sql (dax)
user_lost_nb = VAR _current = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] >= MIN(t_dim_calendrier[dt_date]))
    )
    VAR _previous = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] < MIN(t_dim_calendrier[dt_date]))
    )
RETURN COUNTROWS(EXCEPT(_previous, _current)))
```

## Images

### Utiliser une image encodé en base64

### Utiliser une illustration en SVG