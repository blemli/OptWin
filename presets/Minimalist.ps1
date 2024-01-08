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
    {Hide-AppSuggestions},
    {Uninstall-OneDrive},
    {Enable-Ping},
    {Update-Help},
    {Install-VLC}, #todo: check
    {Install-7zip},
    {Install-PDF24},
    {Install-Everything},
    {Install-Firefox},
    {Clear-Taskbar},
    {Stop-Process -Name Explorer},
    {Clear-RecycleBin -Force},
    {Clear-Notifications}
)

$Inputs=[ordered]@{}

Write-Verbose $Tasks.ToString()
Write-Verbose $Inputs.ToString()