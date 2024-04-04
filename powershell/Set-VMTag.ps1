# Script by Romin Kleeman (531630)
# Controleer of de Az-module is geïnstalleerd, zo niet installeer deze dan
if (!(Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Force
}

# Importeer de Az-module om de cmdlets te kunnen gebruiken
Import-Module Az

# Functie om een tijd in te voeren en te valideren (24uurs formaat)
function Get-ValidatedTime {
    param(
        [string]$prompt
    )

    do {
        $time = Read-Host $prompt
    } while ($time -notmatch "^([01]\d|2[0-3]):([0-5]\d)$")
    return $time
}

# Functie om standaard start- en stoptijden op te vragen
function Get-DefaultTime {
    $defaultStartTime = Get-ValidatedTime "Geef de standaard starttijd op (HH:mm)"
    $defaultStopTime = Get-ValidatedTime "Geef de standaard stoptijd op (HH:mm)"
    return $defaultStartTime, $defaultStopTime
}


# Functie om de start- en stoptijd voor een VM op te vragen
function Get-VMTime {
    param([PsCustomObject]$vm)
    $startTime = Get-ValidatedTime "Geef de starttijd op voor VM $($vm.Name) (HH:mm)"
    $stopTime = Get-ValidatedTime "Geef de stoptijd op voor VM $($vm.Name) (HH:mm)"
    return $startTime, $stopTime
}

# Functie om tags toe te voegen aan een VM
function Set-VMTag {
    param(
        [Parameter(Mandatory=$true)]
        [PsCustomObject]$vm,

        [Parameter(Mandatory=$true)]
        [ValidatePattern("^([01]\d|2[0-3]):([0-5]\d)$")] # Valideren van de tijd in het formaat HH:mm
        [string]$startTime,

        [Parameter(Mandatory=$true)]
        [ValidatePattern("^([01]\d|2[0-3]):([0-5]\d)$")] # Valideren van de tijd in het formaat HH:mm
        [string]$stopTime
    )
    # Ophalen van bestaande tags van de VM
    $tags = (Get-AzResource -ResourceId $vm.Id).Tags

    # Toevoegen of bijwerken van start- en stoptijd tags
    $tags["StartTime"] = $startTime
    $tags["StopTime"] = $stopTime

    # Tags toevoegen aan de VM
    Set-AzResource -ResourceId $vm.Id -Tag $tags -Force | Out-Null
}

# Functie om tags op te halen van een VM
function Get-VMTags {
    param([string]$resourceGroup)
    $vms = Get-AzVM -ResourceGroupName $resourceGroup
    $vmTags = foreach ($vm in $vms) {
        $tags = (Get-AzResource -ResourceId $vm.Id).Tags
        [PSCustomObject]@{
            "Name" = $vm.Name
            "Tags" = $tags
        }
    }
    return $vmTags
}

# Ophalen van de resource group, standaard start- en stoptijden en of deze gebruikt moeten worden
$resourceGroup = Read-Host "Geef de naam van de resourcegroep op"
$defaultStartTime, $defaultStopTime = Get-DefaultTime

$useDefaultTime = Read-Host "Wil je de standaard start- en stoptijd gebruiken? (y/n)"

# Als de gebruiker niet kiest voor standaard start- en stoptijden, vraag deze dan per VM
if ($useDefaultTime -eq 'y') {
    $vms = Get-AzVM -ResourceGroupName $resourceGroup
    foreach ($vm in $vms) {
        Set-VMTag -vm $vm -startTime $defaultStartTime -stopTime $defaultStopTime
    }
} else {
    $vms = Get-AzVM -ResourceGroupName $resourceGroup
    foreach ($vm in $vms) {
        $startTime, $stopTime = Get-VMTime -vm $vm
        Set-VMTag -vm $vm -startTime $startTime -stopTime $stopTime
    }
}

# Haal de tags op van de VM's in de resource group en geef deze weer in een tabel
$vmTags = Get-VMTags -resourceGroup $resourceGroup
$vmTags | Format-Table -AutoSize
