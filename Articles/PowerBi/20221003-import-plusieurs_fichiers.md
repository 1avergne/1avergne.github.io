# Importer plusieurs fichiers en parallèle avec Power Query

J'ai eu envie de faire un rapport sur la météo et ça tombe bien, [Météo France](https://donneespubliques.meteofrance.fr/) donne accès à l'historique d'une cinquantaine de stations sur 15 ans. On peut télécharger les données [ici](https://donneespubliques.meteofrance.fr/?fond=produit&id_produit=90&id_rubrique=32) pour une date ou pour un mois précis. 

![image](/Images/20221003-import-plusieurs_fichiers/rapportMeteo.png)]

Je rencontre deux problématiques :
- récupérer les fichiers pour plusieurs mois sans avoir à faire une requête par mois.
- décompresser les fichiers qui sont fournis en _.gz_.

En téléchargeant un premier fichier j'identifie le format du nom du fichier : l'année et le mois sont indiqués dans l'adresse.

_donneespubliques.meteofrance.fr/donnees_libres/Txt/Synop/Archive/synop.**202210**.csv.gz_

![image](/Images/20221003-import-plusieurs_fichiers/lienTelechargement.png)

Il suffit de changer l'année et le mois pour accéder aux données d'une autre période.
Avec un langage procédural ce serai facile de récupérer tout l'historique dans une boucle :

```powershell
$i = 0
while($i -lt 12){
    $m = ((Get-Date).AddMonths(-1 * $i)) | Get-Date -Format "yyyyMM"
    $uri = "https://donneespubliques.meteofrance.fr/donnees_libres/Txt/Synop/Archive/synop." + $m + ".csv.gz"
    Invoke-RestMethod $uri -Method 'GET' -OutFile $("synop." + $m + ".csv.gz") 
    $i = $i + 1
}
```

Mais dans Power Query, il n'y a pas de boucle. Il faut donc procéder en 3 étapes :
- Etablir la liste des fichiers à télécharger
- Ecrire une fonction capable de traiter un fichier
- Appeler la fonction sur chaque fichier de la liste

## La liste des fichiers

Disons que l'on veuille récupérer 3 ans d'historiques, soit 36 mois :

- On génère une liste de 1 à 36. La liste doit être convertie en table et on peut renommer la colonne.

```
= List.Generate(() > 0, each _ <= 36, each _ + 1)
```

- Pour chaque valeur on détermine un numéro de mois en texte au format _YYYYMM_ (en repartant de la date du jour). 

```
= Table.AddColumn(#"Colonnes renommées", "Code Mois", each DateTime.ToText(Date.AddMonths(Date.EndOfMonth(DateTime.LocalNow()), 0 - [Offset]), "yyyyMM"))
```

- On crée le chemin du fichier après l'adresse du site (c'est à dire après le _.fr/_) en utilisant le numéro de mois.

![image](/Images/20221003-import-plusieurs_fichiers/cheminFichierAjoute.png)

- Enfin on ajoute une colonne qui télécharge le fichier avec l'instruction [```Web.Contents```](https://learn.microsoft.com/fr-fr/powerquery-m/web-contents). Il est **indispensable d'utiliser l'instruction en précisant le nom du site comme premier paramètre et le chemin du fichier comme option** ```RelativePath```. Si on ne fait pas ça (et si on met une url complète comme unique paramètre), la requête est **considérée comme dynamique et [ne peut pas être actualisée](https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-data#refresh-and-dynamic-data-sources)** par le service _powerbi.com_.

```
= Table.AddColumn(#"Chemin Fichier ajouté", "Fichier", each Web.Contents("https://donneespubliques.meteofrance.fr", [RelativePath = [Chemin Fichier]]))
```

![image](/Images/20221003-import-plusieurs_fichiers/fichierAjoute.png)

## Traiter le fichier

Les fichiers récupérés sont des _CSV_ compressés en _ZIP_. 
Il faut les décompresser pour ensuite les traiter. Pour cela on utilise l'instruction [```Binary.Decompress```](https://learn.microsoft.com/fr-fr/powerquery-m/binary-decompress) (je pense que le nom est assez explicite).
Une fois le fichier lisible, on le traite comme un _CSV_ et on remonte la première ligne en en-tête.

Tout ce processus doit être encapsulé dans une fonction pour pouvoir être appelé pour chaque ligne de notre première requête :

```
(ZIPFile) =>
let
    Source = Binary.Decompress(ZIPFile, Compression.GZip),
    Read = Csv.Document(Source, [Delimiter=";", Encoding=1252, QuoteStyle=QuoteStyle.None]),
    Header = Table.PromoteHeaders(Read, [PromoteAllScalars=true])
in
    Header
```

