Import-Module -Name (join-path $PSScriptRoot "/Win10-Initial-Setup-Script/Win10.psm1")
Import-Module -Name (join-path $psscriptroot "/Win10-Initial-Setup-Script/Win11.psm1")
Set-ExecutionPolicy Bypass -Scope Process -Force; 
. (join-path $PSScriptRoot "ActiveSetup.ps1")
. (join-Path $PSScriptRoot "helpers.ps1")

$PresetPath=(Join-Path $PSScriptRoot "presets")

Function Get-OptWinPreset(){
    $Presets=@()
    Get-ChildItem -path $PresetPath *.ps1 | ForEach-Object {
        . $_
        $Preset=[PSCustomObject]@{
            "Name" = $_.basename
            "Description" = $Description 
            "TaskCount" = $Tasks.Count
            "InputCount" = $Inputs.Count
            "Tasks" = $Tasks
            "Inputs" = $Inputs.Keys
        }
        $Presets+=$Preset
    }
    #output as table
    #todo: DefaultDisplayPropertySet$
    $Presets
}
Function Optimize-Windows() {
    [CmdletBinding()]
    param(
    [Parameter(Mandatory = $True)]
    [ValidateScript(
    {  $_ -in (Get-ChildItem -path $PresetPath *.ps1).basename }
    #, ErrorMessage = 'Please specify a valid preset, i.e. "Minimalist"' #only works in PS 7+
    )]
    [ArgumentCompleter(
    {
        param($cmd, $param, $wordToComplete)
        [array] $validValues = (Get-ChildItem -path $PresetPath *.ps1).basename
        $validValues -like "$wordToComplete*"
    }
    )]
    [String]$Preset)

    if((Test-Elevation) -eq $false){
        Write-Error "This script needs to be run as Administrator"
        return
    }
    
    $SelectedPreset = (Join-Path $PresetPath "$Preset.ps1") #get the list of tasks and inputs
    Write-Host "SelectedPreset:" $SelectedPreset
    Write-Host "Preset Path:" $PresetPath
    Write-Host "Gugus"
    . $SelectedPreset
    Write-Host "Do you want to execute the following ${tasks.count} Tasks?"
    $Tasks | ForEach-Object {
        $Description=(Select-Command $_|Get-Synopsis)
        Write-Host "☐ $Description"
    }
    Wait-Keypress
    Write-Information "Reading Inputs"
    $Inputs.GetEnumerator() | ForEach-Object {
        #todo: handle secret with Read-Password
        # if not interactive and has a default
        if ($PSCmdlet.ParameterSetName -eq "__AllParameterSets" -and $_.Value.Default) {
            $Value=$_.Value.Default
        }
        $_.Default = Read-Host -Prompt $Input.Title
        Write-Host $Input.Default
        New-Variable -Name $_.Key -Value $Value -Force -Scope Global
    }
    Write-Information "Processing $Tasks.count Tasks"
        $Tasks | ForEach-Object {
        $Description=(Select-Command $_|Get-Synopsis)
        Write-Progress -Activity "Optimize Windows" -Status $Description -PercentComplete ($Tasks.IndexOf($_)/$Tasks.Count*100)
        Write-Host $Description
        Invoke-Command $_ | out-null
    }
}

<#
.SYNOPSIS
Install VLC BECAUSE it can play anything
#>
Function Install-VLC {
    choco install vlc
    new-item -ItemType Directory -Path $env:appdata\vlc
    Copy-Item -Path $PSScriptRoot\assets\vlc\vlcrc -Destination $env:APPDATA\vlc\vlcrc -force
    Add-ActiveSetupComponent -DisplayName "VLC" -Id "VLC" -Script "New-Item -ItemType Directory -Path $env:appdata\vlc; Copy-Item -Path $PSScriptRoot\assets\vlc\vlcrc -Destination $env:APPDATA\vlc\vlcrc -force"  #TODO find path
    remove-item -path "$env:public\Desktop\VLC media player.lnk"
}

<#
.SYNOPSIS
Install I don't care about cookies BECAUSE we don't care about them
#>
Function Install-IDontCareAboutCookies {
    #todo: make for other browsers
    if ([Environment]::Is64BitOperatingSystem) {
        $Path = "HKLM:\Software\Wow6432Node\Google\Chrome\Extensions\fihnjjcciajhdojfnbdddfaoknhalnja"
    }
    else {
        $Path = "HKLM:\SOFTWARE\Google\Chrome\Extensions\fihnjjcciajhdojfnbdddfaoknhalnja"
    }
    New-Item $Path -ItemType Key -Force
    New-ItemProperty -Path $Path -Name "update_url" -Value "https://clients2.google.com/service/update2/crx" -PropertyType String -Force
    # you need to enable it manually on chrome!
}

