<#
    Title:       DatabaseScriptFull.ps1
    Author:      Chris Harmon (much code borrowed from https://www.simple-talk.com/sql/database-administration/automated-script-generation-with-powershell-and-smo/)
    Create Date: 2016-08-13

    Uses SMO to script out an entire database to a file which can be used to create a copy of the database.
    
    If $DoCreate = 1, after generating the database script, will use that script to create a new,
    empty database on the same instance, with _TEST appended to the database name.

    args: $DataSource $Database $Filepath $DoCreate
#>

#$args = '(local)', 'XDB', 'c:\temp', 1

$DataSource='.\SQL2014' # server name and instance
$Database='XDB' # the database to copy from
$Filepath='C:\temp' # local directory to save build-scripts to
$DoCreate=1
$NewDatabase=$Database+'_TEST' # database to create as copy of $Database

$TargetScriptName=$FilePath+'\'+$Database+'_Build.sql'

"Generating script of database $Database..."

# set "Option Explicit" to catch subtle errors
set-psdebug -strict
$ErrorActionPreference = "stop" # you can opt to stagger on, bleeding, if an error occurs
# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$ms='Microsoft.SqlServer'
$v = [System.Reflection.Assembly]::LoadWithPartialName( "$ms.SMO")
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
[System.Reflection.Assembly]::LoadWithPartialName("$ms.SMOExtended") | out-null
   }
$My="$ms.Management.Smo" #
$s = new-object ("$My.Server") $DataSource
if ($s.Version -eq  $null ){Throw "Can't find the instance $Datasource"}
$db= $s.Databases[$Database] 
if ($db.name -ne $Database){Throw "Can't find the database '$Database' in $Datasource"};
$transfer = new-object ("$My.Transfer") $db
$CreationScriptOptions = new-object ("$My.ScriptingOptions") 
$CreationScriptOptions.ExtendedProperties= $true # yes, we want these
$CreationScriptOptions.DRIAll= $true # and all the constraints 
$CreationScriptOptions.Indexes= $true # Yup, these would be nice
$CreationScriptOptions.Triggers= $true # This should be included when scripting a database
$CreationScriptOptions.ScriptBatchTerminator = $true # this only goes to the file
$CreationScriptOptions.IncludeHeaders = $true; # of course
$CreationScriptOptions.ToFileOnly = $true #no need of string output as well
$CreationScriptOptions.IncludeIfNotExists = $true # not necessary but it means the script can be more versatile
$CreationScriptOptions.FullTextCatalogs = $true
$CreationScriptOptions.FullTextIndexes = $true
$CreationScriptOptions.FullTextStopLists = $true
$CreationScriptOptions.Statistics = $true
$CreationScriptOptions.AllowSystemObjects = $false
$CreationScriptOptions.ChangeTracking = $true
$CreationScriptOptions.Permissions = $true
$CreationScriptOptions.IncludeDatabaseRoleMemberships = $true
$CreationScriptOptions.ScriptOwner = $true
$CreationScriptOptions.Filename =  $TargetScriptName
$transfer = new-object ("$My.Transfer") $s.Databases[$Database]
 
$transfer.options=$CreationScriptOptions # tell the transfer object of our preferences
$transfer.ScriptTransfer()

If ($DoCreate -eq 1) {
"Creating new database $NewDatabase and applying script..."
# Create an empty database named $NewDatabase (drop first if exists)
$query = "
IF DB_ID('$NewDatabase') IS NOT NULL
BEGIN
    ALTER DATABASE [$NewDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$NewDatabase];
END;
GO

DECLARE @DataPath NVARCHAR(255) = (
    SELECT LEFT(physical_name, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name)) + 1)
    FROM [$Database].sys.database_files
    WHERE type = 0
);

DECLARE @LogPath NVARCHAR(255) = (
    SELECT LEFT(physical_name, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name)) + 1)
    FROM [$Database].sys.database_files
    WHERE type = 1
);

DECLARE @CreateSQL NVARCHAR(MAX) = 
N'
    CREATE DATABASE [$NewDatabase]
        ON (NAME = [$NewDatabase], FILENAME = '''+@DataPath+'$NewDatabase.mdf'', SIZE = 64 MB, FILEGROWTH = 64 MB)
    LOG ON (NAME = ["+$NewDatabase+"_Log], FILENAME = '''+@LogPath+'"+$NewDatabase+"_Log.ldf'', SIZE = 64 MB, FILEGROWTH = 64 MB)
';

EXEC (@CreateSQL);
GO

ALTER DATABASE [$NewDatabase] SET RECOVERY SIMPLE;
GO

ALTER AUTHORIZATION ON DATABASE::[$NewDatabase] TO sa;
GO

/* if Change Tracking is enabled on the source database, enable it on target database */
IF EXISTS (
    SELECT * FROM sys.change_tracking_databases
    WHERE database_id = DB_ID('$Database')
)
ALTER DATABASE [$NewDatabase] SET CHANGE_TRACKING = ON (AUTO_CLEANUP = ON, CHANGE_RETENTION = 7 DAYS);
GO
"
Invoke-Sqlcmd -ServerInstance $DataSource -Database 'master' -Query $query

# Run the script we just created against the new database
Invoke-Sqlcmd -ServerInstance $DataSource -Database "$NewDatabase" -InputFile "$TargetScriptName"
}


"Done."