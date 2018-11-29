use cadnceprd;

if exists (select 1 from sys.identity_columns c join sys.tables t on t.object_id = c.object_id where is_not_for_replication = 0)
begin
SELECT  QUOTENAME(SCHEMA_NAME(t.schema_id)) as SchemaName,  
        QUOTENAME(t.name) AS TableName, 
        c.name AS ColumnName,
        c.object_id as ObjectID,
        c.is_not_for_replication,
        'EXEC sys.sp_identitycolumnforreplication '+cast(c.object_id as varchar(20)) + ', 1 ;' as CommandTORun_SetIdendityNOTForReplication
    FROM    sys.identity_columns AS c 
        INNER JOIN  sys.tables AS t ON t.[object_id] = c.[object_id]
        WHERE   c.is_identity = 1
        and c.is_not_for_replication = 0
end
else 
print 'There are no identity columns that needs NOT FOR REPLICATION set to 1'