<# 
.SYNOPSIS
Install Ublock Origin BECAUSE adds are distracting
#>
Function Install-UblockOrigin {
    #todo: other browsers
    if ([Environment]::Is64BitOperatingSystem) {
        $Path = "HKLM:\Software\Wow6432Node\Google\Chrome\Extensions\cjpalhdlnbpafiamejdnhcphjbkeiagm"
    }
    else {
        $Path = "HKLM:\SOFTWARE\Google\Chrome\Extensions\cjpalhdlnbpafiamejdnhcphjbkeiagm"
    }
    New-Item $Path -ItemType Key -Force
    New-ItemProperty -Path $Path -Name "update_url" -Value "https://clients2.google.com/service/update2/crx" -PropertyType String -Force
    # you need to enable it manually
}

<# 
.SYNOPSIS
Disable Chrome Password manager BECAUSE we save them in a better place
#>
Function Disable-ChromePasswordManager {
    $RegPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    New-ItemProperty -Path $RegPath -Name PasswordManagerEnabled -Value 0 -PropertyType DWord -Force
}

<#
.SYNOPSIS
Uninstall Bloatware BECAUSE we never asked for this
#>
Function Uninstall-Bloat {
    # UninstallMsftBloat #TODO: leave paint and calculator
    Get-AppxPackage -AllUsers "Microsoft.SkypeApp" | Remove-AppxPackage -AllUsers
    Get-AppxPackage "MicrosoftTeams" -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxPackage *Xbox* -AllUsers | Remove-AppxPackage -AllUsers #TODO: cannot remove...
    Get-AppxPackage *Spotify* -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxPackage *Solitaire* -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxPackage *Dropbox* -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxPackage *News* -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxPackage *ClipChamp* -AllUsers | Remove-AppxPackage -AllUsers
    Uninstall-Program "ExpressVPN"
    Uninstall-Program "Acer Jumpstart"
}

