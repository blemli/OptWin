$Tasks=[ordered]@{
    "Computer umbenennen"={Rename-Computer -NewName $global:ComputerName} #todo: ignore existing name
    "Dateiendungen einblenden"={ShowKnownExtensions};
    "3D Objekte verstecken"={Hide3DObjectsFromExplorer};
    "Bloatware löschen (Skype)"={Uninstall-Bloat};
    "Fax entfernen"={RemoveFaxPrinter};
    "XPS entfernen"={UninstallXPSPrinter};
    "WiFi deaktivieren"={Disable-Wireless};
    "Bluetooth deaktivieren"={Disable-Bluetooth};
    "Drucker installieren"={Add-Printer -ConnectionName "\\druckerserver\toshiba" -Name "Toshiba"};
    "Standarddrucker setzen"={Set-DefaultPrinter -PrinterName "Toshiba"};
    "Druckerinstallation verbieten"={Disable-PrinterInstallation};
    "Windows Update deaktivieren"={Disable-WindowsUpdate};
    "Lockscreen deaktivieren"={DisableLockscreen};
    "Cortana abschalten"={Disable-Cortana};
    "Keine Websuche im Startmenü"={Disable-WebSearch};
    "Surfer erstellen"={new-unsecureuser $global:username};
    "Autologin aktivieren"={Enable-Autologin};
    "Remove and Block Edge"={Disable-Edge};
    "Searchbox entfernen"={Disable-SearchBox};
    "Taskview entfernen"={Disable-Taskview};
    #"Wallpaper ändern"={Set-WallPaper -Image ".\assets\wallpaper.jpg" -Style Fill};
    "News deaktivieren"={Disable-Feed};
    "Shutdown on Powerbutton"={Enable-ShutdownOnPowerbutton};
    "VLC installieren"={Install-VLC};
    "Google Chrome installieren"={Install-GoogleChrome};
    "Google Chrome als Standard"={Set-DefaultBrowser};
    "Passwörter nicht Speichern in Chrome"={Disable-ChromePasswordManager};
    "Startseite im Browser"={Set-Homepage};
    "I don't care about cookies"={Install-IDontCareAboutCookies};
    "uBlock Origin"={Install-UblockOrigin};
    "Acrobat installieren"={choco install adobereader -params '"/UpdateMode 0"'};
    "Acrobat als Standard"={Set-DefaultPDFReader};
    "Office installieren"={Install-Office};
    "OneDrive Deinstallieren"={UninstallOneDrive};
    "7zip installieren"={Install-7zip};
    "ClassicShell (OpenShell) installieren"={Install-OpenShell};
    "Papercut installieren"={Install-Papercut};
    "DeepFreeze installieren"={Install-DeepFreeze -DeepFreezePassword $global:DeepFreezePassword};
    "Helper deinstallieren"={Uninstall-Helpers};
}

$Inputs=@{
    "Computername"=@{
        "Secret"=$false
        "Mandatory"=$true
    }
    "DeepFreezePassword"=@{
        "Title"="DeepFreeze Password"
        "Secret"=$true
        "Mandatory"=$true
    }
    "Username"=@{
        "Secret"=$false
        "Mandatory"=$true
    }
}