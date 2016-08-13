#args: $DataSource $Database $Filepath $DoCreate

#$args = '(local)', 'AdventureWorks2012', 'c:\temp', 1


$DataSource=$args[0] # server name and instance
$Database=$args[1] # the database to copy from
$Filepath=$args[2] # local directory to save build-scripts to
$DoCreate=$args[3]
$NewDatabase=$Database+'_TEST' # database to create as copy of $Database

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
$CreationScriptOptions.Filename =  "$($FilePath)\$($Database)_Build.sql"; 
$transfer = new-object ("$My.Transfer") $s.Databases[$Database]
 
$transfer.options=$CreationScriptOptions # tell the transfer object of our preferences
$transfer.ScriptTransfer()

If ($DoCreate -eq 1) {
"Creating new database $NewDatabase and applying script..."
# Create an empty database named $NewDatabase (drop first if exists)
$query = "
IF DB_ID('$NewDatabase') IS NOT NULL
BEGIN
    ALTER DATABASE $NewDatabase SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE $NewDatabase;
END;
GO

CREATE DATABASE $NewDatabase;
GO

/* if Change Tracking is enabled on the source database, enable it on target database */
IF EXISTS (
    SELECT * FROM sys.change_tracking_databases
    WHERE database_id = DB_ID('$Database')
)
ALTER DATABASE $NewDatabase SET CHANGE_TRACKING = ON (AUTO_CLEANUP = ON, CHANGE_RETENTION = 7 DAYS);
GO
"
Invoke-Sqlcmd -ServerInstance $DataSource -Database 'master' -Query $query

# Run the script we just created against the new database
Invoke-Sqlcmd -ServerInstance $DataSource -Database "$NewDatabase" -InputFile "$($FilePath)\$($Database)_Build.sql"
}


"Done."