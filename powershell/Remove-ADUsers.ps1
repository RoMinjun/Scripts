# Script made by Romin Kleeman

# Ophalen van alle gebruikers die nog nooit hebben ingelogd
$users = Get-ADUser -Filter * -Properties samaccountname, logoncount | Where-Object { $_.logoncount -eq 0 } | Select-Object samaccountname

# Displayen van de gebruikers die verwijderd gaan worden
Write-Host $users

# Displayen van het aantal gebruikers dat wordt verwijderd
Write-Host "Aantal gebruikers dat nog nooit ingelogd en verwijderd worden: $($users.Count)"

# De prompt voor de gebruiker om te bevestigen dat de gebruikers verwijderd moeten worden
$choice = Read-Host -Prompt "Weet je het zeker dat je de gebruikers wilt verwijderd? (Y/N)"

if ($choice -eq "Y") {
    $removedUsers = @()
    $notRemovedUsers = @()

    foreach ($user in $users) {
        try {
            # Verwijderen van gebruikers account en toevoegen aan array
            Remove-ADUser $user.samaccountname
            Write-Host "Gebruikersaccount $($user.samaccountname) is succesvol verwijderd"
            $removedUsers += $user.samaccountname
        } catch {
            Write-Host "Gebruikersaccount $($user.samaccountname) kon niet verwijderd worden" -ForegroundColor Red
            $notRemovedUsers += $user.samaccountname
        }
    }

    # Aanmaken van bestanden voor verwijderde en niet verwijderde accounts
    $removedUsers | Out-File -FilePath "verwijderde-accounts.txt"
    $notRemovedUsers | Out-File -FilePath "niet-verwijderde-accounts.txt"
} else {
    Write-Host "Script aborted by user."
}
