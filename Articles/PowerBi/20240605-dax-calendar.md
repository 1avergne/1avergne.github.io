# Mon calendrier en DAX

<p style="text-align: right;">2024-06-05</p>

A force d'écrire la même formule en DAX pour créer un calendrier. Je me suis dit qu'il etait temps de faire une version à peu près définitive !

![image](/Images/dalle_calendar4.jfif)

Dans ce code je récupère le calendrier à proprement parler (la liste des jours) avec la fonction ```CALENDARAUTO``` . On peut tout aussi bien utiliser ```CALENDAR```

Je calcule le jour de Paques et les jours fériés qui en découlent avec la [méthode de Butcher-Meeus](https://fr.wikipedia.org/wiki/Calcul_de_la_date_de_P%C3%A2ques#M%C3%A9thode_moderne).

Les jours *ouvrés* correspondent aux jourshors week-end et hors jours fériers.

Les colonnes *Week-end* et *Ouvré* sont des entiers plutôt que des booléens. Cela permet de compter plus rapidement le nombre de jour (en faisant une somme sur la colonne).

```dax
Calendrier = VAR _local = "fr-fr"
VAR _cal = CALENDARAUTO()
VAR _ann = DISTINCT(SELECTCOLUMNS(_cal, "Année", YEAR([Date])))
VAR _paq = ADDCOLUMNS(_ann
, "Date", VAR _n = MOD([Année], 19)
    VAR _c = FLOOR(DIVIDE([Année], 100), 1)
    VAR _u = MOD([Année], 100)
    VAR _s = FLOOR(DIVIDE(_c, 4), 1)
    VAR _t = MOD(_c, 4)
    VAR _p = FLOOR(DIVIDE(_c + 8, 25), 1)
    VAR _q = FLOOR(DIVIDE(_c - _p + 1, 3), 1)
    VAR _e = MOD((19 * _n) + _c - _s - _q + 15, 30)
    VAR _b = FLOOR(DIVIDE(_u, 4), 1)
    VAR _d = MOD(_u, 4)
    VAR _L = MOD((2 * _t) + (2 * _b) - _e - _d + 32, 7)
    VAR _h = FLOOR(DIVIDE(_n + (11 * _e) + (22 * _L), 451), 1)
    VAR _m = FLOOR(DIVIDE(_e + _L - (7 * _h) + 114, 31), 1)
    VAR _j = MOD(_e + _L - (7 * _h) + 114, 31) + 1
    RETURN DATE([Année], _m, _j)
)
VAR _fet = UNION(SELECTCOLUMNS(_paq, "Fete", "Paques", "Date", [Date])
    , SELECTCOLUMNS(_paq, "Fete", "Lundi de Paques", "Date", [Date] + 1)
    , SELECTCOLUMNS(_paq, "Fete", "Ascension", "Date", [Date] + 39)
    , SELECTCOLUMNS(_paq, "Fete", "Pentecôte", "Date", [Date] + 49)
    , SELECTCOLUMNS(_paq, "Fete", "Lundi de Pentecôte", "Date", [Date] + 50)
    , SELECTCOLUMNS(_ann, "Fête", "Jour de l'an", "Date", DATE([Année], 1, 1))
    , SELECTCOLUMNS(_ann, "Fête", "Fête du travail", "Date", DATE([Année], 5, 1))
    , SELECTCOLUMNS(_ann, "Fête", "Victoire 1945", "Date", DATE([Année], 5, 8))
    , SELECTCOLUMNS(_ann, "Fête", "Fête nationale", "Date", DATE([Année], 7, 14))
    , SELECTCOLUMNS(_ann, "Fête", "Assomption", "Date", DATE([Année], 8, 15))
    , SELECTCOLUMNS(_ann, "Fête", "Toussaint", "Date", DATE([Année], 11, 1))
    , SELECTCOLUMNS(_ann, "Fête", "Armistice 1918", "Date", DATE([Année], 11, 11))
    , SELECTCOLUMNS(_ann, "Fête", "Noël", "Date", DATE([Année], 12, 25))
)
RETURN ADDCOLUMNS(ADDCOLUMNS(_cal
, "Année", YEAR([Date])
, "Année-mois", EOMONTH([Date], 0) // afficher au format "mmmm yyyy"
, "Mois", FORMAT([Date], "mmmm", _local) // trier par [Mois (num)]
, "Mois (num)", MONTH([Date])
, "Semaine (num)", WEEKNUM([Date], 2)
, "Jour semaine", FORMAT([Date], "dddd", _local) // trier par [Jour semaine (num)]
, "Jour semaine (num)", WEEKDAY([Date], 2)
, "Début semaine", [Date] - WEEKDAY([Date], 2) + 1
, "Week-end", IF(WEEKDAY([Date], 2) > 5, 1, 0)
, "Fête", MINX(FILTER(_fet, [Date] = EARLIER([Date])), [Fete])
), "Ouvré", IF([Week-end] = 0 && ISBLANK([Fête]), 1, 0)
)
```
