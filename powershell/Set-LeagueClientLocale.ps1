<#
.SYNOPSIS
Creates a shortcut for the League of Legends client and optionally pins it to the taskbar or start menu.

.DESCRIPTION
This script creates a shortcut for the League of Legends client executable and defines a desired locale with options to pin the shortcut to the start menu and taskbar

.PARAMETER Locale
Mandatory parameter. Specifies the locale for the League of Legends client.

.PARAMETER PinToTaskbar
Optional switch parameter. If specified, the shortcut will be pinned to the taskbar.

.PARAMETER PinToStartMenu
Optional switch parameter. If specified, the shortcut will be pinned to the start menu.

.PARAMETER PinToDesktop
Optional switch parameter. If specified, the shortcut will be pinned to the desktop.

.NOTES
File Name      : Create-LoLShortcut.ps1
Author         : RoMinjun
Prerequisite   : PowerShell V5
Copyright 2023 - RoMinjun. All rights reserved.

.EXAMPLE
.\Create-LoLShortcut.ps1 -Locale "ko_KR" -PinToTaskbar
Creates a shortcut for the League of Legends client with the Korean language and pins it to the taskbar.

.EXAMPLE
.\Create-LoLShortcut.ps1 -Locale "ko_KR" -PinToStartMenu
Creates a shortcut for the League of Legends client with the Korean language and pins it to the start menu.

.EXAMPLE
.\Create-LoLShortcut.ps1 -Locale "ko_KR" -PinToTaskbar -PinToStartMenu
Creates a shortcut for the League of Legends client with the Korean language and pins it to the taskbar and start menu.
#>
param (
    [Parameter(Mandatory=$true,
               HelpMessage='Locales')]
    [ValidatePattern("^([a-z]+)_([A-Z]+)$")]
    [ValidateSet("en_US", "es_ES", "fr_FR", "pt_BR", "tr_TR", "de_DE", "fr_FR", "it_IT", "ru_RU", "zh_CN", "ja_JP", "ko_KR")]
    [string]$Locale,
    [switch]$PinToTaskbar,
    [switch]$PinToStartMenu,
    [switch]$PinToDesktop,
    [switch]$CloseRiotClient
)

Out-Null

# Function to get League Client's path while it's running
function Get-ClientPath {
    $script:proc = Get-Process LeagueClient

    while ($proc -eq $null) {
        Read-Host -Prompt "Start your League Client please... Press Enter if League Client's started."
        $script:proc = Get-Process LeagueClient
    }

    $script:clientPath = $proc.Path
}

Get-ClientPath

# Fucntion to create a new shortcut
function New-Shortcut {
    param(
        [Parameter(Mandatory=$true,
                   HelpMessage='Full path to where the shortcut should reside (~\Desktop) e.g.')]
        [string]$ShortcutPath,
        [Parameter(Mandatory=$true,
                   HelpMessage='Full path of the application the shortcut should open ($env:windir\notepad.exe) e.g.')]
        [string]$TargetPath

    )

    # Create COM object to work with shortcuts
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = "$TargetPath"
    $shortcut.Arguments = "--locale=$Locale"
    $shortcut.Save()


    # Copy the shortcut to taskbar and start menu directories if applied
    if ($PinToTaskbar) {
        $script:TaskbarPath = [System.Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
        Copy-Item -Path $ShortcutPath -Destination $TaskbarPath -Force
    }

    if ($PinToStartMenu) {
        $script:StartPagePath = [System.Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Windows\Start Menu\Programs"
        Copy-Item -Path $ShortcutPath -Destination $StartPagePath -Force
    }

    # Copy's to desktop
    if ($PinToDesktop) {
        Copy-Item -Path $ShortcutPath -Destination $HOME\Desktop -Force
    }

}

# Create the shortcut
$ShortcutPath = "$(Split-Path -Path $clientPath -Parent)\LeagueClient.lnk"
New-Shortcut -TargetPath "$clientPath"-ShortcutPath $ShortcutPath

function Restart-LeagueClient {
    # Stop running LeagueClient instance
    $proc.Kill()
    $proc.WaitForExit()


    # Start new LeagueClient instance with new shortcut
    do {
        Start-Sleep -Seconds 1
    } until (
        $proc.HasExited
    )

    Get-Process *riot* | Stop-Process
    Start-Process -f $ShortcutPath -Wait

    # Should probably change the process below to RiotClient with launch product being league of legends
    $newproc = (Get-Process LeagueClient).CommandLine
    if ($newproc -match [regex]::Escape($locale)) {
        Write-Output "Succesfully client's changed locale to $Locale"
    }

    if ($CloseRiotClient) {
        # close riot client possible issue when starting via riot client
    }
}

Restart-LeagueClient