# Test d'intégration d'un rapport en iframe

<p style="text-align: right;">2022-11-08</p>

Le rapport est : "Fiche de compte"

<iframe title="Fiche de Compte" width="1140" height="541.25" src="https://app.powerbi.com/reportEmbed?reportId=fb72f89c-c0b5-4e92-a22f-f93d6d4a2c31&autoAuth=true&ctid=ddfab5ca-1b5b-40d1-9e74-636abded58fd" frameborder="0" allowFullScreen="true"></iframe>


<button onClick="window.location.reload();">Refresh Page</button>


<script language="JavaScript" type="text/javascript">
//<![CDATA[
window.onbeforeunload = function(){
return 'Are you sure you want to leave?';
};
//]]>
</script>