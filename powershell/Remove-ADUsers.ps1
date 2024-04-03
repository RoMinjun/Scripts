# Script made by Romin Kleeman

# Uitlezen van CSV file
$users = Get-ADUser -Filter * -Properties samaccountname, logoncount | Where-Object { $_.logoncount -eq 0 } | Select-Object samaccountname

# Displayen van de gebruikers die verwijderd gaan worden (elke op een new line)
$users | % { Write-Host $_.samaccountname }

# Displayen van het aantal gebruikers dat wordt verwijderd
Write-Host "`nAantal gebruikers dat nog nooit ingelogd en verwijderd worden: $($users.Count)"

# De prompt voor de gebruiker om te bevestigen dat de gebruikers verwijderd moeten worden
$choice = Read-Host -Prompt "Weet je het zeker dat je de gebruikers wilt verwijderd? (Y/N)"

if ($choice -eq "Y") {
    $removedUsers = @()
    $notRemovedUsers = @()

    foreach ($user in $users) {
        try {
            # Aanmaken van gebruiker, account inschakelen en gebruiker dwingen om het standaard wachtwoord te wijzigen bij inloggen
            Remove-ADUser $user.samaccountname -Confirm:$false
            Write-Host "Gebruikersaccount $($user.samaccountname) is succesvol verwijderd"
            $removedUsers += $user.samaccountname
        } catch {
            Write-Host "Gebruikersaccount $($user.samaccountname) kon niet verwijderd worden" -ForegroundColor Red
            $notRemovedUsers += $user.samaccountname
        }
    }

    # Verwijderde en niet verwijderde accounts displayen
    Write-Host "`nVerwijderde accounts:"
    $removedUsers | % { Write-Host $_ }

    Write-Host "`nAccounts waarvoor verwijderen niet gelukt is:"
    $notRemovedUsers | % { Write-Host $_ }

} else {
    Write-Host "Script aborted by user."
}
