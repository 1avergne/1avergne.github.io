# Créer une table 'Calendrier'

<p style="text-align: right;">2020-06-11</p>

**Je n'ai rien inventé, tout est [là](https://www.mssqltips.com/sqlservertip/4054/creating-a-date-dimension-or-calendar-table-in-sql-server/) !**

On a toujours besoin d'une table de type calendrier avec la liste des jours et éventuellement les mois, semaines, dernier jours de mois, jour ouvrés, etc.

Pour cela on crée la table avec une colonne _date_ qui va contenir la date du jour, et les autres colonnes. Toutes les autres colonnes sont définies par une formule basée sur _date_. Cela permet de générer les valeurs pour toutes les colonnes en alimentant uniquement la colonne _date_.

```sql
CREATE TABLE [dwh].[dim_calendar](
    [date] [date] NOT NULL,
    [day]  AS (datepart(day,[date])),
    [month_num]  AS (datepart(month,[date])),
    [month]  AS (datename(month,[date])),
    [year_month_num]  AS (CONVERT([int],format([date],'yyyyMM'))),
    [year_month]  AS (format([date],'MMMM yyyy')),
    [week]  AS (datepart(week,[date])),
    [iso_week]  AS (datepart(iso_week,[date])),
    [day_of_week]  AS (datepart(weekday,[date])),
    [quarter]  AS (datepart(quarter,[date])),
    [year]  AS (datepart(year,[date])),
PRIMARY KEY CLUSTERED 
(
    [date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
```

Pour l'alimentation, on va utiliser une requête qui génère la liste des jours entre le 1er et le dernier jour dans la table de faits. On se base sur une liste numérotée en faisant un _ROW_NUMBER()_ sur une table assez volumineuse (il faut au moins autant de lignes qu'il y a de jours): la table système _all_objects_ croisée avec elle-même fera l'affaire. Dans la requête ci-dessous je génère des années complètes. L'initialisation des variables (dans le _DECLARE_) n'est pas nécessaire puisque je fais une attribution dans le _SELECT_. Le _SELECT_ peut être omis si l'on souhaite définir les dates en dur.

```sql
DECLARE @StartDate DATE = '20170101'
    ,@NumberOfYears INT = 5;
DECLARE @CutoffDate DATE = DATEADD(YEAR, @NumberOfYears, @StartDate);
 
SELECT @StartDate = isnull(DATEFROMPARTS(YEAR([start_date]), 1, 1), @StartDate)
    ,@CutoffDate = isnull(DATEFROMPARTS(YEAR([end_date]) + 1, 1, 1), @CutoffDate)
FROM (
    SELECT min([fact_date]) AS [start_date]
        ,max([fact_date]) AS [end_date]
    FROM [dwh].[fact_sales]
    ) t
 
PRINT 'generate calendar from ' + format(@StartDate, 'yyyy-MM-dd') + ' to ' + format(@CutoffDate, 'yyyy-MM-dd')
 
-- prevent set or regional settings from interfering with 
-- interpretation of dates / literals
-- https://www.mssqltips.com/sqlservertip/4054/creating-a-date-dimension-or-calendar-table-in-sql-server/
SET DATEFIRST 7;
SET DATEFORMAT ydm;
 
INSERT dwh.dwh_dim_calendar ([date])
SELECT d
FROM (
    SELECT d = DATEADD(DAY, rn - 1, @StartDate)
    FROM (
        SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) rn = ROW_NUMBER() OVER (
                ORDER BY s1.[object_id]
                )
        FROM sys.all_objects AS s1
        CROSS JOIN sys.all_objects AS s2
        ORDER BY s1.[object_id]
        ) AS x
    ) AS y;
```