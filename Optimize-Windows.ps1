#requires -RunAsAdministrator

$PresetPath=(Join-Path $PSScriptRoot "presets")
Function Optimize-Windows() {
    [CmdletBinding()]
    param(
    [Parameter(Mandatory = $True)]
    [ValidateScript(
    {  $_ -in (Get-ChildItem -path $PresetPath *.ps1).basename }
    #, ErrorMessage = 'Please specify a valid preset, i.e. "Minimalist"' #only works in PS 7+
    )]
    [ArgumentCompleter(
    {
        param($cmd, $param, $wordToComplete)
        [array] $validValues = (Get-ChildItem -path $PresetPath *.ps1).basename
        $validValues -like "$wordToComplete*"
    }
    )]
    [String]$Preset)
    
    . (Join-Path $PresetPath "$Preset.ps1") #get the list of tasks and inputs
    Write-Host "Do you want to execute the following ${tasks.count} Tasks?"
    $Tasks.Keys | ForEach-Object {
        Write-Host "☐ $_"
    }
    Wait-Keypress
    Write-Information "Reading Inputs"
    $Inputs.GetEnumerator() | ForEach-Object {
        #todo: handle secret with Read-Password
        # if not interactive and has a default
        if ($PSCmdlet.ParameterSetName -eq "__AllParameterSets" -and $_.Value.Default) {
            $Value=$_.Value.Default
        }
        $_.Default = Read-Host -Prompt $Input.Title
        Write-Host $Input.Default
        New-Variable -Name $_.Key -Value $Value -Force -Scope Global
    }
    Write-Information "Processing $Tasks.count Tasks"
        $Tasks.GetEnumerator() | ForEach-Object {
        Write-Progress -Activity "Optimize Windows" -Status "Task $($_.Key)" -PercentComplete ($_.Value.count / $Tasks.count * 100)
        Write-Host $_.Key
        Invoke-Command $_.Value | out-null
    }
}