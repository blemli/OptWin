$Tasks=@(
    {Hide-3DObjects},
    {Remove-BloatPrinters},
    {Disable-AdminShares}
    {Clear-KeyboardLayout},
    #{Disable-SearchHighlights},
    #{Disable-Widgets},
    #{Disable-Feed},
    #{Hide-ChatIcon},
    #{Hide-AppSuggestions},
    {Enable-Ping},
    {Update-Help},
    #{Install-VLC}, #todo: check
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