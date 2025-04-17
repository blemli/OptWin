[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
)
. .\helpers.ps1
. ./helpers.ps1
$ErrorActionPreference="Stop"
Write-Host "Getting nuget api key"
$Key=Get-Password -Name "Powershell Gallery OptWin" -Field "credential"
Import-PowerShellDataFile -Path .\OptWin.psd1 | Set-Variable ModuleData
$ModuleData| Select-Object -ExpandProperty ModuleVersion | Set-Variable OldVersion
$NewVersion=Step-Version -Version $OldVersion -By Patch
Write-Host "Validating module manifest"
Test-ModuleManifest -Path .\OptWin.psd1 | out-null
Update-ModuleManifest -Path .\OptWin.psd1 -ModuleVersion $NewVersion
Write-Host "Version $OldVersion -> $NewVersion"
Write-Host "Ready to publish"
if($PSCmdlet.ShouldProcess("PSGallery","Publish-Module")){
    Write-Host "Let's publish!!"
    Publish-Module -Path . -NuGetApiKey $Key -Repository PSGallery
    if((Find-Module OptWin | Select-Object -ExpandProperty Version) -ne $NewVersion){
        Write-Error "Something went wrong"
        return
    }else{
        Write-Host -ForegroundColor Green "Module published successfully"
    }
    Write-Host "Installing newest version"
    Install-Module -Name OptWin -Force
    Import-Module OptWin
}
Remove-Variable "Key"
