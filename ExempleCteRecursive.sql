drop table if exists #t;
create table #t (obj_id int, parent_id int)
insert into #t 
values (100, null)
,(200, null)
,(300, null)
,(110, 100)
,(120, 100)
,(210, 200)
,(220, 200)
,(230, 200)
,(240, 200)
,(310, 300)
,(111, 110)
,(112, 110)
,(211, 210)
,(212, 210)
,(213, 210)
,(231, 230)
,(241, 240)
,(242, 240)
;

with cte as (
	select t.obj_id
		, t.parent_id
		, convert(varchar(255), t.obj_id) as [path]
		, 0 as [level]
	from #t t
	where parent_id is null
union all 
	select t.obj_id
		, t.parent_id
		, convert(varchar(255), concat(c.[path], '->', convert(varchar(255), t.obj_id))) as [path]
		, c.[level] + 1 as [level]
	from #t t
	inner join cte c on c.obj_id = t.parent_id
)

select * from cte