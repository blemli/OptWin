$Key=(op item get "Powershell Gallery OptWin" --fields credential)
Publish-Module -Path . -NuGetApiKey $Key -Repository PSGallery
Install-Module -Name OptWin -Force
Optimize-Windows -Preset Harmless -WhatIf
Remove-Variable "Key"