# Script made by Romin Kleeman

# Displayen van help text
Write-Host "Het script leest de gebruikersgegevens uit een CSV bestand en maakt de gebruikersaccounts aan in Active Directory."

# Uitlezen van CSV file
$users = Import-Csv -Path "gebruikers.csv" -Delimiter ","

# Displayen van het aantal gebruikers dat wordt aangemaakt
Write-Host "Aantal gebruikers dat wordt aangemaakt: $($users.Count)"

# De prompt voor de gebruiker om te bevestigen dat de gebruikers aangemaakt moeten worden
$choice = Read-Host -Prompt "Weet je het zeker dat je de gebruikers wilt aanmaken? (Y/N)"

# Default wachtwoord voor de gebruikers
$passwd = ConvertTo-SecureString -AsPlainText -Force "Welkom123!"

if ($choice -eq "Y") {
    $createdCount = 0
    $notCreatedCount = 0
    $createdUsers = @()
    $notCreatedUsers = @()

    foreach ($user in $users) {
        try {
            # Aanmaken van gebruiker, account inschakelen en gebruiker dwingen om het standaard wachtwoord te wijzigen bij inloggen
            New-ADUser -GivenName $user.firstname -Surname $user.lastname -SamAccountName $user.samaccountname -UserPrincipalName "$($user.samaccountname)@rominkleeman.local" -AccountPassword $passwd -Enabled $true -ChangePasswordAtLogon $true
            Write-Host "Gebruikersaccount $($user.samaccountname) is succesvol aangemaakt"
            $createdCount++
            $createdUsers += $user.samaccountname
        } catch {
            Write-Host "Gebruikersaccount $($user.samaccountname) kon niet aangemaakt worden" -ForegroundColor Red
            $notCreatedCount++
            $notCreatedUsers += $user.samaccountname
        }
    }

    # Displayen van het aantal aangemaakte en niet aangemaakte accounts
    Write-Host "Aantal gemaakte accounts: $createdCount"
    Write-Host "Aantal accounts dat niet gemaakt kon worden: $notCreatedCount"

    # Aanmaken van bestanden voor aangemaakte en niet aangemaakte accounts
    $createdUsers | Out-File -FilePath "aangemaakte-accounts.txt"
    $notCreatedUsers | Out-File -FilePath "niet-aangemaakte-accounts.txt"
} else {
    Write-Host "Script aborted by user."
}
