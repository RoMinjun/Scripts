# Script by Romin Kleeman (531630)
# This script is a follow up to the Set-VMTag.ps1 script in this repo where I used the set time tags to start or stop that outside of the given hours.

# Controleer of de Az-module is geïnstalleerd, zo niet installeer deze dan
if (!(Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Force
}

# Importeer de Az-module om de cmdlets te kunnen gebruiken
Import-Module Az

function Get-VMTags {
    param([string]$resourceGroup)
    $vms = Get-AzVM -ResourceGroupName $resourceGroup -Status
    $vmTags = foreach ($vm in $vms) {
        $tags = (Get-AzResource -ResourceId $vm.Id).Tags
        # Checken als de tijds tags are uberhaupt wel zijn, zo ja opslaan in een object
        if ($tags.ContainsKey("StartTime") -and $tags.ContainsKey("StopTime")) {
            [PSCustomObject]@{
                "Name" = $vm.Name
                "StartTime" = $tags["StartTime"]
                "StopTime" = $tags["StopTime"]
                "PowerState" = $vm.PowerState
            }
        }
    }
    return $vmTags
}

# Ophalen van de resource group en controleren als deze bestaat
$resourceGroup = Read-Host "Geef de naam van de resourcegroep op"
if (!(Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    Write-Host "Resourcegroep bestaat niet" -ForegroundColor Red
    exit
}

# Haal de tags op van de VM's in de resource group
$vmValues = Get-VMTags -resourceGroup $resourceGroup

foreach ($vm in $vmValues) {
    # Haal de huidige tijd op in het formaat HH:mm
    $currentTime = Get-Date -Format "HH:mm"

    # Check als de huidige tijd tussen de start- en stoptijd ligt
    if ($currentTime -ge $vm.StartTime -and $currentTime -le $vm.StopTime) {
        if ($vm.PowerState -ne "VM running") {
            # Als de VM niet draait, start deze dan
            Write-Host "Starting VM: $($vm.Name)" -ForegroundColor Green
            Start-AzVM -ResourceGroupName $resourceGroup -Name $vm.Name
            $vm | Add-Member -NotePropertyName "Status" -NotePropertyValue "Started VM"
        }
    #
    } else {
        if ($vm.PowerState -eq "VM running") {
            # Als de VM draait, stop deze dan
            Write-Host "Stopping VM: $($vm.Name)" -ForegroundColor Red
            Stop-AzVM -ResourceGroupName $resourceGroup -Name $vm.Name -Force
            $vm | Add-Member -NotePropertyName "Status" -NotePropertyValue "Stopped VM"
        }
    }
}

# output van de VM's met de status in tabelvorm
$vmValues | Format-Table -Property Name, StartTime, StopTime, PowerState, Status -AutoSize