<#
.SYNOPSIS
Install Microsoft Office BECAUSE it is useful
#>
Function Install-Office {
    #choco install office365business
    push-location (Join-Path $PSScriptRoot "\assets\office\")
    ./setup.exe /configure $PSScriptRoot\assets\office\vogelsang.xml
    Pop-Location
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Office\16.0\Common\General'        -Name 'PreferCloudSaveLocations' -PropertyType DWORD -Value 0 -Force
    Add-ActiveSetupComponent -DisplayName "Disable Office Cloud" -Id "DisableOfficeCloud" -Script 'New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Common\General" -Name "PreferCloudSaveLocations" -PropertyType DWORD -Value 0 -Force'
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Office\16.0\Common\General'        -Name 'SkyDriveSignInOption' -PropertyType DWORD -Value 0 -Force
    Add-ActiveSetupComponent -DisplayName "Disable Office SkyDrive" -Id "DisableOfficeSkyDrive" -Script 'New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Common\General" -Name "SkyDriveSignInOption" -PropertyType DWORD -Value 0 -Force'
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Office\16.0\Word\options\DOC-PATH' -Name '\DOC-PATH' -Value "$env:userprofile\Desktop" -Force
    Add-ActiveSetupComponent -DisplayName "Set Word Default Save Location" -Id "SetWordDefaultSaveLocation" -Script 'New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Word\options\" -Name "DOC-PATH" -Value $env:userprofile\Desktop -Force'
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Office\16.0\Word\options'          -Name 'DisableBootToOfficeStart' -PropertyType DWORD -Value 1 -Force
    Add-ActiveSetupComponent -DisplayName "Disable Office Start" -Id "DisableOfficeStart" -Script 'New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Word\options" -Name "DisableBootToOfficeStart" -PropertyType DWORD -Value 1 -Force'
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Office\16.0\Word\options'          -Name 'AutosaveInterval' -PropertyType DWORD -Value 1 -Force
    Add-ActiveSetupComponent -DisplayName "Set Office Autosave Interval" -Id "SetOfficeAutosaveInterval" -Script 'New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Word\options" -Name "AutosaveInterval" -PropertyType DWORD -Value 1 -Force'
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Office\16.0\Common\LinkedIn'       -Name 'OfficeLinkedIn' -PropertyType DWORD -Value 0 -Force
    Add-ActiveSetupComponent -DisplayName "Disable Office LinkedIn" -Id "DisableOfficeLinkedIn" -Script 'New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Common\LinkedIn" -Name "OfficeLinkedIn" -PropertyType DWORD -Value 0 -Force'
}

<#
.SYNOPSIS
Install Google Chrome BECAUSE it is a good browser
#>
Function Install-GoogleChrome {
    choco install googlechrome --ignore-checksums
    New-Item -Path "HKLM:\SOFTWARE\Policies\Google"
    New-Item -Path "HKLM:\SOFTWARE\Policies\Google\Chrome"
    Remove-Item -Path (Join-Path "$env:public" "Desktop/Google Chrome.lnk")
    Remove-Item -Path (Join-Path "$env:userprofile" "Desktop/Google Chrome.lnk")
    #TODO: remove whats new
    #TODO: remove "welcome"
    #TODO: remind to activate plugins
    #TODO: set homepage
    #TODO: privacy
}

<#
.SYNOPSIS
Install Firefox BECAUSE it is a free and open browser
#>
Function Install-Firefox {
    choco install firefox
    refreshenv
    Remove-Item -Path (Join-Path "$env:public" "Desktop/Firefox.lnk")
    Remove-Item -Path (Join-Path "$env:userprofile" "Desktop/Firefox.lnk")
    firefox.exe -setdefaultbrowser -silent
}

<#
.SYNOPSIS
Disable Wifi BECAUSE the Computer is wired
#>
Function Disable-Wireless {
    Get-NetAdapter WLAN | Disable-NetAdapter -confirm:$false
}

<#
.SYNOPSIS
Enable Wifi BECAUSE we need it
#>
Function Enable-Wireless {
    Get-NetAdapter WLAN | Enable-NetAdapter -confirm:$false
}

<#
.SYNOPSIS
Disable Bluetooth BECAUSE if we don't need it it's more secure disabled
#>
Function Disable-Bluetooth {
    Get-PnpDevice | Where-Object { $_.Name -like "*Bluetooth*" } | Disable-PnpDevice -confirm:$false
}

<#
.SYNOPSIS
enable Bluetooth BECAUSE it is useful
#>
Function Enable-Bluetooth {
    Get-PnpDevice | Where-Object { $_.Name -like "*Bluetooth*" } | Enable-PnpDevice -confirm:$false
}

<#
.SYNOPSIS
Install DeepFreeze BECAUSE users should not be able to change anything
#>
Function Install-DeepFreeze {
    param(
    [Parameter(Mandatory = $true)]
    [String]$DeepFreezePassword
    )
    #TODO: create a choco or scoop package instead
    $oldloc = (Get-Location)
    set-location  (join-path $PSScriptRoot "assets\DeepFreeze")
    .\DFStd.exe /Install  /PW=$global:DeepFreezePassword /USB /FireWire /NoSplash /NoReboot #/Thawed
    set-location $oldloc
    Set-ItemProperty -Path 'HKCU:\Control Panel\NotifyIconSettings\8878936794893171756' -Name IsPromoted -Value 1 #Always show Tray Icon
    #TODO: manually: add license
}

<#
Remove Edge BECAUSE it is to distracting and always changes
#>
Function Disable-Edge {
    DisableEdgeShortcutCreation
    remove-item -path "C:\Users\Public\Desktop\Microsoft Edge.lnk"
    choco install msedgeredirect
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Robert Maehl Software\MSEdgeRedirect" -Name NoUpdates -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Robert Maehl Software\MSEdgeRedirect" -Name NoTray -Value 1
    Remove-TaskbarPin -AppName "Microsoft Edge" #maybe: does this work?
}

<#
.SYNOPSIS
Applies a specified wallpaper to the current user's desktop

.PARAMETER Image
Provide the exact path to the image

.PARAMETER Style
Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)

.EXAMPLE
Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit

#>
Function Set-WallPaper {
    
    param (
    [parameter(Mandatory = $True)]
    # Provide path to image
    [string]$Image,
    # Provide wallpaper style that you would like applied
    [parameter(Mandatory = $False)]
    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
    [string]$Style
    )
    
    $ImagePath = (get-item $Image).FullName
    
    $WallpaperStyle = Switch ($Style) {
        
        "Fill" { "10" }
        "Fit" { "6" }
        "Stretch" { "2" }
        "Tile" { "0" }
        "Center" { "0" }
        "Span" { "22" }
        
    }
    
    If ($Style -eq "Tile") {
        
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 1 -Force
        
    }
    Else {
        
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 0 -Force
        
    }
    
    Add-Type -TypeDefinition @" 
    using System; 
    using System.Runtime.InteropServices;
    
    public class Params
    { 
        [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
        public static extern int SystemParametersInfo (Int32 uAction, 
        Int32 uParam, 
        String lpvParam, 
        Int32 fuWinIni);
    }
"@
    
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
    
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
    
    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $fWinIni)
}

