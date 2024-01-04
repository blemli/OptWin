Set-ExecutionPolicy Bypass -Scope Process -Force
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Get-PSRepository -Name PSGallery | Select-Object -Expandproperty InstallationPolicy | Set-Variable -Name OldInstallationPolicy
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name OptWin -Force -Scope AllUsers
Import-Module OptWin
Set-PSRepository -Name PSGallery -InstallationPolicy $OldInstallationPolicy