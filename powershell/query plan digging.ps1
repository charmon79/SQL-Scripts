import-module dbatools

$query = @"
SELECT collection_time, session_id, query_plan
FROM dbadmin..WhoIsActiveStats
WHERE (collection_time between '2019-04-29 8:00 AM' and '2019-04-29 1:05 PM') and sql_text like 'DECLARE @AsOfDate DATETIME, @Insurer AS INTEGER%' 
"@

$query

$plans = Invoke-DbaQuery -SqlInstance PWCADSQL01\CADENCE -Query $query

# $results = @()
$qh = ""
$ph = ""

foreach ($p in $plans) {
    [xml]$xp = $p.query_plan

    #Set namespace manager
    $nsMgr = new-object 'System.Xml.XmlNamespaceManager' $xp.NameTable;
    $nsMgr.AddNamespace("sm", 'http://schemas.microsoft.com/sqlserver/2004/07/showplan');
    
    $results += [PSCustomObject]@{
        QueryHash = $xp.SelectNodes("//sm:StmtSimple", $nsMgr).QueryHash
        QueryPlanHash = $xp.SelectNodes("//sm:StmtSimple", $nsMgr).QueryPlanHash
        QueryPlan = $xp
        collection_time = $p.collection_time
        session_id = $p.session_id
    }
    # $QueryHash = $xp.SelectNodes("//sm:StmtSimple", $nsMgr).QueryHash
    # $QueryPlanHash = $xp.SelectNodes("//sm:StmtSimple", $nsMgr).QueryPlanHash

    # if ($QueryHash -ne $qh)
    # {
    #     $qh = $QueryHash
    #     Write-Output ('$qh = {0}' -f $qh)
    #     if ($QueryPlanHash -ne $ph -and $p.QueryPlan.Length -gt 1)
    #     {
    #         $ph = $QueryPlanHash
    #         Write-Output ('$ph = {0}' -f $ph)
    #         $xp.Save("c:\temp\{0}_{1}_{2}.sqlplan" -f ($p.collection_time.ToString("yyyyMMdd-hhmmss")), $p.session_id, $ph)
    #     }
    # }
}



$results | Where-Object {$null -ne $_.QueryHash} | Sort-Object QueryHash, QueryPlanHash | % {
    if ($_.QueryHash -ne $qh)
    {
        $qh = $_.QueryHash
        if ($_.QueryPlanHash -ne $ph)
        {
            $ph = $_.QueryPlanHash
            Write-Output ('$ph = {0}' -f $ph)
            $_.QueryPlan.Save("c:\temp\{0}_{1}_{2}.sqlplan" -f ($_.collection_time.ToString("yyyyMMdd-hhmmss")), $_.session_id, $ph)
        }
    }
}


# $results[0].QueryPlan.Save('C:\temp\QueryPlan.sqlplan')

