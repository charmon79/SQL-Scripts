

$outFile = "C:\temp\ServiceAccountSearchResult.txt"

$servers = Get-ADComputer -Filter * -SearchBase "OU=Domain Servers, DC=foo, DC=com" | ? {$_.Enabled}

$results = [PSCustomObject]@()

Write-Output "" | out-file $outFile

foreach ($s in $servers) {
    Write-Output ("*** {0} ***" -f $s.name)
    Write-Output ("*** {0} ***" -f $s.name) | out-file -Append $outFile

    Get-WmiObject win32_service -ComputerName $s.name | ? { $_.StartName -eq "foo\Administrator" } | select Name, StartName, State, StartMode | format-table -AutoSize | out-file -Append $outFile
}
