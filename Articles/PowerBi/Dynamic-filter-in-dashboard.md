# Dynamic filter in dashboard

With the _Web-content_ tile, it's possible to add a custom menu Inside a Power BI dashboard !

To do this, I use a javascript code that change the target url of a link according to the selected value in a dropdown menu.

![image](/Images/dynamic-filter-demo.gif)

Generated url embed the value as a parameter. The syntax is : ```URL?filter=Table/Field eq 'value'```

All documentation about this functionality is [here](https://docs.microsoft.com/en-us/power-bi/service-url-filters).

![image](/Images/dynamic-filter-screen.png)

Here is my code:

```html
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