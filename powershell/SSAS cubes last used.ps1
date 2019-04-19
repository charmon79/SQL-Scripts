<# 
 SYNOPSIS 
    Lists all objects of a SSAS database. 
 DESCRIPTION 
    This script uses AdoMd Client to lists all objects of a SSAS database with their 
    last processing and update timestamp. 
    Works with SSAS 2005 and higher version. 
 NOTES 
    Author  : Olaf Helper 
    Requires: PowerShell Version 2.0, AdoMd Client assembly 
 LINK 
    MSDN AdoMd Client 
        http://msdn.microsoft.com/en-us/library/microsoft.analysisservices.adomdclient.aspx 
#> 
 
# Change the server and the database name to meet your enviroment. 
[string] $server   = "foo\bar" 
[string] $database = "dbFoo" 
 
# Add AdoMd client namespace. 
$loadInfo = [Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.AdomdClient") 

$lastUpdated = [datetime]"1999-01-01"
$lastProcessed = [datetime]"1999-01-01"
 
# Open a connection to SSAS database. 
$cat = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection 
$cat.ConnectionString = "Data Source=$server;Initial Catalog=$database" 
try  
{   $cat.Open() 
 
    # Print server version, state and database name. 
    Write-Output ("`nVersion: {0}`nState: {1}`nDB name: {2}`n" -f 
                  $cat.ServerVersion, $cat.State.ToString(), $cat.Database 
                 ) 
 
    # Print last processed and updated timestamp for each object in the database. 
    foreach ($cube in $cat.Cubes) 
    { 
        #Write-Output ("Object: {0} ({1})`nPrc: {2}`nUpd: {3}`n" -f 
        #               $cube.Name, $cube.Type.ToString(), $cube.LastUpdated, $cube.LastProcessed 
         #            )
        if ($cube.LastUpdated -gt $lastUpdated) {$lastUpdated = $cube.LastUpdated}
        if ($cube.LastProcessed -gt $lastProcessed) {$lastProcessed = $cube.LastProcessed}
    } 
    $cat.Close()

    Write-Output ("Last updated: {0}`nLast processed: {1}" -f $lastUpdated, $lastProcessed)
} 
catch  
{ 
    Write-Output ($_.Exception.Message)  
} 
finally 
{ 
    # Cleanup objects.     
    $cat.Dispose() 
}