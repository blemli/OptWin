Function Uninstall-Helpers {
    choco uninstall git
    uninstall-Chocolatey
    #TODO: also remove tempdir
}
Function Install-Chocolatey {
    $ChocoPath="C:\ProgramData\chocolatey"
    if(Test-Path $ChocoPath){
        Remove-Item $ChocoPath -Force -Recurse
    }
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    RefreshEnv.cmd
    Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    RefreshEnv.cmd
    choco feature enable -n=allowGlobalConfirmation
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
    
    
    function Add-ActiveSetupComponent{
        [CmdletBinding()]
        param (
        [Parameter()]
        [String]
        $DisplayName,
        [Parameter(Mandatory=$True)]
        [String]
        $Id,
        [Parameter()]
        [String]
        $Locale,
        [Parameter(Mandatory=$True)]
        [String]
        $Script,
        [Parameter()]
        [String]
        $Version,
        [Parameter()]
        [String]
        [ValidateSet($null,"First","Last")]
        $Position = $null
        )
        
        switch ($Position) {
            $null  { $PositionChar="" }
            "First" { $PositionChar="<" }
            "Last"  { $PositionChar=">" }
            Default {$PositionChar=""}
        }
        
        $BasePath="HKLM:\Software\Microsoft\Active Setup\Installed Components"
        $RegPath= Join-Path $BasePath ("$PositionChar"+"$Id")
        New-Item -Path $RegPath
        
        New-ItemProperty -Path $RegPath -name "(default)" -value $DisplayName -Force
        if($Locale){
            New-ItemProperty -Path $RegPath -Name "Locale" -value "de"
        }
        New-ItemProperty -Path $RegPath -Name "StubPath" -value "powershell.exe -WindowStyle Hidden -NonInteractive -Command Set-ExecutionPolicy Bypass -Scope Process; $script" -Force
        if($Version){
            New-ItemProperty -Path $RegPath -Name "Version" -value $Version -Force
        }
    }
    
    function Disable-ActiveSetupComponent{
        param (
        [Parameter(Mandatory=$True)]
        [String]
        $Id
        )
        #todo: also try <$id and >$id
        $BasePath="HKLM:\Software\Microsoft\Active Setup\Installed Components"
        $RegPath= Join-Path $BasePath $Id
        New-ItemProperty -Path $RegPath -Name IsInstalled -value 0 -Force
    }
    
    function Enable-ActiveSetupComponent{
        param (
        [Parameter(Mandatory=$True)]
        [String]
        $Id
        )
        #todo: also try <$id and >$id
        $BasePath="HKLM:\Software\Microsoft\Active Setup\Installed Components"
        $RegPath= Join-Path $BasePath $Id
        New-ItemProperty -Path $RegPath -Name IsInstalled -value 1 -Force
    }
    
    Function Approve-ScriptExecution{
        $ExecutionPolicy = Get-ExecutionPolicy -Scope Process
        if($ExecutionPolicy -eq "RemoteSigned" -or $ExecutionPolicy -eq "Unrestricted" -or $ExecutionPolicy -eq "Bypass") {
            Write-Host "ScriptExecution is already allowed ($ExecutionPolicy)"
        } else {
            Write-Host "ExecutionPolicy is $ExecutionPolicy, changing to RemoteSigned"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
        }
    }
    
    Function Select-Command{
        param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [ScriptBlock]
        $ScriptBlock
        )
        # extract the command from the scriptblock
        try{
            $Command = $ScriptBlock.ToString().Split(" ")[0]
        }catch{
            Write-Error "Could not extract command from scriptblock"
        }
        # check if the command is available
        if(Get-Command $Command -ErrorAction SilentlyContinue){
            return $Command
        }else{
            Write-Error "Command $Command not found"
        }
    }
    
Function Test-Elevation{
    Write-Verbose "Checking for elevated permissions..."
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
        Return $false
    }
    else {
        Write-Verbose "Code is running as administrator — go on executing the script..."
        Return $true
    }
}

<#
.SYNOPSIS
    Increment a Semantic Version
.DESCRIPTION
    Parse a string in the format of MAJOR.MINOR.PATCH and increment the
    selected digit.
.EXAMPLE
    C:\PS> Step-Version 1.1.1
    1.1.2

    Will increment the Patch/Build section of the Version
.EXAMPLE
    C:\PS> Step-Version 1.1.1 Minor
    1.2.0

    Will increment the Minor section of the Version
.EXAMPLE
    C:\PS> Step-Version 1.1.1 Major
    2.0.0

    Will increment the Major section of the Version
.EXAMPLE
    C:\PS> $v = [version]"1.1.1"
    C:\PS> $v | Step-Version -Type Minor
    1.2.0
.INPUTS
    String
.OUTPUTS
    String
.NOTES
    This function operates on strings.
#>
function Step-Version {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        # Version as string to increment
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [version]
        $Version,

        # Version section to step
        [Parameter(Position=1)]
        [ValidateSet("Major", "Minor", "Build","Patch")]
        [Alias("Type")]
        [string]
        $By = "Patch"
    )

    Process
    {
        $major = $Version.Major
        $minor = $Version.Minor
        $build = $Version.Build

        switch ($By) {
            "Major" { $major++
                    $minor = 0
                    $build = 0
                    break }
            "Minor" { $minor++
                    $build = 0
                    break }
            Default { $build++
                    break }
        }

        Write-Output (New-Object Version -ArgumentList $major, $minor, $build).ToString()
    }
}

Function Get-Password{
    param(
    [Parameter(Mandatory=$true)]
    [String]
    $Name,
    [Parameter(Mandatory=$true)]
    [String]
    $Field
    )
    op item get "$Name" --fields "$Field"
}