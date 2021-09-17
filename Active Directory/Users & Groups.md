**Vous trouverez dans cette page des exemples de requète contruite pour des besoins spécifiques**

- [Récupérer la listes des Managers](#récupérer-la-listes-des-managers)
- [Exporter en csv les utilisateurs d'un groupe Azure AD](#exporter-en-csv-les-utilisateurs-dun-groupe-azure-ad)
- [Mettre à jour les attributs de certains comptes Azure AD](#mettre-à-jour-les-attributs-de-certains-comptes-azure-ad)
- [Créer un compte invité sans message d'invitation via Graph Explorer](#créer-un-compte-invité-sans-message-dinvitation-via-graph-explorer)


# Récupérer la listes des Managers

    $ManagerList = @()
    Get-AzureADUser -All $True | Where-Object {($_.Mail -ne '') -and ($_.Mail -like "*@MyDomain.region") -and ($_.UserPrincipalName -like "*@MyDomain.region") -and ($_.AccountEnabled -eq $True)} | ForEach-Object {$Manager = $_ |Get-AzureADUserManager; $ManagerList += $Manager}
    $ManagerList | Select -Unique

# Exporter en csv les utilisateurs d'un groupe Azure AD

    Get-AzureADGroup -ALL $True | Where-Object {$_.DisplayName -like "*WORD*TO*FIND*"} | %{$CSVName=$_.DisplayName + ".csv";Get-AzureADGroupMember -ObjectId $_.ObjectId | Select Mail | Export-csv $CSVName}

# Mettre à jour les attributs de certains comptes Azure AD

    Get-AzureADUser | Where-Object {$_.FacsimileTelephoneNumber -eq 'MaRecherche'} | ForEach-Object {Set-AzureADUser -ObjectId $_.ObjectId -PhysicalDeliveryOfficeName 'NewValue' -FacsimileTelephoneNumber 'NewValue'}

# Créer un compte invité sans message d'invitation via Graph Explorer

Se connecter à l'outil graph explorer et s'authentifier (à gauche) avec le compte ayant les droits nécessaire sur le tenant.

https://developer.microsoft.com/en-us/graph/graph-explorer

La requète doit être de type POST avec l'api suivante "https://graph.microsoft.com/v1.0/invitations"


Le request body doit contenir au minimum les éléments suivants si on veut que le compte est un Display Name et que l'utilisateur soit redirigé automatiquement vers un site SharePoint spécifique:

    {
    "invitedUserDisplayName": "Prénom Nom",
    "invitedUserEmailAddress": "AdresseEmailInvité",
    "sendInvitationMessage": false,
    "inviteRedirectUrl": "https://xxxxxx.sharepoint.com/sites/SiteVersLequelJeVeuxRedirigéMonIvité"
    } 
