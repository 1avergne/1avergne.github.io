# DAX Design pattern

<p style="text-align: right;">2026-05-22</p>

*Ceci est un article perpétuel, qui sera complété au fil du temps et des idées.*

## Syntaxe et convention de nommage

Lorsque j'écris du code DAX, je respecte quelques règles de syntaxe afin d'avoir un code propre et lisible. Pour autant, je ne m'impose pas d'indentation stricte ; pour les instructions les plus simples j'écris mon code sur une seule ligne.

- virgules en début de ligne
- fonctions en majuscule
- pas d'espace après les noms de fonction ou les parenthèses, un espace après les virgules : ```t_cal = CALENDAR(DATE(2020, 1, 1), TODAY())```
- si l'instruction est assez longue, je rajoute un espace avant la parenthèse fermante de la première fonction : ```t_cal = CALENDAR(DATE(2020, 1, 1), EOMONTH(MAX(t_fact[date_fact]), 0) )```
- nom de variable en *CamelCase* précédé d'un tiret-bas : ```VAR _varDate = MAX(dim_calendrier[jour])```

Pour mettre en forme rapidement le code DAX, je ne peux que conseiller le très utile [DAX Formatter](https://www.daxformatter.com/).

## Optimisation et choix des fonctions

Comme pour beaucoup de choses, il existe de nombreuses méthodes pour arriver au même résultat. Mais certains chemins sont plus courts que d'autres. Voici quelques astuces pour avoir un code performant et maintenable.

- Au-delà de deux appels de la même mesure dans le même contexte, utiliser une variable.
- Au-delà de deux [*IF*](https://learn.microsoft.com/fr-fr/dax/if-function-dax) imbriqués, utiliser la fonction [*SWITCH*](https://learn.microsoft.com/fr-fr/dax/switch-function-dax) : 

```DAX
IF([mesure_test], 0, IF([mesure_test_2] > 1000, -1, [mesure_test_2]))
```
<p style="text-align: center;">🡻 devient 🡻</p>
```DAX
VAR _mesure_test_2 = [mesure_test_2]
RETURN SWITCH(TRUE()
    , NOT(ISBLANK([mesure_test])), 0
    , _mesure_test_2 > 1000, -1
    , _mesure_test_2
)
```

- Certaines fonctions permettent d'éviter l'utilisation de conditions : [*COALESCE*](https://learn.microsoft.com/fr-fr/dax/coalesce-function-dax) pour remplacer une valeur vide, [*MAX*](https://learn.microsoft.com/fr-fr/dax/max-function-dax) et [*MIN*](https://learn.microsoft.com/fr-fr/dax/min-function-dax) pour borner une valeur, [*SELECTEDVALUE*](https://learn.microsoft.com/fr-fr/dax/selectedvalue-function-dax) renvoie la valeur sélectionnée dans un champ uniquement si elle est unique.

```DAX
VAR _mesure_test = [mesure_test]
RETURN IF(ISBLANK(_mesure_test), 0, IF(_mesure_test > 1000, 1000, _mesure_test))
```
<p style="text-align: center;">🡻 devient 🡻</p>
```DAX
MIN(COALESCE([mesure_test], 0), 1000)
```

## *Design pattern* de mesures

### Date et temps

Voici quelques exemples de mesures pour des cas d'usage génériques : 

#### Convertir une durée en secondes vers le type *time*

La mesure renvoie une valeur de type *DateTime* correspondant au nombre de secondes donné par la mesure source. Elle doit être mise au format *hh:MM:ss* dans le paramétrage de la mesure pour renvoyer une information cohérente.
Si la durée dépasse 24 heures (86 400 secondes), la mesure renvoie le modulo à la journée.

La fonction [*TIME*](https://learn.microsoft.com/fr-fr/dax/time-function-dax) reçoit en paramètres des valeurs numériques de type *short* : de -32 768 à 32 767. Les valeurs utilisées ne doivent donc pas dépasser 32 767 (sachant que 32 767 secondes ça fait 9 heures 6 minutes et 7 secondes).

Si la valeur est inférieure à 32 768 : 

```DAX
ValTime = TIME(0, 0, [ValSelected])
```

Si la valeur est supérieure ou égale à 32 768 : 

```DAX
ValTime = VAR _v = [ValSelected]
VAR _h = FLOOR(DIVIDE(_v, 3600), 1)
VAR _m = FLOOR(DIVIDE(MOD(_v, 3600), 60), 1)
VAR _s = MOD(_v, 60)
RETURN TIME(_h, _m, _s)
```

#### Formatter une durée en secondes vers du texte

On utilise la fonction [*FORMAT*](https://learn.microsoft.com/fr-fr/dax/format-function-dax) qui permet de faire une conversion vers du texte. 
Attention, une valeur sous forme de texte ne peut plus être utilisée dans un visuel *graphique* (histogramme, courbe, camembert, etc.).

```DAX
TextTime = FORMAT([ValTime], "HH:mm:ss"))
```

Si la valeur est encore en secondes (valeur numérique) :

```DAX
TextTime = VAR _v = [ValSelected]
VAR _h = FLOOR(DIVIDE(_v, 3600), 1)
VAR _m = FLOOR(DIVIDE(MOD(_v, 3600), 60), 1)
VAR _s = MOD(_v, 60)
RETURN FORMAT(_h, "00") & ":" & FORMAT(_m, "00") & ":" & FORMAT(_s, "00")
```

## Comptage

### Compter le nombre d'utilisateurs sur une période 

```DAX
user_nb = DISTINCTCOUNT(t_fact_app_usage[user_principal_name])
```

### Compter le nombre de nouveaux utilisateurs

Le nombre d'utilisateurs enregistrés pour la première fois sur la période observée.

```DAX
user_new_nb = VAR _current = DISTINCT(t_fact_app_usage[user_principal_name])
VAR _previous = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] < MIN(t_dim_calendrier[dt_date]))
    )
RETURN COUNTROWS(EXCEPT(_current, _previous))
```

### Compter le nombre d'utilisateurs réguliers

Le nombre d'utilisateurs enregistrés sur la période observée et qui ont au moins un autre enregistrement avant le début de la période observée.

```DAX
user_old_nb = VAR _current = DISTINCT(t_fact_app_usage[user_principal_name])
VAR _previous = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] < MIN(t_dim_calendrier[dt_date]))
    )
RETURN COUNTROWS(INTERSECT(_current, _previous))
```

### Compter le nombre d'utilisateurs perdus

Le nombre d'utilisateurs ayant au moins un enregistrement avant le début de la période observée et qui n'ont plus aucun enregistrement à partir du début de la période observée.

```DAX
user_lost_nb = VAR _current = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] >= MIN(t_dim_calendrier[dt_date]))
    )
VAR _previous = CALCULATETABLE(DISTINCT(t_fact_app_usage[user_principal_name])
        , FILTER(ALL(t_dim_calendrier), t_dim_calendrier[dt_date] < MIN(t_dim_calendrier[dt_date]))
    )
RETURN COUNTROWS(EXCEPT(_previous, _current))
```

## Couleurs

### Générer un code couleur complètement aléatoire

On utilise une mesure (qu'on appellera *hexa_alea*) qui renvoie une valeur hexadécimale aléatoire entre *0* et *F* (15).

```DAX
MEASURE 'Measures'[hexa_alea] = VAR _an = RANDBETWEEN(0, 15)
RETURN IF(_an < 10, FORMAT(_an, "0"), UNICHAR(UNICODE("A") + _an - 10))
```

La mesure *hexa_alea* doit être appelée dans un [*CALCULATE*](https://learn.microsoft.com/fr-fr/dax/calculate-function-dax) avec une table et être enregistrée dans une variable pour forcer plusieurs évaluations successives et ainsi obtenir des valeurs diférentes.

```DAX
MEASURE 'Measures'[color_alea] = VAR _a = [hexa_alea]
VAR _b = CALCULATE([hexa_alea], GENERATESERIES(0, 0, 1))
VAR _c = CALCULATE([hexa_alea], GENERATESERIES(0, 0, 1)) 
VAR _d = CALCULATE([hexa_alea], GENERATESERIES(0, 0, 1)) 
VAR _e = CALCULATE([hexa_alea], GENERATESERIES(0, 0, 1)) 
VAR _f = CALCULATE([hexa_alea], GENERATESERIES(0, 0, 1)) 
RETURN "#" & _a &_b & _c & _d & _e & _f
```

Il aurait été plus élégant d'utiliser un [*GENERATESERIES*](https://learn.microsoft.com/fr-fr/dax/generateseries-function-dax) pour éviter la succession de variables. Mais dans ce cas, le contexte d'exécution est unique et [*RANDBETWEEN*](https://learn.microsoft.com/fr-fr/dax/randbetween-function-dax) renvoie toujours du gris : 

```DAX
MEASURE 'Measures'[color_alea_ko] = "#" 
& CONCATENATEX(
    ADDCOLUMNS(GENERATESERIES(0, 5)
    , "h", CALCULATE([hexa_alea], GENERATESERIES(0, 0, 1)) 
) , [h])
```
Le résultat sera toujours de la forme *#DDDDDD*, *#555555*, etc.

### Générer un code couleur avec une luminosité constante

Cette mesure renvoie le code hexadécimal d'une couleur au hasard. La couleur a une luminosité constante de 51 % et une dominante rouge, verte ou bleue pour être toujours visible.

```DAX
MEASURE 'Measures'[color51_alea] = 
VAR _pos = MOD(SECOND(UTCNOW()),6) + 1 -- RANDBETWEEN(1, 3)
VAR _ab = RANDBETWEEN(3, 255)
VAR _an = MOD(_ab, 16)
VAR _at = IF(_an < 10, FORMAT(_an, "0"), UNICHAR(UNICODE("A") + _an - 10))
VAR _bn = FLOOR(DIVIDE(_ab, 16), 1)
VAR _bt = IF(_bn < 10, FORMAT(_bn, "0"), UNICHAR(UNICODE("A") + _bn - 10))
RETURN "#" 
	& SWITCH(_pos, 1, "FF03", 2, "03FF", 3, "FF", 4, "03") 
	& _at & _bt 
	& SWITCH(_pos, 3, "03", 4, "FF", 5, "FF03", 6, "03FF")
```

## Images sérialisées

### Afficher une image enregistrée en *Base 64*

Le format *Base64* permet de sérialiser une image pour la stocker directement dans un champ texte. Power BI est capable d'interpréter ce format.

1. Choisir une image simple. L'image doit être suffisamment simple pour que l'enregistrement sérialisé ne dépasse pas la limite de 32766 caractères de Power BI : icône, logo monochrome, illustration simple.
2. Convertir l'image en *Base64*, plusieurs sites internet permettent de le faire, par exemple [base64-image.de](https://www.base64-image.de/). Le code généré doit commencer par ```data:image/png;base64,```
3. Intégrer la chaîne de caractères dans une mesure Power BI.
4. Modifier la 'Catégorie de données' de la mesure : *URL de l'image*.

![image](/Images/20260522-dax-design-pattern/tel_base64.png)

5. L'image peut être affichée dans un visuel image, un tableau, une carte ou tout autre visuel qui supporte les images.

![image](/Images/20260522-dax-design-pattern/tel_base64_visual.png)

### Afficher une image enregistrée en *SVG*

Le *Scalable Vector Graphics* (en français "graphique vectoriel adaptable"), ou *SVG*, est un format de données ASCII conçu pour décrire des ensembles de graphiques vectoriels 2D et fondé sur *XML*. [*cf.*](https://fr.wikipedia.org/wiki/Scalable_Vector_Graphics)

Ce format a l'avantage d'être facilement manipulable et paramétrable. Il est donc très utile pour créer des visuels personnalisés. SQLBI l'explique très bien dans [cet article](https://www.sqlbi.com/articles/creating-custom-visuals-in-power-bi-with-dax/).

1. Choisir ou créer une image SVG. J'utilise régulièrement le site [svgrepo](https://www.svgrepo.com/) pour trouver des images.
2. Dans le fichier SVG, ne conserver que le code entre les balises ```<svg>``` et ```</svg>```, et répéter toutes les doubles quotes pour qu'elles ne soient pas interprétées dans une mesure (**ctrl+H** est ton ami ...).
3. Ajouter en début de code (avant la balise ```<svg>```) le code suivant : ```data:image/svg+xml;utf8,```
4. Intégrer la chaîne de caractères dans une mesure Power BI.
5. Modifier la 'Catégorie de données' de la mesure : *URL de l'image*.
6. L'image peut être affichée dans un visuel image, un tableau, une carte ou tout autre visuel qui supporte les images.

![image](/Images/20260522-dax-design-pattern/raine_svg.png)