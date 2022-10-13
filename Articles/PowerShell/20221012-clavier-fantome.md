# Avoir un _clavier fantôme_ qui appuie sur une touche toutes les 5 secondes

Marre d'être déconnecté d'une VM ?

Envie de profiter de votre télétravail tout en apparaissant comme _actif_ sur Teams ?

Pas motiver pour retaper votre mot de passe apès la pause café ?

## Ce script est fait pour vous !

Il va tout simplement _appuyer_ sur la touche _z_ toutes les 5 secondes, et donc eviter que votre poste se met en veille

```powershell
[int]$delay = 5
[string]$char = "z";

Write-Output "$char typed each $delay sec";

while($delay -gt 0)
{
    Start-Sleep -Seconds $delay;
    Write-Output "$char typed !";
    [System.Windows.Forms.SendKeys]::SendWait($char);
}
```

Et pour plus de fun, n'hésitez pas à remplacer _z_ par votre émoji préféré 😴

![image](/Images/powershell-typez.png)