$ssisDir = "C:\\temp\\SQL01"
$searchString = "foobar"

gci $ssisDir -Filter "*.dtsx" -Recurse | where {$_.Attributes -ne "Directory"} |
 ForEach-Object {
    $PackageXML = Get-Content $_.FullName

    if ($PackageXML | Select-String -Pattern $searchString) {
        #Write-Output ("Found in package '{0}'" -f $_.FullName)
        #Write-Output ($_.FullName)
        Write-Output "foo"
    }
 }

