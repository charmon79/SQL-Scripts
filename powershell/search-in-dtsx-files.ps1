$ssisDir = "C:\temp\SSIS"
$searchString = "I want to find SSIS packages that contain this text"

gci $ssisDir -Filter "*.dtsx" -Recurse | where {$_.Attributes -ne "Directory"} |
 ForEach-Object {
    $PackageXML = Get-Content $_.FullName

    if ($PackageXML | Select-String -Pattern $searchString) {
        Write-Output ("Found in package '{0}'" -f $_.FullName)
    }
 }