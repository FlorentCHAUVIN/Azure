# Quelques requètes contruite pour des besoins spécifiques

## Récupérer la listes des Managers

    $ManagerList = @()
    Get-AzureADUser -All $True | Where-Object {($_.Mail -ne '') -and ($_.Mail -like "*@MyDomain.region") -and ($_.UserPrincipalName -like "*@MyDomain.region") -and ($_.AccountEnabled -eq $True)} | ForEach-Object {$Manager = $_ |Get-AzureADUserManager; $ManagerList += $Manager}
    $ManagerList | Select -Unique

## Exporter en csv les utilisateurs d'un groupe Azure AD

    Get-AzureADGroup -ALL $True | Where-Object {$_.DisplayName -like "*WORD*TO*FIND*"} | %{$CSVName=$_.DisplayName + ".csv";Get-AzureADGroupMember -ObjectId $_.ObjectId | Select Mail | Export-csv $CSVName}

## Mettre à jour les attribut de certains comptes Azure AD

    Get-AzureADUser | Where-Object {$_.FacsimileTelephoneNumber -eq 'MaRecherche'} | ForEach-Object {Set-AzureADUser -ObjectId $_.ObjectId -PhysicalDeliveryOfficeName 'NewValue' -FacsimileTelephoneNumber 'NewValue'}