<#
.SYNOPSIS
Disable Printer Installation BECAUSE users shouldn't install printers
#>
Function Disable-PrinterInstallation {
    #todo: does this work?
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoAddPrinter -Value 1 -Type DWORD
}

<#
.SYNOPSIS
Disable Windows Update BECAUSE the computer is frozen anyways
.DESCRIPTION
Disable Windows Update BECAUSE the computer is frozen anyways
Only do this if you know what you are doing
#>
Function Disable-WindowsUpdate {
    get-service -DisplayName "Windows Update" | Stop-Service -Force
    get-service -DisplayName "Windows Update" | Set-Service -StartupType "Disabled"
}

<#
.SYNOPSIS
Create a Unsecure User BECAUSE we need a user without password for autologin
#>
Function New-UnsecureUser() {
    param(
    [Parameter(Mandatory = $true)]
    [String]$Name
    )
    Disable-PrivacyExperience
    New-LocalUser -Name $Name -NoPassword -AccountNeverExpires -Description "Generic Account without login" -UserMayNotChangePassword -FullName "$Name"
    Set-LocalUser -name $Name -PasswordNeverExpires:$true
    $UserDir = Join-Path $env:Systemdrive "Users"
    $UserDir = Join-Path $UserDir $Name
    new-Item -type Directory -path $userdir #Todo only if not exists
}

<#
.SYNOPSIS Enble Autologin BECAUSE it is more convenient
#>   
Function Enable-Autologin { 
    param(
    [Parameter(Mandatory = $true)]
    [String]$username
    )
    $RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    if (Test-Path (Join-Path $RegistryPath AutoLogonSID)) {
        Remove-ItemProperty -Path $RegistryPath -Name AutoLogonSID -Force
    }
    Set-ItemProperty -Path $RegistryPath 'AutoAdminLogon' -Value "1" -Type String 
    Set-ItemProperty -Path $RegistryPath 'DefaultUsername' -Value "$username" -type String 
    Set-ItemProperty -Path $RegistryPath 'DefaultPassword' -Value "" -type String
}

<#
.SYNOPSIS
Set Acrobat as default PDF Reader BECAUSE it is better than edge
#>
Function Set-DefaultPDFReader {
    #TODO: doesn't work
    $RegistryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice'
    New-ItemProperty -Path $RegistryPath -Name Progid -Value "Applications\Acrobat.exe" -Type String -Force
}

<#
.SYNOPSIS Disable Privacy Experience BECAUSE it asks to many questions on first login
#>
Function Disable-PrivacyExperience {
    $RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
    New-Item $RegistryPath
    New-ItemProperty -Path $RegistryPath -Name -Value 1 -Type DWORD -Force
}

<#
.SYNOPSIS Disable Feed BECAUSE it is distracting
#>
Function Disable-Feed {
    $RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
    New-Item $RegistryPath
    New-ItemProperty -Path $RegistryPath -Name "EnableFeeds " -Value 0 -Type DWORD -Force
    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests"
    New-ItemProperty -path $RegistryPath -name "AllowNewsAndInterests" -value 0 -type DWORD -Force
}

<#
.SYNOPSIS
Install 7zip BECAUSE it is the best archival Programm
#>
Function Install-7zip {
    choco install 7zip
}

<#
.SYNOPSIS
Install Sudo BECAUSE it is useful to elevate stuff on the fly
#>
Function Install-Sudo{
    
    choco install gsudo
    
    Write-Output "`nImport-Module 'gsudoModule'"| Add-Content $Profile
    gsudo config CacheMode Auto
}

<#
.SYNOPSIS
Install OpenShell BECAUSE we like Windows 7
#>
Function Install-OpenShell {
    choco install open-shell
    New-Item "HKLM:\SOFTWARE\OpenShell\StartMenu\" -Force
    New-Item "HKLM:\SOFTWARE\OpenShell\StartMenu\Settings" -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenShell\StartMenu\Settings" -Name SkinW7 -Value "Windows Aero"
}

