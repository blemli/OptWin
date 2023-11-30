function Disable-WindowsHotkeys {
    #warning, disables all Windows Hotkeys including Win+R etc.
    $RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    New-ItemProperty -Path $RegPath -Name "NoWinKeys" -Value 1 -PropertyType dword
}

function Enable-WindowsHotkeys {
    $RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    New-ItemProperty -Path $RegPath -Name "NoWinKeys" -Value 0 -PropertyType dword
}