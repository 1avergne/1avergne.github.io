# Le fichier Layout

Si vous dezippez un fichier _.pbix_ (_-Mais on peut faire ça ?! -Oui ..._) vous trouverez un certains nombre d'élements l'interieur : les images et ressources du rapports, les visuels personalisés, les données, la version, etc.

```
C:.
│   DataModel
│   DiagramLayout
│   Metadata
│   SecurityBindings
│   Settings
│   Version
│   [Content_Types].xml
│
└───Report
    │   Layout
    │
    └───StaticResources
        └───SharedResources
            └───BaseThemes
                    CY22SU09.json
```

C'est le fichier **Layout** qui nous interesse. Il contient la définition complète du rapport au format _JSON_.
Le fichier est encodé en _Unicode_ (codepage : 1200). 


**Attention :** Modififier manuellement le fichier pour ensuite recréer un fichier _.pbix_ risque de produire un fichier corrompu. Je vous conseille d'essayer la méthode décrite [ici](https://community.powerbi.com/t5/Desktop/Modifying-the-Layout-file-that-is-embedded-in-a-pbix-file/m-p/1616614/highlight/true#M652387) pour avoir un fichier utilisable.