<#
.SYNOPSIS Disable Searchbox BECAUSE we can search by hitting WIN Key
#>
Function Disable-SearchBox {
    $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    New-ItemProperty -Path $RegPath -Name "SearchboxTaskbarMode" -Value 0 -Type DWORD -Force
    Add-ActiveSetupComponent -DisplayName "Disable Searchbox" -Id "DisableSearchbox" -Script "New-ItemProperty -Path $RegPath -Name 'SearchboxTaskbarMode' -Value 0 -Type DWORD -Force"
}

<#
.SYNOPSIS
Disable Web Search BECAUSE it is distracting, we can just search in browser
#>
Function Disable-WebSearch {
    DisableWebSearch
    $Regpath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows"
    New-Item -Path $RegPath -name Explorer
    New-ItemProperty -Path $Regpath -PropertyType dword -Name 'DisableSearchBoxSuggestions' -Value 1
    Add-ActiveSetupComponent -id DisableWebSearch -DisplayName "Disable Web Search" -Script "New-Item -Path $RegPath -Name Explorer; New-ItemProperty -Path $Regpath\Explorer -PropertyType dword -Name 'DisableSearchBoxSuggestions' -Value 1"
}

<#
.SYNOPSIS
Disable Taskview BECAUSE it is distracting, we can just use ALT+TAB
#>
Function Disable-Taskview {
    $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    New-ItemProperty -Path $RegPath -Name "ShowTaskViewButton" -Value 0 -Type DWORD -Force
    Add-ActiveSetupComponent -DisplayName "Taskview Ausblenden" -Id "DisableTaskview" -Version 1 -Script 'New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowTaskViewButton" -Value 0 -Type DWORD -Force'
}

<#
.SYNOPSIS
Set Default Printer BECAUSE it is convenient
#>
Function Set-DefaultPrinter {
    [CmdletBinding()]
    param (
    # Printer Name
    [Parameter(Mandatory = $true)]
    [String]
    $PrinterName
    )
    #todo: suggest printers
    $Printer = Get-CimInstance -Class Win32_Printer -Filter "Name='$PrinterName'"
    #todo: handle printer not found
    Invoke-CimMethod -InputObject $Printer -MethodName SetDefaultPrinter 
}

<#
.SYNOPSIS
Enable Shutdown on Powerbutton BECAUSE it is convenient
#>
Function Enable-ShutdownOnPowerbutton {
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\7648EFA3-DD9C-4E3E-B566-50F929386280"
    New-ItemProperty -Path $RegPath -Name "ACSettingIndex" -Value 3 -Type DWORD -Force
    New-ItemProperty -Path $RegPath -Name "DCSettingIndex" -Value 3 -Type DWORD -Force
    #todo: create disable Function
}

Function Set-TaskbarAlignement {
    #validate 0 or 1
    param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(0,1)]
    [int]$Alignment
    )
    $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    New-ItemProperty -Path $RegPath -Name "TaskbarAl" -Value $Alignment -Force
    Add-ActiveSetupComponent -Id TaskbarAlignement -DisplayName "Align Taskbar" -Script "New-ItemProperty -Path $RegPath -Name 'TaskbarAl' -Value $Alignment -Force"
}


<#
.SYNOPSIS
Move Taskbar to Left of Screen BECAUSE that's where it always has been.
.DESCRIPTION
Move Taskbar to Left of Screen BECAUSE that's where it always has been.
This is also the Windows 10 default.
.EXAMPLE
Move-TaskbarLeft
#>  
Function Move-TaskbarLeft {
    Set-TaskbarAlignement 0
}

<#
.SYNOPSIS
Move Taskbar to Center of Screen BECAUSE it looks better on huge Screens
.DESCRIPTION
Move Taskbar to Center of Screen BECAUSE it looks better on huge Screens.
This is also the Windows 11 default.
.EXAMPLE
Move-TaskbarCenter
#>
Function Move-TaskbarCenter {
    Set-TaskbarAlignement 1
}


<#
.SYNOPSIS
Remove all the default Printers BECAUSE they are cluttering the Printer Dialog
.DESCRIPTION
Remove all the Bloated Printers from Windows.
Keeps the PDF one as an Exception.
Make sure to run this Script at the end so it can also
remove the Printers that were installed by other Programs.
.EXAMPLE
Remove-BloatPrinters
#>
Function Remove-BloatPrinters {
    $Printers = get-printer
    foreach ($Printer in $Printers) {
        if ($Printer.Name -ne "Microsoft Print to PDF") {
            Remove-Printer $Printer
        }
    }
}

