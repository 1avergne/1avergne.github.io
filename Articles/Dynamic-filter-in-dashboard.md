With the 'Web-content' tile, it's possible to add a custom menu Inside a Power BI dashboard !

To do this, I use a javascript code that change the target url of a link according to the selected value in a dropdown menu.

![image](uploads/15ab243d250a5e73be6d66824bbfc7e7/image.png)

Generated url embed the value as a parameter. The syntax is : URL?filter=Table/Field eq 'value'

All documentation about this functionality is here : https://docs.microsoft.com/en-us/power-bi/service-url-filters

![image](uploads/3e0104b9fed27c698071cc278e697b99/image.png)

Here is my code:

```
<script> 
function func(o){
    var reportUrl = "https://app.powerbi.com/groups/myP0werB1R3p0rtUrl";
    document.getElementById('reportHref').href=reportUrl + "?filter=Table/Field eq '" + o.value + "'";
}
</script>
</br>
</br>HUMAN PART : <select id="hpart" onchange="func(this)">
<option id="ong">ongle</option>
<option id="doi">doigt</option>
<option id="main">main</option>
<option id="pie">pied</option>
<option id="tet">tete</option>
<option id="autre">autre</option>
</select>
</br>
</br>
<a id="reportHref" target="_blank" href="#">GO</a>
```