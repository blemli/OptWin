$Tasks=@(
    {Move-TaskbarLeft}
    {Show-KnownExtensions},
    {Hide-3DObjects},
    {Uninstall-Bloat},
    {Remove-BloatPrinters},
    {Disable-AdminShares}
    {Clear-KeyboardLayout},
    {Disable-Cortana},
    #{Disable-Edge},
    {Disable-SearchBox},
    {Disable-SearchHighlights},
    {Disable-Widgets},
    {Disable-Feed},
    {Hide-ChatIcon},
    {Hide-AppSuggestions},
    {Uninstall-OneDrive},
    {Update-Help},
    {Install-VLC},
    {Install-7zip},
    {Install-PDF24},
    {Install-Everything},
    {Clear-Taskbar},
    {Stop-Process -Name Explorer},
    {Clear-RecycleBin -Force},
    {Clear-Notifications}
)

$Inputs=[ordered]@{}

Write-Verbose $Tasks.ToString()
Write-Verbose $Inputs.ToString()