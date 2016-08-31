USE master;
GO

SELECT  
        'bob'
    ,   'DROP THINGY ' + QUOTENAME(o.name) -- SQL to drop the unwanted thing (fix the code gen per the object type)
    ,   *
FROM    sys.objects AS o
WHERE   o.is_ms_shipped = 0 -- ignores any Microsoft-created objects which aren't flagged as system objects
        AND o.name NOT LIKE 'sp_%' -- to ignore 3rd party utility procs like sp_WhoIsActive, sp_who3, sp_Blitz, etc.
        AND o.name NOT IN (
                                /* ignore Ola Hallengren's Maintenance Solution objects */
                                'DatabaseBackup'
                            ,   'DatabaseIntegrityCheck'
                            ,   'GetDBNames'
                            ,   'IndexOptimize'
                            ,   'CommandExecute'
                            ,   'CommandLog'
                        )
ORDER BY o.name;

