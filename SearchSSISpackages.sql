--===========================================================================
-- 4/4/2016		Dave Panico		Created

--	Script to search through ssis packages as xml for a given string
-- Follow these steps:
--
-- 1) Copy the ssis solution to a shared network folder. For some reason this 
--	  will not work on your C drive
--
-- 2) Make note of the root /top level directory for the ssis solution. 
--	  This directory will be needed for the @myPath variable. 
--
-- 3) The @ObjectName variable is the string that you want to search for. 
--	  Please note that column names and table names use the bracktes []. 
--	  ex : [dbo].[tablename]. 
--
--4) After the process runs, if there are any hits, the package name along 
--	 with the xml will be listed in a table format. It is a temp table 
--	 that gets dropped after the process runs. If there are no hits, then 
--	 the output will be an empty table
 
--===========================================================================

SET NOCOUNT on

--parameter
declare @myPath			NVARCHAR(4000) =  'q:\Xceligent.Data.ETL'
		,@ObjectName	VARCHAR(100) = '[dbo].[ZipCode]'
		,@dpath			VARCHAR(1000) 
		,@ID			INT
		,@Pdir			INT
		,@Path			VARCHAR(400)

CREATE TABLE #DirectoryTree (
	id int IDENTITY(1,1)
	,subdirectory nvarchar(512)
	,depth int
	,isfile bit
	, ParentDirectory int
	);

CREATE TABLE #DTSPackages(PkgName VARCHAR(200), x XML )
CREATE TABLE #SSISResults(PkgName VARCHAR(200), pkgXML XML, SearchString VARCHAR(100) )

CREATE TABLE #dirs( 
	id				INT
	,subdirectory	VARCHAR(400)
	,depth			INT
	,isFile			bit
    ,ParentDirectory INT
	,container		VARCHAR(400)
	,dpath			VARCHAR(400)

)

--====================================================
-- this section determines the hierarchy of the 
-- ssis packages and their associated files. We're
-- only concerned with the parent ( isfile = 0) and
-- the dtsx files. NON dtsx files are ignored 
--====================================================

-- top level directory
INSERT #DirectoryTree (subdirectory,depth,isfile)
	VALUES (@myPath,0,0);
-- all the rest under top level
INSERT #DirectoryTree (subdirectory,depth,isfile)
	EXEC master.sys.xp_dirtree @myPath,0,1;

UPDATE #DirectoryTree
	SET ParentDirectory = (
		SELECT MAX(Id) FROM #DirectoryTree
		WHERE Depth = d.Depth -1 AND Id < d.Id	)
FROM #DirectoryTree d;


-- SEE all with full paths
WITH dirs AS (
	 SELECT
		 Id,subdirectory,depth,isfile,ParentDirectory
		 , CAST (null AS NVARCHAR(MAX)) AS container
		 , CAST([subdirectory] AS NVARCHAR(MAX)) AS dpath
		 FROM #DirectoryTree
		 WHERE ParentDirectory IS NULL 
	 UNION ALL
	 SELECT
		 d.Id,d.subdirectory,d.depth,d.isfile,d.ParentDirectory
		 , dpath as container
		 , dpath +'\'+d.[subdirectory]  
	 FROM #DirectoryTree AS d
	 INNER JOIN dirs ON  d.ParentDirectory = dirs.id
)

INSERT INTO #dirs
        ( id ,
          subdirectory ,
          depth ,
          isFile ,
          ParentDirectory ,
          container ,
          dpath
        )
SELECT id ,
          subdirectory ,
          depth ,
          isFile ,
          ParentDirectory ,
          container ,
          dpath
FROM dirs
WHERE depth > 0 
  AND ( isFile = 0 
		OR  subdirectory LIKE '%.dtsx'
	)


--SELECT * FROM #dirs ORDER BY id

--SELECT DISTINCT parentdirectory 
--FROM #dirs 
--WHERE ParentDirectory > 1
-- AND subdirectory LIKE '%.dtsx'

------------------------------------------
-- cursor through the directories
-- change to xml
------------------------------------------
DECLARE s_cursor CURSOR 
READ_ONLY
FOR 
SELECT DISTINCT parentdirectory 
FROM #dirs 
WHERE ParentDirectory > 1
 AND subdirectory LIKE '%.dtsx'

OPEN s_cursor   
FETCH NEXT FROM s_cursor INTO @Pdir

WHILE @@FETCH_STATUS = 0   
BEGIN  

	-- make sure a file is available
	SELECT TOP 1 @dpath = dpath, @ID = id 
	FROM #dirs
	WHERE ParentDirectory = @Pdir 
	AND isfile = 1
	AND subdirectory LIKE '%.dtsx'

	-- gets all dtsx's associated with one parent package
	WHILE @dPath IS NOT NULL
	BEGIN
	
		-- here for monitoring progress
		PRINT @dPath

		-- converts dtsx to xml
		DECLARE @SQL varchar(max) = 'INSERT #DTSPackages
		SELECT ''' + @dpath + ''', *
		FROM OPENROWSET(BULK ''' + @dpath + ''',
		   SINGLE_BLOB) AS x;'

		EXEC (@SQL)
		--PRINT @sql 
		
		SET @dPath = NULL
		
		SELECT TOP 1 @dPath = dpath,@ID  = id
		FROM #dirs
		WHERE ParentDirectory = @Pdir 
		 AND isfile = 1
		 AND subdirectory LIKE '%.dtsx'
		 AND id > @ID
		ORDER BY id
	END

	-- searches the xml for the string occurence
	IF EXISTS(
		SELECT x
		FROM #DTSPackages
		WHERE CHARINDEX(@ObjectName,cast(x as nvarchar(max))) > 0
		)
	 BEGIN
		INSERT INTO #SSISResults
		        ( PkgName, pkgXML, SearchString)
		SELECT PkgName, x, @ObjectName
			FROM #DTSPackages	
	 END
     
	-- holds only the dtsx files associated with current parent
	TRUNCATE TABLE #DTSPackages

	FETCH NEXT FROM s_cursor INTO @pdir
END   

CLOSE s_cursor   
DEALLOCATE s_cursor


-- select the results 
SELECT * FROM #SSISResults


DROP TABLE #DirectoryTree
DROP TABLE #DTSPackages
DROP TABLE #dirs
DROP TABLE #SSISResults
