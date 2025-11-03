# J’ai redéveloppé FIGlet dans Power BI !

<p style="text-align: right;">2025-11-03</p>

## Un peu d’histoire pour les plus jeunes.

**FIGlet** est un logiciel en ligne de commande développé par Glenn Chappell et Ian Chai au début des années 90. C’est un logiciel libre intégré dans de nombreuses distributions GNU/Linux et qui a également été implémenté dans divers langages ou solutions.

Concrètement FIGlet permet de générer des bannières de texte en *ASCII Art*. C’est-à-dire d’écrire du texte en très gros à partir de caractères normaux.
Avec FIGlet ``1avergne.github.io`` devient :
```
  ___                                                      _   __    __          __       _      
 <  / ___ _ _  __ ___   ____  ___ _  ___  ___      ___ _  (_) / /_  / /  __ __  / /      (_) ___ 
 / / / _  /| |/ // -_) / __/ / _  / / _ \/ -_) _  / _  / / / / __/ / _ \/ // / / _ \ _  / / / _ \
/_/  \_,_/ |___/ \__/ /_/    \_, / /_//_/\__/ (_) \_, / /_/  \__/ /_//_/\_,_/ /_.__/(_)/_/  \___/
                            /___/                /___/                                                               
```

Ou encore ``Power-BI #1 :)`` devient :
```
  _ \                                        _ )  _ _|       |  |    _ |     _)  \ \  
  __/    _ \  \ \  \ /    -_)    _|  ____|   _ \    |      _ |_ |_|    |            | 
 _|    \___/   \_/\_/   \___|  _|           ___/  ___|     _ |_ |_|   _|     _)     | 
                                                            _| _|                 _/  
```
C’est un logiciel que j’affectionne particulièrement car il permet de rendre facilement visible des titres dans une documentation ou es commentaires d’un code.

## Etape 1 : les polices

Même s’il est assez simple de créer sa propre police FIGlet, il existe déjà plusieurs polices *historiques* et je trouvais intéressant de pouvoir les réutiliser.

Chaque police est enregistrée au même format dans un fichier *.flf* :

![image](/Images/20251103-powerbi-figlet/powerbi-figlet-alphabet.png)

-	Une ligne d’en-tête avec quelques métadonnées : la hauteur des caractères, le nombre de lignes de commentaire, etc.
-	Un bloc de commentaire
-	Les caractères à la suite en commençant par l’espace (le 32e caractère dans le code ASCII) : 
    -	Chaque ligne se termine par ``@``
    -   La dernière ligne (la plus basse) se termine par ``@@``
-	Les caractères sont enregistrés dans l’ordre de l’alphabet ASCII
-	Pour les caractères hors de l’alphabet ASCII, une ligne d’entête indique le code Unicode et le nom du caractère

![image](/Images/20251103-powerbi-figlet/powerbi-figlet-alphabet-215.png)

Dans Power Query, j’ai créé une fonction qui va récupérer le fichier de police sur Git et le transforme en table avec comme colonnes :
-	Code : le code d’une ligne de caractère comme il définit dans FIGlet, mais sans le @ en fin de ligne, et avec des guillemets `à la place des espaces
-	Index : la numérotation des lignes du fichier. Je n’utiliserai pas cette colonne ensuite.
-	Line : le numéro de la ligne pour chaque ligne de code d’un caractère en commençant à 0 pour la ligne la plus basse (qui finissait par @@).
-	Letter Index : la numérotation des caractères dans le fichier. Je n’utiliserai pas cette colonne ensuite.
-	Letter Code : le code ASCII ou Unicode du caractère.

![image](/Images/20251103-powerbi-figlet/powerbi-figlet-get-font.png)

A partir d'une liste de polices à récuperer dans un répo GIT, j’appelle la fonction pour obtenir une table avec la définition de toutes mes polices.

![image](/Images/20251103-powerbi-figlet/powerbi-figlet-get-font-path.png)

Cette table est chargée dans le modèle, elle servira de base à mon FIGlet *Power BI*.

![image](/Images/20251103-powerbi-figlet/powerbi-figlet-fonts-table.png)

## Etape 2 : Le DAX
Il s’agit maintenant d’écrire le code qui va permettre de passer de *ça* à ...
         
```
  __    __,  
 /     /  |  
 \___/ \_/|_/
  _)         
