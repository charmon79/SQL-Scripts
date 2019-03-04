$sqlInstance = 'FOOSQL'
$database = 'foobar'
$searchRegex = '[serverName].'
$replaceString = ''

$sprocName = @(
 'uspFoo'
,'uspBar'
)

$viewName = @(
 'vwFoo'
,'vwBar'
)

$scriptingOptions = New-DbaScriptingOption
$scriptingOptions.ScriptForAlter = $true
$scriptingOptions.IncludeDatabaseContext = $true

$sprocName | ForEach-Object {
    $sp = Get-DbaDbStoredProcedure -SqlInstance $sqlInstance -Database $database | Where name -eq $_

    # generate alter scripts
    -join ("USE {0}" -f $sp.Database), "GO", ($sp.ScriptHeader($true)), ( $sp.TextBody -ireplace [regex]::Escape($searchRegex), $replaceString ), "GO" | out-file ('C:\temp\Stored Procedures\{0}.sql' -f $_) 

    Invoke-SqlCmd -ServerInstance $sqlInstance -Database $database -InputFile ('C:\temp\Stored Procedures\{0}.sql' -f $_) 
}

$viewName | ForEach-Object {

    $view = Get-DbaDbView -SqlInstance $sqlInstance -Database $database | Where name -eq $_

    # generate alter scripts
    -join ("USE {0}" -f $view.Database), "GO", ($view.ScriptHeader($true)), ( $view.TextBody -ireplace [regex]::Escape($searchRegex), $replaceString ), "GO" | out-file ('C:\temp\Views\{0}.sql' -f $_) 

    Invoke-SqlCmd -ServerInstance $sqlInstance -Database $database -InputFile ('C:\temp\Views\{0}.sql' -f $_) 
}






