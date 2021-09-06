#Set variables
$mySubscriptionId = "MySubscriptionId"
$loc = 'MyAzureRegion'
$rgName = 'MyVMResourceGroupName'
$vmName = 'MyVmName'
$vmSize = 'MyVmSize'
$networkinterfaceName = 'MyNetworkInterfaceName'
$vnetName = 'MyVnetName'
$rgvnetName = 'MyVNetResourceGroupName'
$subnetName = 'MysubnetName'
#osDiskName - Get-AzureRmDisk for name
$osDiskName = 'MyOSDiskName'
$dataDiskName = 'IfNeededMyDataDiskName'
#AvailabilitySetName - Get-AzureRmAvailabilitySet for name
$AvailabilitySetName = 'IfNeededMyAvailabilitySetName'


#login to Azure account
Login-AzureRmAccount
Select-AzureRmSubscription -Subscription $mySubscriptionId
 
#Clean up and remove VM & nic
Remove-AzureRmVM -ResourceGroupName  $rgname –Name $vmName -Force
Remove-AzureRmNetworkInterface –Name $networkinterfacename -ResourceGroup $rgname -force
 
#Create new network interface and set NicId value 
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgvnetName -Name $vnetName
$subnetId = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
$subnetId = $subnetId.Id
$nic = New-AzureRmNetworkInterface -Name $networkinterfaceName -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId
$nic1 = Get-AzureRmNetworkInterface -Name $networkinterfaceName -ResourceGroupName $rgname;
$nic1Id = $nic1.Id;
 
#Get AvailabilitySetId, set AvailabilitySetId value and add to $vm config
If(![string]::IsNullOrWhiteSpace($AvailabilitySetName))
{
    $AvailabilitySetId = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name ($AvailabilitySetName)
    $AvailabilitySetId = $AvailabilitySetId.Id
    $vm = New-AzureRmVMConfig -vmName $vmName -vmSize $vmSize -AvailabilitySetId $AvailabilitySetId
}
else
{
    $vm = New-AzureRmVMConfig -vmName $vmName -vmSize $vmSize
}

 
#Get ManagedDiskId, set ManagedDiskId and add to $vm config
#Recreate new VM using same OSDisk, new network interface and setting license type to AHUB for Windows Server
#Here it's a Linux sample
$ManagedDiskId = Get-AzureRmDisk -ResourceGroupName $rgname -DiskName $osDiskName
$ManagedDiskId = $ManagedDiskId.Id
$vm = Set-AzureRmVMOSDisk -VM $vm  -name $osDiskName -CreateOption attach -Linux -ManagedDiskId $ManagedDiskId 
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic1Id;

#Add Data Disk
If(![string]::IsNullOrWhiteSpace($dataDiskName))
{
    $disk = Get-AzureRMDisk -ResourceGroupName $rgName -DiskName $dataDiskName 
    $vm = Add-AzureRmVMDataDisk -CreateOption Attach -Lun 0 -VM $vm -ManagedDiskId $disk.Id
}

#Create VM
New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $vm -Verbose