<#
.SYNOPSIS
Set Chrome as Default Browser BECAUSE it is better than Edge
#>
Function Set-ChromeDefaultBrowser {
    try {
        Write-Host "Starting script execution..."
        $namespaceName = "root\cimv2\mdm\dmmap"
        $className = "MDM_Policy_Config01_ApplicationDefaults02"
        $obj = Get-CimInstance -Namespace $namespaceName -ClassName $className -Filter "ParentID='./Vendor/MSFT/Policy/Config' and InstanceID='ApplicationDefaults'"
        if ($obj) {
            $obj.DefaultAssociationsConfiguration = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxEZWZhdWx0QXNzb2NpYXRpb25zPg0KICA8QXNzb2NpYXRpb24gSWRlbnRpZmllcj0iLmh0bSIgUHJvZ0lkPSJDaHJvbWVIVE1MIiBBcHBsaWNhdGlvbk5hbWU9Ikdvb2dsZSBDaHJvbWUiIC8+DQogIDxBc3NvY2lhdGlvbiBJZGVudGlmaWVyPSIuaHRtbCIgUHJvZ0lkPSJDaHJvbWVIVE1MIiBBcHBsaWNhdGlvbk5hbWU9Ikdvb2dsZSBDaHJvbWUiIC8+DQogIDxBc3NvY2lhdGlvbiBJZGVudGlmaWVyPSJodHRwIiBQcm9nSWQ9IkNocm9tZUhUTUwiIEFwcGxpY2F0aW9uTmFtZT0iR29vZ2xlIENocm9tZSIgLz4NCiAgPEFzc29jaWF0aW9uIElkZW50aWZpZXI9Imh0dHBzIiBQcm9nSWQ9IkNocm9tZUhUTUwiIEFwcGxpY2F0aW9uTmFtZT0iR29vZ2xlIENocm9tZSIgLz4NCjwvRGVmYXVsdEFzc29jaWF0aW9ucz4='
            Set-CimInstance -CimInstance $obj
        }
        else {
            $obj = New-CimInstance -Namespace $namespaceName -ClassName $className -Property @{ParentID = "./Vendor/MSFT/Policy/Config"; InstanceID = "ApplicationDefaults"; DefaultAssociationsConfiguration = "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxEZWZhdWx0QXNzb2NpYXRpb25zPg0KICA8QXNzb2NpYXRpb24gSWRlbnRpZmllcj0iLmh0bSIgUHJvZ0lkPSJDaHJvbWVIVE1MIiBBcHBsaWNhdGlvbk5hbWU9Ikdvb2dsZSBDaHJvbWUiIC8+DQogIDxBc3NvY2lhdGlvbiBJZGVudGlmaWVyPSIuaHRtbCIgUHJvZ0lkPSJDaHJvbWVIVE1MIiBBcHBsaWNhdGlvbk5hbWU9Ikdvb2dsZSBDaHJvbWUiIC8+DQogIDxBc3NvY2lhdGlvbiBJZGVudGlmaWVyPSJodHRwIiBQcm9nSWQ9IkNocm9tZUhUTUwiIEFwcGxpY2F0aW9uTmFtZT0iR29vZ2xlIENocm9tZSIgLz4NCiAgPEFzc29jaWF0aW9uIElkZW50aWZpZXI9Imh0dHBzIiBQcm9nSWQ9IkNocm9tZUhUTUwiIEFwcGxpY2F0aW9uTmFtZT0iR29vZ2xlIENocm9tZSIgLz4NCjwvRGVmYXVsdEFzc29jaWF0aW9ucz4=" }
        }
        
    }
    catch {
        $_.Exception.Message
    }
    
    Write-Host "Script execution completed."
}

<#
.SYNOPSIS
Disable Lockscreen BECAUSE there is only one user without login
.DESCRIPTION
Disable Lockscreen BECAUSE there is only one user without login
Only do this if you know what you are doing!
#>
Function Disable-Lockscreen {
    #Todo: what about DisableLockscreen?
    $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    New-Item -Path $Path
    New-ItemProperty -Path $Path -Name "NoLockScreen" -Type dword -value 1 -Force
}

<#
.SYNOPSIS
Install .NET Framework BECAUSE some programs need it
#>
Function Install-DotNet {
    Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3"
}

<#
.SYNOPSIS
Install Everything BECAUSE it is better than windows search
#>
Function Install-Everything {
    choco install everything
    remove-item (Join-Path $env:Public "Desktop/Everything.lnk")
    #TODO remove tray icon
}

