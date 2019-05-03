$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file "~/keys/powershell/rubrik.key"


(get-credential).Password | ConvertFrom-SecureString -key (get-content "~/keys/powershell/rubrik.key") | set-content "~/keys/powershell/rubrik.txt"