On appelle la fonction _Unzip_ histoire de rester original.

![image](/Images/20221003-import-plusieurs_fichiers/fonctionUnzip.png)

## Appeler la fonction pour chaque fichier

On a la liste des fichiers (téléchargés en binaire) et une fonction pour les lire, il ne reste plus qu'à utiliser tout ça.

Dans la première requête, on crée une nouvelle colonne en appelant une fonction personnalisée : la fonction _Unzip_ crée précédemment ! La fonction prend en paramètre la colonne des fichiers en binaire.

![image](/Images/20221003-import-plusieurs_fichiers/appelerFonctionPersonalisee.png)

On peut à présent développer la nouvelle colonne pour récupérer le contenu de chaque fichier dans la même table.

![image](/Images/20221003-import-plusieurs_fichiers/developperColonneUnzip.png)

Le script complet de la requête Power Query est :
```
let
    Source = List.Generate(() > 0, each _ <= 36, each _ + 1),
    #"Converti en table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Colonnes renommées" = Table.RenameColumns(#"Converti en table",{{"Column1", "Offset"}}),
    #"Code Mois ajouté" = Table.AddColumn(#"Colonnes renommées", "Code Mois", each DateTime.ToText(Date.AddMonths(Date.EndOfMonth(DateTime.LocalNow()), 0 - [Offset]), "yyyyMM")),
    #"Chemin Fichier ajouté" = Table.AddColumn(#"Code Mois ajouté", "Chemin Fichier", each "donnees_libres/Txt/Synop/Archive/synop." & [Code Mois] &".csv.gz"),
    #"Fichier ajouté" = Table.AddColumn(#"Chemin Fichier ajouté", "Fichier", each Web.Contents("https://donneespubliques.meteofrance.fr", [RelativePath = [Chemin Fichier]])),
    #"Fonction personnalisée appelée" = Table.AddColumn(#"Fichier ajouté", "Unzip", each Unzip([Fichier])),
    #"Autres colonnes supprimées" = Table.SelectColumns(#"Fonction personnalisée appelée",{"Unzip"}),
    #"Unzip développé" = Table.ExpandTableColumn(#"Autres colonnes supprimées", "Unzip", {"numer_sta", "date", "pmer", "tend", "cod_tend", "dd", "ff", "t", "td", "u", "vv", "ww", "w1", "w2", "n", "nbas", "hbas", "cl", "cm", "ch", "pres", "niv_bar", "geop", "tend24", "tn12", "tn24", "tx12", "tx24", "tminsol", "sw", "tw", "raf10", "rafper", "per", "etat_sol", "ht_neige", "ssfrai", "perssfrai", "rr1", "rr3", "rr6", "rr12", "rr24", "phenspe1", "phenspe2", "phenspe3", "phenspe4", "nnuage1", "ctype1", "hnuage1", "nnuage2", "ctype2", "hnuage2", "nnuage3", "ctype3", "hnuage3", "nnuage4", "ctype4", "hnuage4", ""}, {"numer_sta", "date", "pmer", "tend", "cod_tend", "dd", "ff", "t", "td", "u", "vv", "ww", "w1", "w2", "n", "nbas", "hbas", "cl", "cm", "ch", "pres", "niv_bar", "geop", "tend24", "tn12", "tn24", "tx12", "tx24", "tminsol", "sw", "tw", "raf10", "rafper", "per", "etat_sol", "ht_neige", "ssfrai", "perssfrai", "rr1", "rr3", "rr6", "rr12", "rr24", "phenspe1", "phenspe2", "phenspe3", "phenspe4", "nnuage1", "ctype1", "hnuage1", "nnuage2", "ctype2", "hnuage2", "nnuage3", "ctype3", "hnuage3", "nnuage4", "ctype4", "hnuage4", "Colonne1"})
in
    #"Unzip développé"
```

## La même en mieux

Si on souhaite améliorer la requête et se conformer aux bonnes pratiques :
- Séparer les étapes en plusieurs requêtes et ne garder que la dernière requête d'active.
- Utiliser des paramètres pour le nombre de mois d'historique, l'adresse du site web, et le chemin relatif.
- Utiliser une balise dans le chemin relatif pour le numéro du mois qui sera remplacé dynamiquement lors du chargement :

```
= Table.AddColumn(#"Personnalisée ajoutée", "Fichier", each Web.Contents(#"Base Uri", [RelativePath = Text.Replace(#"Complement Uri", "<mois>", [Code Mois])]))
```

![image](/Images/20221003-import-plusieurs_fichiers/dependancesRequetes.png)