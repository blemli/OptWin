# OptWin
_From Chaos to Calm: Windows is amazing, but not out of the box._ ![](./optwin.webp) 

```powershell
Install-Module OptWin
Optimize-Windows -Preset Minimalist
```

## What does it do?

There are different Presets and you can create your own. The *Minimalist* Preset does the following:

//todo: add



## Unattended

If you have something better to do while your OS is installed you can use the [Ventoy Autorun Plugin](https://www.ventoy.net/en/doc_inject_autorun.html) to automatically run Optimize-Windows after an unattended Windows Installation.

Put the [inject_optwin.7z](./inject_optwin.7z) into the *ventoy* folder on your usb-drive. Then insert the following into your ventoy.json:

```json
"auto_install": [
	{
		"image": "/iso/Win11_22H2_German_x64v2.iso",
		"template": "/ventoy/script/win11.xml"
   }
],
"injection": [
	{
		"image": "/iso/Win11_22H2_German_x64v2.iso",
		"archive": "/ventoy/inject_optwin.7z"
	}
]
```

adjust the image-paths to fit your image.



## Update

You can update the Module with `Update-Module -Name OptWin`

## Publish

You will need a PSGallery API-Key with the correct Permissions.

1. `$Key=(op item get "Powershell Gallery OptWin" --fields credential)`
2. `Publish-Module -Path . -NuGetApiKey $Key -Repository PSGallery`
3. Verify: `Install-Module -Name MyModule` then `Optimize-Windows -Preset Harmless -Whatif`
4. Remove Key: `Remove-Variable Key`
