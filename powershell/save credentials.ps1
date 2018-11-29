# function to read ADM account credential from a secure file
Function Read-AdmCredential {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$userName
    )
    $cred = Import-Clixml -Path "~\pscreds\$userName.txt"
    return $cred
}

# function to save ADM account credential to a secure file
Function Save-AdmCredential {
    $userName = Read-Host 'Enter user name'
    $securePassword = Read-Host -Prompt 'Enter password' -AsSecureString
    New-Object System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword | Export-Clixml -Path "~\pscreds\$userName.txt"
}

