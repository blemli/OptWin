$Tasks=@(
    {Move-TaskbarLeft},
    {Set-Wallpaper -Path "$psscriptroot\assets\wallpaper\sunset.jpg"}    
)

$Inputs=[ordered]@{}

Write-Verbose $Tasks
Write-Verbose $Inputs