# Convertir les caractères ASCII du code hexa au symbole

J'ai plein de chaînes de caractères avec des _$20_. 20 est le code hexadécimal pour l'espace, donc je pourrai faire un simple _REPLACE_. Mais pourquoi faire simple quand on peut faire une fonction ?

![image](/Images/sql-code-hexa.png)

J'ai donc écris une fonction qui convertie dans une chaîne les séquences "$**" (avec ** un nombre hexadécimal entre 00 et 7F) en symbole ASCII :

```sql
CREATE FUNCTION [dbo].[ReplaceHex]
(@str NVARCHAR(255)
)
RETURNS NVARCHAR(255)
AS
BEGIN
    --declare @str NVARCHAR(255) = '/TGBT$2dN/Energie$20act$ive'
 
    declare @res NVARCHAR(255) = ''
    declare @uchar NVARCHAR(3)
 
    --recherche tous les charactères $ qui peuvent preceder un code hexa
    declare @i int = PATINDEX('%[$][0-7][0123456789ABCDEF]%', UPPER(@str))
    while @i > 0
    begin
        select @res += left(@str, @i - 1)
            , @uchar =  UPPER(SUBSTRING(@str, @i , 3))
            , @str = SUBSTRING(@str, @i + 3, LEN(@str))
     
        --select @res += char((16 * convert(int, SUBSTRING(@uchar,2,1))) + isnull(try_convert(int,SUBSTRING(@uchar,3,1)), ascii(SUBSTRING(@uchar,3,1)) - 55))
        select @res += char((16 * convert(int, SUBSTRING(@uchar,2,1))) + case when SUBSTRING(@uchar,3,1) like '[0-9]' then convert(int,SUBSTRING(@uchar,3,1)) else ascii(SUBSTRING(@uchar,3,1)) - 55 end)
            , @i = PATINDEX('%[$][0-7][0123456789ABCDEF]%', @str)
    end
    select @res += @str
 
    RETURN @res
END
```