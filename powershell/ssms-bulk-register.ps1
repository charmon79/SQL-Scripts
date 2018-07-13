<#

Code from Jeffrey Yao https://www.mssqltips.com/sqlservertip/3252/automate-registering-and-maintaining-servers-in-sql-server-management-studio-ssms/
Bulk add servers to SSMS Registered Servers from a text file.

Input text file expects INI-like format, e.g.:

[HR]
HR_Server1
HR_Server2

[HR\REPORT]
HR_RPT1
HR_RPT2

#>

#ensure the script is run under SQL Server PowerShell window
if ((get-process -id $pid).MainWindowTitle -ne 'SQL Server PowerShell')
{
        write-error "`r`n`r`nScript should be run in SQL Server PowerShell Window. `r`n`r`nPlease start SQLPS from SSMS to ensure the correct SQLPS version loaded";
        return;

}

[string]$choice = 'Database Engine Server Group' # 'Central Management Server Group\CentralServerName';
$srv = @();

#part 1: Interpret the INI file
$pf='.';
SWITCH -Regex -File C:\TEMP\mssql-servers.txt # change to your own INI file path
{
    "^\s*\[(\w+[^\\])]$" #folder, the format is [folder]
    {
        $srv +=New-Object -TypeName psobject -Property @{ParentFolder='.'; Type='Directory'; Value=$Matches[1]; };
        $Pf = $matches[1];       
    }

    "^\s*\[(\w+\\.+)]$" #sub-folder, the format is [folder\subfolder]
    {
        $pf = split-path -Path $matches[1];
        [string]$leaf = split-path $matches[1] -Leaf;
        $srv +=New-Object -TypeName psobject -Property @{ParentFolder=$pf; Type='Directory'; Value=$leaf; };
        $pf = $matches[1];
             
    }

    '^\s*(?![;#\[])(.+)' # if you want to comment out one server, just put ; or # in front of the server name    
    {
        $srv += New-Object -TypeName PSObject -Property @{ParentFolder=$pf; Type='Registration'; value=$matches[1];}
    }

}

#part 2: create the folder/registered server based on the info in $srv

Set-Location "SQLServer:\SqlRegistration\$($choice)";
dir -Recurse | Remove-Item -force; #clean up everything
foreach ($g in $srv)
{
    if ($g.Type -eq 'Directory')
    {
        if ($g.ParentFolder -eq '.')
        {
           Set-Location -LiteralPath "SQLServer:\SqlRegistration\$($choice)"
        }
        else
        {
           Set-Location -LiteralPath "SQLServer:\SqlRegistration\$($choice)\$($g.ParentFolder)";
        }
        New-Item -Path $g.Value -ItemType $g.type;
    } 
    else # it is a registered server
    {
        $regsrv = $g.value.replace("%5C","\")
        New-Item -Name $(encode-sqlname $g.value) -path "sqlserver:\SQLRegistration\$($choice)\$($g.parentfolder)" -ItemType $g.type -Value ("Server=$regsrv ; integrated security=true");
    }
    
}

Set-Location "SQLServer:\SqlRegistration\$($choice)";


