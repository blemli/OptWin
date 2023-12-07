$Tasks=@(
    {Move-TaskbarLeft}
    {Show-KnownExtensions},
    {Hide-3DObjects},
    {Uninstall-Bloat},
    {Remove-BloatPrinters},
    {Disable-AdminShares}
    {Clear-KeyboardLayout},
    {Disable-Cortana},
    {Disable-Edge},
    {Disable-SearchBox},
    {Disable-Taskview},
    {Disable-SearchHighlights},
    {Disable-Widgets},
    {Disable-Feed},
    {Hide-ChatIcon},
    {Update-Help},
    {Install-VLC}, #todo: check
    {Uninstall-OneDrive},
    {Install-7zip},
    {Install-PDF24},
    {Install-Everything},
    {choco install powertoys}
    {Clear-Taskbar},
    {Stop-Process -Name Explorer},
    {Clear-RecycleBin -Force},
    {Clear-Notifications}
)

$Inputs=[ordered]@{}

Write-Verbose $Tasks
Write-Verbose $Inputs