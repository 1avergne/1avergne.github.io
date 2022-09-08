Power BI permet d’afficher dans un Dashboard des vidéos hébergé sur Vimeo ou YouTube, mais il est aussi possible de diffuser des vidéo MP4 / WEBM / OGV directement accessible sur internet.

Pour cela il faut utiliser le type de vignette _Web content_ pour embarquer la vidéo dans le Dashboard.

![image](uploads/f96448a53690e270ed3e92ac9d22103b/image.png)

Par exemple, en allant sur le site internet d’une grande entreprise de publicité, on peut voir en arrière-plan une vidéo qui tourne en boucle, si je devais faire un Dashboard pour cette entreprise il serait intéressant d’afficher cette vidéo.

Une rapide inspection du code de la page permet d’obtenir l’adresse source de la vidéo :

![image](uploads/e47474039f7d5299a4ab6284f822fb06/image.png)

En créant une nouvelle vignette de _type Web Content_ et en mettant le morceau de code `<video … >…</video>`, j’affiche directement la vidéo telle qu’elle est sur le site original.

C’est-à-dire en très très gros … Une petite mise en page s’impose !

Dans l’exemple suivant :

- Je n’utilise plus qu’une seule source pour la vidéo : un fichier MP4.
- La vidéo est redimensionnée pour avoir les proportions d’une vignette 3x2.
- Le son est coupé (instruction « muted »).
- La vidéo démarre automatiquement et tourne en boucle (instructions « autoplay » et « loop »).
- Les contrôles (boutons lecture, pause, …) ne sont pas affichés (pas d’instruction « controls »).
- Je rajoute un fond noir pour les zones qui ne sont pas couverte par la vidéo avec l’instruction « style ».

```
<video width="770" height="350" muted autoplay loop
src="https://www.sample-videos.com/video123/mp4/480/big_buck_bunny_480p_1mb.mp4" type="video/mp4"
style="width: 770px; height: 350px; background-color:black;">
</video>
```

![image](uploads/0e1f5a4a6ecbc859340e9d2bab211b77/image.png)