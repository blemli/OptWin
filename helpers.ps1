Function Uninstall-Helpers {
    choco uninstall git
    uninstall-Chocolatey
    #TODO: also remove tempdir
}

Function Set-Dword{
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $Path,
        [Parameter(Mandatory=$true)]
        [String]
        $Name,
        [Parameter(Mandatory=$true)]
        [int]
        $Value
    )

    New-ItemProperty -Path $Path -Name $Name -PropertyType DWORD -Value $Value -Force
}


function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}
Function Uninstall-Program($Program) {
    (Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "$Program" }).uninstall()
}



Function Remove-TaskbarPin {
    #TODO: doesn't seem to work on windows11
    param(
        [String]$AppName
    )
    ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ? { $_.Name -eq $appname }).Verbs() | ? { $_.Name.replace('&', '') -match 'Unpin from taskbar' } | % { $_.DoIt(); $exec =
        $true }
}

Function Wait-Keypress{
    #maybe: check if powershell is running interactively
    #maybe: specify key to wait for?
    Write-Host "Press any key to continue..."
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $x | out-null
}

Function Uninstall-Chocolatey {
    <#
    .SYNOPSIS Uninstall Chocolatey BECAUSE it shouldn't be to be too easy to install software
    #>
    $VerbosePreference = 'Continue'
    if (-not $env:ChocolateyInstall) {
        $message = @(
        "The ChocolateyInstall environment variable was not found."
        "Chocolatey is not detected as installed. Nothing to do."
        ) -join "`n"
        
        Write-Warning $message
        return
    }
    
    if (-not (Test-Path $env:ChocolateyInstall)) {
        $message = @(
        "No Chocolatey installation detected at '$env:ChocolateyInstall'."
        "Nothing to do."
        ) -join "`n"
        
        Write-Warning $message
        return
    }
    
    <#
    Using the .NET registry calls is necessary here in order to preserve environment variables embedded in PATH values;
    Powershell's registry provider doesn't provide a method of preserving variable references, and we don't want to
    accidentally overwrite them with absolute path values. Where the registry allows us to see "%SystemRoot%" in a PATH
    entry, PowerShell's registry provider only sees "C:\Windows", for example.
    #>
    $userKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()
    
    $machineKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\', $true)
    $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()
    
    $backupPATHs = @(
    "User PATH: $userPath"
    "Machine PATH: $machinePath"
    )
    $backupFile = "C:\PATH_backups_ChocolateyUninstall.txt"
    $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force
    
    $warningMessage = @"
    This could cause issues after reboot where nothing is found if something goes wrong.
    In that case, look at the backup file for the original PATH values in '$backupFile'.
"@
    
    if ($userPath -like "*$env:ChocolateyInstall*") {
        Write-Verbose "Chocolatey Install location found in User Path. Removing..."
        Write-Warning $warningMessage
        
        $newUserPATH = @(
        $userPath -split [System.IO.Path]::PathSeparator |
        Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator
        
        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
    }
    
    if ($machinePath -like "*$env:ChocolateyInstall*") {
        Write-Verbose "Chocolatey Install location found in Machine Path. Removing..."
        Write-Warning $warningMessage
        
        $newMachinePATH = @(
        $machinePath -split [System.IO.Path]::PathSeparator |
        Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator
        
        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $machineKey.SetValue('PATH', $newMachinePATH, 'ExpandString')
    }
    
    # Adapt for any services running in subfolders of ChocolateyInstall
    $agentService = Get-Service -Name chocolatey-agent -ErrorAction SilentlyContinue
    if ($agentService -and $agentService.Status -eq 'Running') {
        $agentService.Stop()
    }
    # TODO: add other services here
    
    Remove-Item -Path $env:ChocolateyInstall -Recurse -Force -WhatIf
    
    'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
        foreach ($scope in 'User', 'Machine') {
            [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
        }
    }
    
    $machineKey.Close()
    $userKey.Close()
}
function Restart-Explorer {
    Stop-Process -Name Explorer
}

Function Get-ClearText($SecureString) {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    $value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) # free up the unmanged memory afterwards (thank to dimizuno)
    return $value
}

Function Read-Password() {
    param(
    [Parameter()]
    [switch]$NoRepeat,
    
    [Parameter()]
    [String]$Prompt = "Password"
    
    #[Parameter()]
    #[switch]$MinLength=0 #todo: implement
    
    )
    $First = "a"
    $Second = "b"
    # if prompt doesn't end with : add one
    if ($prompt[-1] -ne ":") {
        $prompt = "${Prompt}:"
    }
    if ($NoRepeat) {
        $First = Get-ClearText(Read-Host -Assecurestring -prompt "$prompt")
    }
    else {
        while ($first -ne $second) {
            $First = Get-ClearText(Read-Host -Assecurestring -prompt "$prompt")
            $Second = Get-ClearText(Read-Host -Assecurestring -prompt "Repeat $prompt")
            if ($first -eq $second) {
                break
            }
            Write-Error "Inputs do not match"
        }
    }
    return $first
}