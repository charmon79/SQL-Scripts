# set execution policy so we can run unsigned local scripts
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force

# Trust Microsoft's default PowerShell Gallery repository
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Install & Import the NuGet provider
Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap

# Install dbatools module from PSGallery
Install-Module dbatools

# install PSFramework (prereq for dbachecks)
Install-Module PSFramework

# install Pester (prereq for dbachecks)
Install-Module Pester -SkipPublisherCheck -Force

# Oh yeah, let's install dbachecks also (builds atop dbatools for monitoring!)
Install-Module dbachecks

# Finally, import dbatools & tell PowerShell to always trust the publisher
Write-Host "Choose 'A' when prompted to always trust dbatools publisher!" -ForegroundColor Yellow
Import-Module dbatools

