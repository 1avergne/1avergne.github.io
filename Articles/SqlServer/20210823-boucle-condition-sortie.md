# T-SQL - Prévoir une _sortie_ dans une boucle

<p style="text-align: right;">2021-08-23</p>

Il y a plein de raisons de faire une boucle en SQL : [suppression par lots](https://1avergne.github.io/Articles/SqlServer/suppression-lot.html), traitement par partition... Mais il arrive que ça prenne un peu de temps et qu'il faille interrompre l'exécution de la boucle. Dans ce cas on n'a pas forcement envie d'annuler tout ce qui a déjà été fait. 

![image](https://i.giphy.com/media/9P8PtNwxCzHtjH5mEU/giphy.webp)

Pour me permettre d'interrompre proprement une boucle et de sortir entre deux itérations sans faire de _break_ sur ma commande, j'ajoute l'instruction suivante dans la condition de ma boucle (_while_ ou curseur) :  ```AND OBJECT_ID('tempdb..##stop') is null```

## Par exemple :

```
DECLARE @m int = 10

WHILE @m >= 0 AND OBJECT_ID('tempdb..##stop') is null
BEGIN
	PRINT '--- ' + convert(NVARCHAR(5), @m) + ' ---'
		
	SELECT @m -= 1
END
```

Pour sortir de la boucle, il suffit alors de créer la table ```##stop``` dans une autre fenêtre :

```
select 1 as i into ##stop
```

Si je dois relancer la boucle, je supprime la table ou je ferme la fenêtre où elle a été créée :

```
drop table ##stop
```