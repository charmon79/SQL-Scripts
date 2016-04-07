USE atlas;
GO

DECLARE
--CREATE PROCEDURE dbo.awPersonExtract
    @BatchID INT = 0
,   @BatchSize INT = 10
,   @ChangeVersion BIGINT = 0
,   @Reinit BIT = 0
--AS
BEGIN
/*
    Valid inputs:
        1.  @BatchID = 0|1 [, @BatchSize = n] [, @Reinit = 0|1]
            Start a brand new bulk load. Optionally, reinitialize the table containing the list of IDs to load.
        2.  @ChangeVersion = n
            Poll for most recent incremental changes since version n, meant to be the last known sync version.
            (Requires Change Tracking to be enabled for all tables involved in extract query in the source database.)
*/

/* Fail on invalid combination of inputs */
IF @ChangeVersion <> 0 AND @Reinit = 1
BEGIN
    /* We don't want to allow @Reinit = 1 if only polling changes, in case someone is doing a full reload at the same time. */
    RAISERROR('@Reinit and @ChangeVersion cannot both be specified.', 16, 1);
    RETURN -1
END

/* Clean inputs */
IF @BatchID < 1 SET @BatchID = 1;
IF @BatchSize < 1 SET @BatchSize = 0;

/* Declare variables */
DECLARE @xml XML;
DECLARE @StartRank INT = ((@BatchID - 1) * @BatchSize) + 1;
DECLARE @EndRank INT = @StartRank + (@BatchSize - 1);
DECLARE @sql NVARCHAR(MAX);
--DECLARE @PersonID INT = 2409

/* Prepare staging tables with a list of ID values to extract. This lets us carve it up into batches if necessary. */
IF @Reinit = 1
BEGIN
    IF object_id('dbo.Person') IS NOT NULL DROP TABLE dbo.Person;
    CREATE TABLE dbo.Person (BusinessEntityID INT, RankID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED);

    INSERT INTO dbo.Person (BusinessEntityID)
    SELECT BusinessEntityID FROM AdventureWorks2014.Person.Person;
END

ELSE IF @ChangeVersion <> 0
BEGIN
    IF object_id('dbo.PersonDelta') IS NOT NULL DROP TABLE dbo.PersonDelta;
    CREATE TABLE dbo.PersonDelta (BusinessEntityID INT, RankID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED);

    /*
        Find IDs that have changes we need to load, including changes in any related tables that get joined in the extract query.
        (Really want to make this metadata-driven, so we don't have to hard-code object names & maintain this section
        if tables are added to/removed from the extract query.)


    */



    SET @sql = N'SELECT * FROM CHANGETABLE(CHANGES AdventureWorks2014.Person.Person, @version) AS ct';

    INSERT INTO dbo.Person (BusinessEntityID)
    EXEC sys.sp_executesql @sql, N'@version bigint', @version = @ChangeVersion;
END

/* Fetch the current batch of IDs into a temp table */
IF object_id('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp;
CREATE TABLE #tmp (BusinessEntityID INT NOT NULL PRIMARY KEY CLUSTERED);

IF @ChangeVersion <> 0
BEGIN
    INSERT INTO #tmp (BusinessEntityID)
    SELECT BusinessEntityID FROM dbo.Person WHERE RankID BETWEEN @StartRank AND @EndRank;
END
ELSE
BEGIN
    INSERT INTO #tmp (BusinessEntityID)
    SELECT BusinessEntityID FROM dbo.PersonDelta WHERE RankID BETWEEN @StartRank AND @EndRank;
END


/* Generate the output result set */
SET @xml = (
SELECT  p.BusinessEntityID AS _id
      , p.BusinessEntityID AS PersonID
      , p.PersonType
      , p.Title
      , p.FirstName
      , p.MiddleName
      , p.LastName
      , p.Suffix
      , dbo.awGetPersonPhoneList(p.BusinessEntityID) AS PhoneList
      , p.ModifiedDate
FROM AdventureWorks2014.Person.Person AS p
WHERE p.BusinessEntityID = @PersonID
ORDER BY p.BusinessEntityID
FOR XML PATH, ROOT
)

SELECT dbo.FlattenedJSON(@xml, 'root', '{"create": {"_index": "aw_person_load", "_type": "property", "_id" : "^^ID^^"}}');

END;

GO

SET STATISTICS IO, TIME on

--USE AdventureWorks2014;
USE master;

DECLARE @version BIGINT = 0

--SELECT * FROM CHANGETABLE(CHANGES AdventureWorks2014.Person.Person, @version) AS ct

SELECT DISTINCT
        p.BusinessEntityID
FROM    AdventureWorks2014.Person.Person AS p
        INNER JOIN AdventureWorks2014.Person.PersonPhone AS pp
            ON pp.BusinessEntityID = p.BusinessEntityID
        INNER JOIN (SELECT  *
                    FROM    CHANGETABLE(CHANGES AdventureWorks2014.Person.PersonPhone, @version) AS ct
                   ) AS change
            ON change.BusinessEntityID = pp.BusinessEntityID;