<#
.SYNOPSIS
Disable Tray Overflow BECAUSE it is clutter
#>
Function Disable-TrayOverflow {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    $Path = "HKCR:\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify"
    New-ItemProperty -Path $Path -Name "SystemTrayChevronVisibility" -Type dword -value 0 -Force
}

<#
.SYNOPSIS
Enable Tray Overflow BECAUSE it is useful
#>
Function Enable-TrayOverflow {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    $Path = "HKCR:\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify"
    New-ItemProperty -Path $Path -Name "SystemTrayChevronVisibility" -Type dword -value 1 -Force
}

<#
.SYNOPSIS
Disable Conexant BECAUSE it is useless and buggy
#>
Function Disable-Conexant {
    Stop-Service CxAudMsg
    Set-Service CxAudMsg -StartupType Disabled
    Stop-Service CxMonSvc
    Set-Service CxMonSvc -StartupType Disabled
    Stop-Service CxUtilSvc
    Set-Service CxUtilSvc -StartupType Disabled
}

<#
.SYNOPSIS
Hide Chat Icon BECAUSE it is distracting, we can just open/pin teams
#>
Function Hide-ChatIcon {
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
    New-Item -Path $RegPath
    Set-ItemProperty -Path $regpath -Name ChatIcon -Value 3 -Type dword
}

<#
.SYNOPSIS
Show Chat Icon BECAUSE it is useful
#>
Function Show-ChatIcon {
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
    Remove-Item $RegPath
}

<#
.SYNOPSIS
Install Acrobat Reader BECAUSE it is better than Edge
#>
Function Install-Acrobat {
    choco install adobereader -params '"/UpdateMode 0"'
    Remove-Item -Path (Join-Path "$env:public" "Desktop/Adobe Acrobat.lnk")
    #todo: disable tour
}

<#
.SYNOPSIS
Disable Keyboard Layout BECAUSE less clutter in Tray and No accidental switches
.PARAMETER
Layout
The Layout to disable
.EXAMPLE
Disable-KeyboardLayout -Layout "de-CH"
#>
Function Disable-KeyboardLayout() {
    param(
    [parameter(mandatory = $True)]
    $Layout
    )
    #maybe: suggest layout
    $list = Get-WinUserLanguageList
    $list.RemoveAll({ $args[0].LanguageTag -clike "$Layout" })
    set-WinUSerLanguageList  $list -Force
}

<#
.SYNOPSIS
Clear Keyboard Layout BECAUSE less clutter in Tray and No accidental switches
#>
Function Clear-KeyboardLayout() {
    $Layouts = Get-WinUserLanguageList
    #Remove all but first
    $Layouts | Select-Object -Skip 1 | ForEach-Object {
        $Layouts.Remove($_)
    }
    Set-WinUSerLanguageList $Layouts -Force
    Add-ActiveSetupComponent -Id "ClearKeyboardLayout" -Script "Clear-KeyboardLayout"
    # maybe: not ideal
}

<#
.SYNOPSIS
Disable Sleep BECAUSE we want to see if it is running from afar
#>
Function Disable-Sleep() {
    powercfg /change standby-timeout-dc 0
    powercfg /change standby-timeout-ac 0
    powercfg /change monitor-timeout-dc 0
    powercfg /change monitor-timeout-ac 0
}

<#
.SYNOPSIS Disable Cortana BECAUSE it doesn't work in Switzerland
#>
Function Disable-Cortana {
    DisableCortana
    Add-ActiveSetupComponent -Id "DisableCortana" -DisplayName "Disable Cortana" -Script "DisableCortana"
}

<#
.SYNOPSIS Show File Extensions BECAUSE it is more secure
#>
Function Show-FileExtenstions {
    ShowKnownExtensions
    Add-ActiveSetupComponent -Id "ShowFileExtensions" -Script "New-Itemproperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Type DWord -Value 0"
}

<#
.SYNOPSIS
Clear all Notifications BECAUSE they are distracting
#>
Function Clear-Notifications {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    
    $notifications = Get-ChildItem -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings' | Select-Object -ExpandProperty Name
    
    foreach ($notification in $notifications) { 
        $lastRegistryKeyName = ($notification -split '\\')[-1] -replace '\\$'
        [Windows.UI.Notifications.ToastNotificationManager]::History.Clear($lastRegistryKeyName) 
    }
}