```
             
Même si on serait tenté d’aborder le problème de manière itérative (je converti une lettre en code, et je passe à la suivante, ainsi de suite jusqu’à la fin du texte) on fait ici du DAX dans Power BI ! Il faut donc voir les choses sous forme de tables qui vont être transformées globalement.

Je crée une mesure DAX, avec une variable texte qui contient ``GE3K`` c'est le texte à convertir.

- Générer une table avec un caractère par ligne. Y ajouter le code de chaque caractère

Letter Order | Letter Code
--- | ---
1 | 71 *G*
2 | 69 *E*
3 | 51 *3*
4 | 75 *K*

- Puis répéter chaque caractère par le nombre de ligne dans l’encodage FIGlet.

Letter Order | Letter Code | Line
--- | --- | ---
1 | 71 *G* | 2
1 | 71 *G* | 1
1 | 71 *G* | 0
2 | 69 *E* | 2
2 | 69 *E* | 1
2 | 69 *E* | 0
3 | 51 *3* | 2
3 | 51 *3* | 1
3 | 51 *3* | 0
4 | 75 *K* | 2
4 | 75 *K* | 1
4 | 75 *K* | 0

Il suffit à présent de faire la jointure avec l’alphabet FIGlet souhaité (c’est-à dire la table chargée de Power Query filtré sur un alphabet).

Letter Order | Letter Code | Line | Code
--- | --- | --- | ---
1 | 71 *G* | 2 | \`__
1 | 71 *G* | 1 | /__
1 | 71 *G* | 0 | \\_\| 
2 | 69 *E* | 2 | \`_ 
2 | 69 *E* | 1 | \|_ 
2 | 69 *E* | 0 | \|_ 
3 | 51 *3* | 2 | _\`
3 | 51 *3* | 1 | _)
3 | 51 *3* | 0 | _)
4 | 75 *K* | 2 | \`\`
4 | 75 *K* | 1 | \|/ 
4 | 75 *K* | 0 | \|\

Enfin on va concaténer chacune des lignes de la plus haute (avec l’index *Line* le plus élevé) à la plus basse (avec Line égal à 0) en les séparant par un retour chariot. Et pour chaque ligne, on va concaténer l’encodage FIGlet des caractères (colonne *Code*) en suivant l’ordre original du texte (colonne *Letter Order*).

Dans la table alphabet, j’avais remplacé les espaces par des guillemets. Je les remplace des espaces insécables. Avec un espace normal, Power BI supprime les espaces répétés ou en début de texte.

Pour que l’affichage soit correct, il faut utiliser une police de caractères à [chasse fixe](https://fr.wikipedia.org/wiki/Police_de_caract%C3%A8res_%C3%A0_chasse_fixe). Par défaut, Power BI propose **Consolas** ou **Courier New**.

![image](/Images/20251103-powerbi-figlet/powerbi-figlet-ge3k.png)

## Etape 3 : la fonction

L’objectif est d’avoir une routine facilement réutilisable, que l’on puisse appeler simplement.
Je vais donc utiliser une fonction définie par l’utilisateur pour appeler mon code.
Dans l éditeur DAX de Power BI Desktop, je définie la fonction « FIGlet » avec deux paramètres :
-	Le texte en entrée à encoder
-	Le nom d’alphabet à utiliser
Ces paramètres remplacent les variables de ma mesure initiale. Je peux à présent utiliser mon FIGlet Power BI dans mon rapport !

![image](/Images/20251103-powerbi-figlet/powerbi-figlet-today.png)

```dax
DEFINE 
FUNCTION Figlet = (InputText: string, Font: string) =>
 VAR _nl = "
"
VAR _heigth = MAXX(FILTER(ALL(Fonts), Fonts[Font] = COALESCE(Font, MAX(Fonts[Font]))), Fonts[Line])
VAR _texteMatrix = --crée une matrice avec le texte ; une colonne par lettre du texte et N lignes
GENERATE(SELECTCOLUMNS(GENERATESERIES(1, LEN(InputText), 1)
    , "Letter Order", INT([Value])
    , "Letter Code", INT(UNICODE(MID(InputText, [Value], 1)))
    )
, SELECTCOLUMNS(GENERATESERIES(0, _heigth, 1)
    , "Line", INT([Value])
    )
)
VAR _letterCode = --récupère l'alphabet à utiliser ; reformate le tableau pour permettre de faire les jointures
SELECTCOLUMNS(FILTER(ALL(Fonts), Fonts[Font] = COALESCE(Font, MAX(Fonts[Font])))
    , "Letter Code", INT(Fonts[Letter Code])
    , "Line", INT(Fonts[Line])
    , "Code", Fonts[Code]
)
VAR _resMatrix = --associe chaque letttre/ligne et l'encodage dans l'alphabet 
NATURALINNERJOIN(_texteMatrix, _letterCode)
RETURN CONCATENATEX(GENERATESERIES(0, _heigth, 1)
    , SUBSTITUTE(CONCATENATEX(FILTER(_resMatrix, [Line] = [Value]), [Code], , [Letter Order], ASC), "`", UNICHAR(160))
    , _nl, [Value], DESC
)
```