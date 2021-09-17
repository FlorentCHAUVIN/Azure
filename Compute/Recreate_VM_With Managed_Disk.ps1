#Set variables
$mySubscriptionId = "MySubscriptionId"
$loc = 'MyAzureRegion'
$rgName = 'MyVMResourceGroupName'
$vmName = 'MyVmName'
$vmSize = 'MyVmSize'
$networkinterfaceName = 'MyNetworkInterfaceName' #IP will be assigned dynamically by Azure, don't forget to set it after creation if needed
$vnetName = 'MyVnetName'
$rgvnetName = 'MyVNetResourceGroupName'
$subnetName = 'MysubnetName'
$osType = "LinuxORWindows"
#osDiskName - Get-AzDisk for name
$osDiskName = 'MyOSDiskName'
$dataDiskName = 'IfNeededMyDataDiskName'
#AvailabilitySetName - Get-AzAvailabilitySet for name
$AvailabilitySetName = 'IfNeededMyAvailabilitySetName'
$BootDiagnosticStorageAccountName = "IfNeededBootDiagnosticStorageAccountName"


#login to Azure account
Login-AzAccount
Select-AzSubscription -Subscription $mySubscriptionId
 
#Clean up and remove VM & nic
Remove-AzVM -ResourceGroupName  $rgname –Name $vmName -Force
Remove-AzNetworkInterface –Name $networkinterfacename -ResourceGroup $rgname -force
 
#Create new network interface and set NicId value 
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgvnetName -Name $vnetName
$subnetId = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
$subnetId = $subnetId.Id
$nic = New-AzNetworkInterface -Name $networkinterfaceName -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId
$nic1 = Get-AzNetworkInterface -Name $networkinterfaceName -ResourceGroupName $rgname;
$nic1Id = $nic1.Id;
 
#Get AvailabilitySetId, set AvailabilitySetId value and add to $vm config
If(![string]::IsNullOrWhiteSpace($AvailabilitySetName))
{
    $AvailabilitySetId = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name ($AvailabilitySetName)
    $AvailabilitySetId = $AvailabilitySetId.Id
    $vm = New-AzVMConfig -vmName $vmName -vmSize $vmSize -AvailabilitySetId $AvailabilitySetId
}
else
{
    $vm = New-AzVMConfig -vmName $vmName -vmSize $vmSize
}

 
#Get ManagedDiskId, set ManagedDiskId and add to $vm config
#Recreate new VM using same OSDisk, new network interface
$ManagedDiskId = Get-AzDisk -ResourceGroupName $rgname -DiskName $osDiskName
$ManagedDiskId = $ManagedDiskId.Id
If(![string]::IsNullOrWhiteSpace($BootDiagnosticStorageAccountName))
{
    If($osType -eq "Linux")
    {
        $vm = Set-AzVMOSDisk -VM $vm -name $osDiskName -CreateOption attach -Linux -ManagedDiskId $ManagedDiskId
    }
    ElseIf($osType -eq "Windows")
    {
        $vm = Set-AzVMOSDisk -VM $vm -name $osDiskName -CreateOption attach -Windows -ManagedDiskId $ManagedDiskId
    }
    else 
    {
        Write-Host "OS Type not recognized" -ForegroundColor Red
        Break    
    }
}
else
{
    If($osType -eq "Linux")
    {
        $vm = Set-AzVMOSDisk -VM $vm -name $osDiskName -CreateOption attach -Linux -ManagedDiskId $ManagedDiskId --boot-diagnostics-storage $BootDiagnosticStorageAccountName
    }
    ElseIf($osType -eq "Windows")
    {
        $vm = Set-AzVMOSDisk -VM $vm -name $osDiskName -CreateOption attach -Windows -ManagedDiskId $ManagedDiskId --boot-diagnostics-storage $BootDiagnosticStorageAccountName
    }
    else 
    {
        Write-Host "OS Type not recognized" -ForegroundColor Red
        Break    
    }
}
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic1Id;

#Add Data Disk
If(![string]::IsNullOrWhiteSpace($dataDiskName))
{
    $disk = Get-AzDisk -ResourceGroupName $rgName -DiskName $dataDiskName 
    $vm = Add-AzVMDataDisk -CreateOption Attach -Lun 0 -VM $vm -ManagedDiskId $disk.Id
}

#Create VM
New-AzVM -ResourceGroupName $rgname -Location $loc -VM $vm -Verbose