#TODO - read this from a file or enumerate some other way
$computers = "SQL01"
$outpath = "C:\temp\"

Function Get-NetLocalGroup { # because easier ways to do this don't exist in PoSh 2.0/Win2008
    [cmdletbinding()]
    
    Param(
    [Parameter(Position=0)]
    [ValidateNotNullorEmpty()]
    [object[]]$Computername=$env:computername,
    [ValidateNotNullorEmpty()]
    [string]$Group = "Administrators",
    [switch]$Asjob
    )
    
    Write-Verbose "Getting members of local group $Group"
    
    #define the scriptblock
    $sb = {
     Param([string]$Name = "Administrators")
    $members = net localgroup $Name | 
     where {$_ -AND $_ -notmatch "command completed successfully"} | 
     select -skip 4
    New-Object PSObject -Property @{
     Computername = $env:COMPUTERNAME
     Group = $Name
     Members=$members
     }
    } #end scriptblock
    
    #define a parameter hash table for splatting
    $paramhash = @{
     Scriptblock = $sb
     HideComputername=$True
     ArgumentList=$Group
     }
    
    if ($Computername[0] -is [management.automation.runspaces.pssession]) {
        $paramhash.Add("Session",$Computername)
    }
    else {
        $paramhash.Add("Computername",$Computername)
    }
    
    if ($asjob) {
        Write-Verbose "Running as job"
        $paramhash.Add("AsJob",$True)
    }
    
    #run the command
    Invoke-Command @paramhash | Select * -ExcludeProperty RunspaceID
    
} #end Get-NetLocalGroup

function Get-ADGroupMemberRecursive ($group) {

}

# for each computer, enumerate local admins & if they're AD groups, get their members
# (TODO: enumerate members of local groups which are members of Administrators)
foreach ($c in $computers) {
    $admins = Get-NetLocalGroup -ComputerName $c -Group "Administrators"

    $adminUsers = @{} # hashtable to build up output results

    foreach ($a in $admins.Members) {
        $adGroup = Get-ADGroup -LDAPFilter "(SAMAccountName=$a)"

        if ($adGroup -ne $null) {
            $adGroupMembers = Get-ADGroupMember -Identity $a -Recursive
        }
    }
}

