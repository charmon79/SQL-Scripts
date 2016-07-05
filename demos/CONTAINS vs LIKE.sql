USE XDB;

SET STATISTICS IO, TIME ON;

/*
    Prefix (LIKE '%term') & infix (LIKE '%term%') searches using LIKE are very slow.
    This is for two reasons:
    
    1) SQL Server cannot use an index seek to find matching rows, so this will force a table scan,
       or at best a full scan of a nonclustered index containing the field.
    2) There is a high CPU cost to read each string & find the ones that have an infix/suffix match.

    STATISTICS TIME reports the following query taking > 11 seconds of CPU time to execute on SQLM11DEV.
*/

SELECT  c.CompanyName
FROM    XDB.dbo.Company AS c
        INNER JOIN XDB.dbo.Company_Metro AS cm
            ON cm.CompanyID = c.CompanyId
WHERE   c.CompanyName LIKE '%bob%';

/*
    By contrast, if the column belongs to a full-text index, we can use CONTAINS to search for matching
    terms.

    This works slightly differently than LIKE because the full-text engine has split the original string
    into terms, or words. We can find any words which are similar to our search term, or do a prefix search
    for words which begin with our search term.
    
    (Prefix search with "term*" should meet all of our needs here, but you can do other kinds of searches
     using CONTAINS. If you're curious: https://msdn.microsoft.com/en-us/library/ms187787.aspx)
*/

SELECT  c.CompanyName
FROM    XDB.dbo.Company AS c
        INNER JOIN XDB.dbo.Company_Metro AS cm
            ON cm.CompanyID = c.CompanyId
WHERE   cm.MetroID = 74
        AND CONTAINS (c.CompanyName, ' "bob*" ');

/*
    You might have noticed that this CONTAINS query example is only doing a prefix search,
    and therefore yields a different count than the LIKE query which does an infix search.

    The reason is simple: We CANNOT do a suffix or infix search using CONTAINS.
    While you can find 'Walmart' using LIKE '%mart', you cannot do the same using CONTAINS.
    This was deemed acceptable for XRC company/property/user name searches.
*/
-- Show the company names which match LIKE '%bob%' but not CONTAINS(CompanyName, ' "bob*" ')
SELECT  c.CompanyName
FROM    XDB.dbo.Company AS c
        INNER JOIN XDB.dbo.Company_Metro AS cm
            ON cm.CompanyID = c.CompanyId
WHERE   cm.MetroID = 74
        AND c.CompanyName LIKE '%bob%'
        AND c.CompanyId NOT IN (SELECT  c2.CompanyId
                                FROM    XDB.dbo.Company AS c2
                                        INNER JOIN XDB.dbo.Company_Metro AS cm2
                                            ON cm2.CompanyID = c2.CompanyId
                                WHERE   cm2.MetroID = 74
                                        AND CONTAINS (c2.CompanyName, ' "bob*" '));

/*
    A couple of things to keep in mind:

    1) A table can only have one full-text index. That index can include multiple columns.

    2) The table must have a key index on a single, unique, non-nullable key column.
       (This does not have to be the primary key, it can be a unique nonclustered index.)
*/

-- Show the tables & columns which are currently full-text indexed.
SELECT  o.name AS TableName
      , c.name AS ColumnName
      , fi.is_enabled AS IsFullTextIndexEnabled
FROM    XDB.sys.fulltext_indexes AS fi
        INNER JOIN XDB.sys.fulltext_index_columns AS fic
            ON fic.object_id = fi.object_id
        INNER JOIN XDB.sys.objects AS o
            ON o.object_id = fi.object_id
        INNER JOIN XDB.sys.columns c
            ON c.object_id = fic.object_id
               AND c.column_id = fic.column_id;