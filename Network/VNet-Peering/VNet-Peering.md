- [Création de peering entre deux VNets situés dans des abonnements/tenants différents](#création-de-peering-entre-deux-vnets-situés-dans-des-abonnementstenants-différents)
  - [Procédure avec compte utilisateur en invité](#procédure-avec-compte-utilisateur-en-invité)
  - [Procédure avec SERVICE PRINCIPALE](#procédure-avec-service-principale)
    - [Azure PowerShell example :](#azure-powershell-example-)
    - [Azure CLI Example](#azure-cli-example)
    - [ARM REST API Example](#arm-rest-api-example)

# Création de peering entre deux VNets situés dans des abonnements/tenants différents

## Procédure avec compte utilisateur en invité

* Get the id for myVnetA.
  
    `vnetAId=$(az network vnet show --resource-group 'myVnetAResourceGroup' --name 'myVnetAName' --query id --out tsv)`

* Peer myVNetA to myVNetB.

    `az network vnet peering create --name 'MyPeeringName' --resource-group 'myVnetBResourceGroup' --vnet-name 'myVnetBName' --remote-vnet-id '/subscriptions/MyVnetASubscriptionID/resourceGroups/myVnetAResourceGroup/providers/Microsoft.Network/virtualNetworks/myVnetAName' --allow-vnet-access`

Some docs about peering:

https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering

https://docs.microsoft.com/fr-fr/azure/virtual-network/create-peering-different-subscriptions

https://docs.microsoft.com/fr-fr/azure/virtual-network/virtual-network-manage-peering#permissions

https://techcommunity.microsoft.com/t5/Azure-Active-Directory-B2B-Ideas/Invite-guest-user-without-a-mailbox/idi-p/72774

If invited user don't have mail box. You just want the user status to change from "invited" to a valid user AND the other user account is from a standard Azure Active Directory tenant (e.g. a work account, that can be linked with B2B, e.g. also ending in ".onmicrosoft.com") AND users are allowed to see your azure portal then you can proceed with the following steps:

1. Invite the guest in AAD, as if she has a valid e-mail.
2. User will then be listed with status "invited" in AAD.
3. Send the user the follwing url to click (e.g. via different email address): https://portal.azure.com/#@[your aad tenant name].onmicrosoft.com
e.g. for tenant mytenant.onmicrosoft.com, send the url:
https://portal.azure.com/#@mytenant.onmicrosoft.com
4. Once the user clicks on this link and logs in with his non-email-account, she has to confirm the terms and conditions.
After confirmation, user will show up as valid user in your AAD.

## Procédure avec SERVICE PRINCIPALE

Source :
https://medium.com/@ArsenVlad/azure-vnet-peering-across-azure-active-directory-tenants-using-service-principal-authentication-13c52d3190ab


1. Mark Azure AD Application as Multi-Tenanted
In the 1st Azure AD tenant, create Azure AD application and set its Settings->Properties for multi-tenanted = Yes.
Record application id (client_id) and key (client_secret).
2. Create Service Principal from Application
In the 2nd Azure AD tenant, consent to the multi-tenanted application so that corresponding Service Principal is created in the 2nd tenant.
Consent URL example
https:// login.microsoftonline.com/TENANT2_ID/oauth2/authorize?client_id=CLIENT_ID_OF_MULTI_TENATED_APPLICATION&response_type=code


### Azure PowerShell example :

    $applicationId = "CLIENT_ID"
    $key = "CLIENT_SECRET| ConvertTo-SecureString -AsPlainText -Force  
    $cred = New-Object -TypeName PSCredential -ArgumentList $applicationId, $key
    Clear-AzureRmContext
    Connect-AzureRMAccount -ServicePrincipal -Credential $cred -Tenant "TENANT1_ID"
    Get-AzureRmResourceGroup
    $vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName "vnetpeer1" -Name "vnetpeer1"
    Add-AzureRmVirtualNetworkPeering -Name 'peer1-peer2' -VirtualNetwork $vnet1  -RemoteVirtualNetworkId "/subscriptions/SUBSCRIPTION2_ID/resourceGroups/vnetpeer2/providers/Microsoft.Network/virtualNetworks/vnetpeer2" -Debug
    Connect-AzureRMAccount -ServicePrincipal -Credential $cred -Tenant "TENANT2_ID"
    Get-AzureRmResourceGroup
    $vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName "vnetpeer2" -Name "vnetpeer2"
    Add-AzureRmVirtualNetworkPeering -Name 'peer2-peer1' -VirtualNetwork $vnet2  -RemoteVirtualNetworkId "/subscriptions/SUBSCRIPTION1_ID/resourceGroups/vnetpeer1/providers/Microsoft.Network/virtualNetworks/vnetpeer1"


### Azure CLI Example

    #Azure CLI login using service principal authentication
    az account clear
    az login --service-principal -u "CLIENT_ID" -p "CLIENT_SECRET" --tenant "TENANT1_ID"
    az account get-access-token
    az login --service-principal -u "CLIENT_ID" -p "CLIENT_SECRET" --tenant "TENANT2_ID"
    az account get-access-token
    ## The following did not work properly in Azure CLI version 2.0.50 when using multi-tenanted application service principal
    ## However, as of 2018-11-27, the issue is fixed in Azure CLI versions 2.0.52 and later via this pull request https://github.com/Azure/azure-cli/pull/7916
    az network vnet peering create --name vnet1-vnet2 --resource-group vnetpeer1 --vnet-name vnetpeer1 --remote-vnet "/subscriptions/SUBSCRIPTION2_ID/resourceGroups/vnetpeer2/providers/Microsoft.Network/virtualNetworks/vnetpeer2" --allow-vnet-access
    az network vnet peering create --name vnet2-vnet1 --resource-group vnetpeer2 --vnet-name vnetpeer2 --remote-vnet "/subscriptions/SUBSCRIPTION1_ID/resourceGroups/vnetpeer1/providers/Microsoft.Network/virtualNetworks/vnetpeer1" --allow-vnet-access  --allowForwardedTraffic


### ARM REST API Example

    # Create VNet Peering in Subscription 1
    curl -X PUT \
    'https://management.azure.com/subscriptions/SUBSCRIPTION1_ID/resourceGroups/vnetpeer1/providers/Microsoft.Network/virtualNetworks/vnetpeer1/virtualNetworkPeerings/peer1-peer2?api-version=2018-02-01' \
    -H 'Authorization: Bearer TENANT1_TOKEN' \
    -H 'Content-Type: application/json' \
    -H 'cache-control: no-cache' \
    -H 'x-ms-authorization-auxiliary: Bearer TENANT2_TOKEN' \
    -d '{ "properties": { "allowVirtualNetworkAccess": true, "allowForwardedTraffic": false, "allowGatewayTransit": false, "useRemoteGateways": false, "remoteVirtualNetwork": { "id": "/subscriptions/SUBSCRIPTION2_ID/resourceGroups/vnetpeer2/providers/Microsoft.Network/virtualNetworks/vnetpeer2" } } }'

    # Create VNet Peering in Subscription 2
    curl -X PUT \
    'https://management.azure.com/subscriptions/SUBSCRIPTION2_ID/resourceGroups/vnetpeer2/providers/Microsoft.Network/virtualNetworks/vnetpeer2/virtualNetworkPeerings/peer2-peer1?api-version=2018-02-01' \
    -H 'Authorization: Bearer TENANT2_TOKEN' \
    -H 'Content-Type: application/json' \
    -H 'cache-control: no-cache' \
    -H 'x-ms-authorization-auxiliary: Bearer TENANT1_TOKEN' \
    -d '{ "properties": { "allowVirtualNetworkAccess": true, "allowForwardedTraffic": false, "allowGatewayTransit": false, "useRemoteGateways": false, "remoteVirtualNetwork": { "id": "/subscriptions/SUBSCRIPTION1_ID/resourceGroups/vnetpeer1/providers/Microsoft.Network/virtualNetworks/vnetpeer1" } } }'