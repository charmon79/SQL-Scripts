

select *
from sys.tables t
where not exists (
    select 1
    from sys.indexes i
    where i.object_id = t.object_id
    and i.is_primary_key = 1 
)
and is_ms_shipped = 0


