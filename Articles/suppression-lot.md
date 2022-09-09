## Suppression par lots

Pour éviter de saturer les logs d'une base, ou d'avoir une requête trop longue, il est conseillé de faire les opérations de DELETE par lots, c'est-à-dire de supprimer un nombre limité de lignes successivement dans différentes transactions.

Pour cela on utilise l'instruction TOP dans un DELETE répété dans un boucle :

```sql
declare @rc int = 200000
 
while @rc >= 200000 
begin
    begin tran
        delete TOP(200000) from sal
        from [dwh].[fact_sales] sal
        inner join [ods].[fact_sales] on ods.business_unit = sal.business_unit 
            and ods.business_month = sal.business_month
             
        select @rc = @@ROWCOUNT
    commit tran
end
```