# Quelques exemples de modifcation en masse de table de routage
## Ajouts d'une ou plusieurs routes

On récupère les tables de routage qui nous intéresse :

     # Get route to update with some filters on reoute table name
     $MyRouteTableToUpdate = Get-AzRouteTable -ResourceGroupName MyRessourceGroupeName | Where-Object {($_.Name -like "*PartOfNameToFind*") -and ($_.Name -notlike "*PartOfNameToDontFind*")}

On met à jour les tables de routages avec une ou plus routes

     # Update route table with on or more routes
     $MyRouteTableToUpdate | ForEach-Object {Add-AzRouteConfig -Name "YourRouteName1" -AddressPrefix X.X.X.X/X -NextHopType "YourHopType" -NextHopIpAddress X.X.X.X -RouteTable $_| Set-AzRouteTable;Add-AzRouteConfig -Name "YourRouteName2" -AddressPrefix X.X.X.X/X -NextHopType "YourHopType" -NextHopIpAddress X.X.X.X -RouteTable $_| Set-AzRouteTable}

## Suppression d'une ou plusieurs routes

On récupère les tables de routage qui nous intéresse :

     # Get route to update with some filters on reoute table name
     $MyRouteTableToUpdate = Get-AzRouteTable -ResourceGroupName MyRessourceGroupeName | Where-Object {($_.Name -like "*PartOfNameToFind*") -and ($_.Name -notlike "*PartOfNameToDontFind*")}

On supprime une ou plusieurs routes de nos tables de routages

    # Delete one or more route from route tables
    $MyRouteTableToUpdate | ForEach-Object {Remove-AzRouteConfig -Name "YourRouteName1" -RouteTable $_| Set-AzRouteTable;Remove-AzRouteConfig -Name "YourRouteName2" -RouteTable $_| Set-AzRouteTable}