<#
.SYNOPSIS
Install PDF24 BECAUSE we don't want users to upload documents to the internet
#>
Function Install-PDF24 {
    choco install PDF24 #TODO: options?
    Remove-Item -Path (Join-Path "$env:public" "Desktop/PDF24.lnk")
    reg import (Join-Path $PSScriptRoot assets/pdf24.reg) #maybe: port to powershell
}
<#
.SYNOPSIS
Remove all pinned items from the taskbar
.DESCRIPTION
Remove all pinned items from the taskbar because the location to start Programs from is the START-Menu.
#>
Function Clear-Taskbar {
    $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
    Remove-ItemProperty -Path $RegPath -Name Favorites
    Add-ActiveSetupComponent -Id "ClearTaskbar" -Script "Remove-ItemProperty -Path $RegPath -Name Favorites"
}

<#
.SYNOPSIS
Sets the default terminal application.

.DESCRIPTION
The Set-DefaultTerminal Function is designed to alter the default terminal application for the
current user on a Windows machine. It modifies the Windows Registry to set the terminal application
to one of three possible choices: Windows Terminal, CMD, or back to the system default.
This can be useful in scenarios where you need to programmatically switch the terminal to suit
different workflows or user preferences.

.PARAMETER Application
A mandatory parameter specifying the terminal application to set as default.
Accepts one of the following values: 'Terminal', 'CMD', or 'Default'.

.EXAMPLE
Set-DefaultTerminal -Application 'Terminal'

This will set the Windows Terminal as the default terminal application for the current user.

.EXAMPLE
Set-DefaultTerminal -Application 'CMD'

This will set the CMD as the default terminal application for the current user.

.EXAMPLE
Set-DefaultTerminal -Application 'Default'

This will reset the terminal application to the system default.
#>
Function Set-DefaultTerminal {
    
    param(
    [parameter(mandatory = $True)]
    [ValidateSet('Terminal', 'CMD', 'Default')]
    $Application
    )
    switch ($Application) {
        "Terminal" {
            $DelegationConsole = "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
            $DelegationTerminal = "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"
            Break
        }
        "CMD" {
            $DelegationConsole = "{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}"
            $DelegationTerminal = "{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}"
            Break
        }
        "Default" {
            $DelegationConsole = "{00000000-0000-0000-0000-000000000000}"
            $DelegationTerminal = "{00000000-0000-0000-0000-000000000000}"
            Break
        }
    }
    New-ItemProperty -Path "HKCU:\Console\%%Startup" -Name DelegationConsole -Value $DelegationConsole -Force -PropertyType String
    Add-ActiveSetupComponent -Id "SetDefaultTerminal" -Script "New-ItemProperty -Path 'HKCU:\Console\%%Startup' -Name DelegationConsole -Value $DelegationConsole -Force"
    New-ItemProperty -Path "HKCU:\Console\%%Startup" -Name DelegationTerminal -Value $DelegationTerminal -Force -PropertyType String
    Add-ActiveSetupComponent -Id "SetDefaultTerminal" -Script "New-ItemProperty -Path 'HKCU:\Console\%%Startup' -Name DelegationTerminal -Value $DelegationTerminal -Force"
}

<#
.SYNOPSIS Show Known File Extensions BECAUSE it is more secure
#>
Function Show-KnownExtensions {
    ShowKnownExtensions
    Add-ActiveSetupComponent -Id "ShowKnownExtensions" -Script "ShowKnownExtensions"
}
<#
.SYNOPSIS
Install WinScan2PDF BECAUSE users know how to use it
#>
Function Install-WinScan2PDF {
    choco install WinScan2PDF
    Remove-Item -Path (Join-Path "$env:public" "Desktop/WinScan2PDF.lnk")
}

<#
.SYNOPSIS
Disable Search Highlights BECAUSE it is distracting
#>
Function Disable-SearchHighlights{
    Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -Value 0
}

<#
.SYNOPSIS
Hide 3D Objects from Explorer BECAUSE it is clutter
#>
Function Hide-3DObjects {
    Hide3DObjectsFromExplorer
}


<#
.SYNOPSIS
DisableAdminShares BECAUSE they are a security risk
#>
Function Disable-AdminShares {
    DisableAdminShares
}

<#
.SYNOPSIS
Disable Widgets BECAUSE they are distracting
#>
Function Disable-Widgets{
    DisableWidgets
}

<#
.SYNOPSIS
Uninstall OneDrive BECAUSE we can always reinstall it
#>
Uninstall-OneDrive{
    UninstallOneDrive
}