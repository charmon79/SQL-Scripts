<#
    Adapted from Scott Newman's script at https://sqlserverpowershell.com/2013/04/15/export-rdl-files-from-reportserver-database-with-powershell/
#>

Import-Module dbatools
 
$destDir = 'c:\temp\SSRS'

$rows = Invoke-DbaQuery -SqlInstance "foo\bar" -Database "ReportServer" -Query 'SELECT * FROM dbo.Catalog WHERE Content IS NOT NULL;'
 
foreach($row in $rows){
    $newDir = $row.Path.ToString() -replace '/', '\'
    #new-item will automagically create the directory from the string variable
    #for example, string "c:\test\dir1\dir2" will create all three directories
    New-Item -ItemType Directory -Path "$($destDir)$($newDir)" -ErrorAction SilentlyContinue
    $row.Content | Set-Content -Path "$($destDir)\$($newDir)\$($row.Name).rdl" -Encoding Byte
}