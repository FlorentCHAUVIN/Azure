#*===============================================================================
# Filename : Azure-Deploy-VM.ps1
# Version : 1.1.0
#*===============================================================================
# Author : Florent CHAUVIN
# Company: LINKBYNET
#*===============================================================================
# Created: FCH - 22 december 2015
# Modified: FCH - 10 may 2016
#*===============================================================================
# Description :
# Script to deploy VM from csv configuration file
# Virtual Network and Subnet must be created before
#*===============================================================================

#*===============================================================================
# Variables Configuration
#*===============================================================================

#Path for configuration file
$Global:ConfigFile = ".\Azure-Deploy-VM_Config-MAJIKAN-PREPROD.csv"
#Path for script logging
$Global:Log = ".\" + (get-date -uformat '%Y%m%d-%H%M') + "-Azure-Deploy-VM.log"
#Number of header in configuration file (Verify if csv import is done correctly )
$Global:ConfigFileHeaderNumber = 23
#Debug mode, use to see all variables configuration.
$Global:DebugMode = $Failed
$StartTime = (Get-Date)

#*===============================================================================
# Main
#*===============================================================================

Start-Transcript $Log
if (!$?)
{
	Write-Host "Transcript cannot start because path is unavailable" -Fore Red
	$TranscriptStatus= "Error"
}

Write-host "============================================================================" -fore Yellow
Write-host "==          Script to deploy VMs from configuration file (csv)            ==" -fore Yellow
Write-host "============================================================================" -fore Yellow
Write-host "|-> Launch this script in last version of Microsoft Azure Powershell (ARM)"
Write-host "|-> Login to subscription (Authentication pop-up)" -fore Yellow
Login-AzureRmAccount

Write-host "|-> Get default Azure susbscription Id" -fore Yellow
$subscriptionId = (Get-AzureRMSubscription).SubscriptionId

Write-host "|-> Import VMs configuration (csv)" -fore Yellow
If((Get-Content $ConfigFile) -match ",")
{
	$VMsConfig = import-csv $ConfigFile -delimiter ","
}
ElseIf((Get-Content $ConfigFile) -match ";")
{
	$VMsConfig = import-csv $ConfigFile -delimiter ";"
}
Else
{
	$VMsConfig = import-csv $ConfigFile -UseCulture
}

Write-host "|-> Check if VMs configuration file (csv) have correct number of header" -fore Yellow
$VMsConfigHeader = $VMsConfig | Get-Member | Where-object{$_.MemberType -eq "NoteProperty"}
$VMsConfigHeaderCount = $VMsConfigHeader.Count
If($VMsConfigHeader.Count -eq $ConfigFileHeaderNumber)
{
	Write-Host "|-> We get correct number of header ($ConfigFileHeaderNumber)" -fore Green
}
Else
{
	Write-Host "|-> There is an error when loading rule configuration, we get $VMsConfigHeaderCount header instead of $ConfigFileHeaderNumber" -fore Red
	Exit
}

Foreach ($VM in $VMsConfig)
{

	Try
	{
		#Define VM variables
		$rgName=$VM.VMResourceGroupName
		$locName=$VM.VMLocationName
		$saName=$VM.VMStorageAccountName
		$saType=$VM.VMStorageAccountType
		$saRgName=$VM.VMStorageResourceGroupName
		$coName=$VM.VMStorageAccountContainerName
		$vnetName=$VM.VirtualNetworkName
		$SubnetName=$VM.VMSubnetName
		$nicName=$VM.VMNetworkCardName
		$nicStaticPrivateIP=$VM.VMStaticPrivateIP
		$pipName=$VM.VMPublicIPName
		$pipDomLab=$VM.VMPublicIPDomainLabel
		$pipAllocMeth=$VM.VMPublicIPAllocationMethod
		$vmName=$VM.VMName
		$vmSize=$VM.VMSize
		$avName=$VM.VMAvailabiltySetName
		$pubName=$VM.VMPublisherName
		$offerName=$VM.VMOfferName
		$skuName=$VM.VMSkuName
		$OSdiskName=$VM.VMOSDiskName
		$DatadiskSize=$VM.VMDataDiskSize
		$DatadiskLabel=$VM.VMDataDiskLabel
		$DatadiskName=$VM.VMDataDiskVhdName
	}
	Catch
	{
		$errText = $error[0].Exception.Message
		Write-Host "|--> There is an error when loading rule configuration, verify you csv file: $errText" -fore Red
		Exit
	}
	
	Write-Host "----------------------------------------------------------------------------" -fore Yellow
	Write-host "-- Deployment of VM "$VM.VMName -fore Yellow
	Write-Host "----------------------------------------------------------------------------" -fore Yellow
	Write-host "|-> VM Configuration summary:" -fore White
	$VM
	Write-Host "----------------------------------------------------------------------------" -fore Yellow
	
	Write-host "|-> check if VM $vmName exist" -fore Yellow
	
	If((Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName -ErrorAction SilentlyContinue) -eq $Null)
	{
		Write-host "|--> VM $vmName don't exist" -fore Green
	}
	Else
	{
		Write-host "|--> VM $vmName already exist" -fore Red
		Continue
	}

	Write-host "|-> Check if VNet $vnetName exist" -fore Yellow
	$VNet = Get-AzureRmVirtualNetwork | ?{$_.name -eq $vnetName}
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: vnet="
		$vnet
	}	
	If ($VNet -eq $null)
	{
		Write-host "|--> VNet $vnetName don't exist, Virtual Network must be created before use this script." -fore Red
		Continue
	}
	Else
	{
		Write-host "|--> VNet $vnetName exist." -fore Green
	}

	Write-host "|-> Check if Subnet $RuleSubnetName exist" -fore Yellow
	$Subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VNet | ?{$_.Name -eq $SubnetName}
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: Subnet="
		$Subnet
	}
	If ($Subnet -eq $null)
	{
		Write-host "|--> Subnet $SubnetName don't exist, Subnet must be created before use this script." -fore Red
		Continue
	}
	Else
	{
		Write-host "|--> Subnet $SubnetName exist." -fore Green
		$subnetId = $subnet.Id
	}	
	
	Write-host "|-> Check if Resource Group $rgName exist" -fore Yellow
	If((Get-AzureRmResourceGroup -Name $rgName) -eq $Null)
	{
		Write-host "|--> Create Resource Group $rgName" -fore Yellow
		New-AzureRmResourceGroup -Name $rgName -Location $locName
		If((Get-AzureRmResourceGroup -Name $rgName -ErrorAction SilentlyContinue) -ne $Null)
		{
			Write-host "|--> Resource Group $rgName succesfully created" -fore Green
		}
		Else
		{
			Write-host "|--> Resource Group $rgName creation failed" -fore Red
			Continue
		}
	}
	Else
	{
		Write-host "|--> Resource Group $rgName exist" -fore Green
	}

	Write-host "|-> Check if Storage Account $saName exist" -fore Yellow
	$storageAcc=Get-AzureRMStorageAccount | ?{$_.StorageAccountName -eq $saName}
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: storageAcc="
		$storageAcc
	}
	If($storageAcc -eq $Null)
	{
		Write-host "|--> Create Storage Account $saName" -fore Yellow
		If(($saRgName -eq $null) -or ($saRgName -eq ""))
		{
			$saRgName = $rgName
		}
		Else
		{
			Write-host "|--> Check if Resource Group $saRgName exist" -fore Yellow
			If((Get-AzureRmResourceGroup -Name $saRgName) -eq $Null)
			{
				Write-host "|---> Create Resource Group $saRgName" -fore Yellow
				New-AzureRmResourceGroup -Name $saRgName -Location $locName
				If((Get-AzureRmResourceGroup -Name $saRgName) -ne $Null)
				{
					Write-host "|---> Resource Group $saRgName succesfully created" -fore Green
				}
				Else
				{
					Write-host "|---> Resource Group $saRgName creation failed" -fore Red
					Continue
				}
			}
			Else
			{
				Write-host "|--> Resource Group $saRgName exist" -fore Green
			}
		}
		If ($DebugMode -eq $True)
		{
			Write-host "|-> DEBUG: saRgName="
			$saRgName
		}
		New-AzureRMStorageAccount -Name $saName -Location $locName -ResourceGroupName $saRgName -Type $saType
		$storageAcc=Get-AzureRMStorageAccount | ?{$_.StorageAccountName -eq $saName}
		If($storageAcc -ne $Null)
		{
			Write-host "|--> Storage Account $saName succesfully created" -fore Green
		}
		Else
		{
			Write-host "|--> Storage Account $saName creation failed" -fore Red
			Continue
		}
	}
	Else
	{
		Write-host "|--> Storage Account $saName exist" -fore Green
	}
	
	Write-host "|-> Check if Storage Account Container $coName exist" -fore Yellow
	If(($saRgName -eq $null) -or ($saRgName -eq ""))
	{
		$saRgName = $rgName
	}
	$storageAcc=Get-AzureRMStorageAccount | ?{$_.StorageAccountName -eq $saName}
	$storageAccKey=(Get-AzureRmStorageAccountKey -ResourceGroupName $saRgName -Name $saName).key1
	If($storageAccKey -eq $null)
	{
		$storageAccKey=(Get-AzureRmStorageAccountKey -ResourceGroupName $saRgName -Name $saName).value | select -first 1
	}
	$ctx=New-AzureStorageContext -StorageAccountName $saName -StorageAccountKey $storageAccKey
	$Co=Get-AzureStorageContainer -context $ctx -Name $coName -ErrorAction SilentlyContinue
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: saRgName="
		$saRgName
		Write-host "|-> DEBUG: storageAcc="
		$storageAcc
		Write-host "|-> DEBUG: storageAccKey="
		$StorageAccKey
		Write-host "|-> DEBUG: ctx="
		$ctx
		Write-host "|-> DEBUG: Co="
		$Co
	}
	If($Co -eq $Null)
	{
		Write-host "|--> Create Storage Account Container $coName" -fore Yellow
		New-AzureStorageContainer -Name $coName -Context $ctx -Permission Blob
		$storageAcc=Get-AzureRMStorageAccount | ?{$_.StorageAccountName -eq $saName}
		$storageAccKey=(Get-AzureRmStorageAccountKey -ResourceGroupName $saRgName -Name $saName).key1
		If($storageAccKey -eq $null)
		{
			$storageAccKey=(Get-AzureRmStorageAccountKey -ResourceGroupName $saRgName -Name $saName).value | select -first 1
		}
		$ctx=New-AzureStorageContext -StorageAccountName $saName -StorageAccountKey $storageAccKey
		$Co=Get-AzureStorageContainer -context $ctx -Name $coName -ErrorAction SilentlyContinue		
		If($Co -ne $Null)
		{
			Write-host "|--> Storage Account Container $coName successfully created" -fore Green
		}
		Else
		{
			Write-host "|--> Storage Account Container $coName creation failed" -fore Red
			Continue
		}
	}
	Else
	{
		Write-host "|--> Container $coName exist" -fore Green
	}	
	
	
	Write-host "|-> Check if Network Card $nicName exist" -fore Yellow
	$nic=Get-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName  -ErrorAction SilentlyContinue
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: nic="
		$nic
	}
	If($nic -eq $null)
	{
		Write-host "|--> Create the Network Card $nicName" -fore Yellow
		If(($pipName -ne $null) -and ($pipName -ne ""))
		{
			Write-host "|--> Check if Public IP $pipName exist" -fore Yellow
			$pip=Get-AzureRMPublicIpAddress -Name $pipName -ResourceGroupName $rgName -ErrorAction SilentlyContinue	
			If($pip -eq $null)
			{
				Write-host "|---> Create Public IP $pipName " -fore Yellow
				$pip=New-AzureRMPublicIpAddress -Name $pipName -ResourceGroupName $rgName -DomainNameLabel $pipDomLab -Location $locName -AllocationMethod $pipAllocMeth
				$pip=Get-AzureRMPublicIpAddress -Name $pipName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
				If($pip -ne $null)
				{
					Write-host "|---> Public IP $pipName succesfully created" -fore Green
				}
				Else
				{
					Write-host "|---> Public IP $pipName creation failed" -fore Red
					Continue
				}
			}
			If ($DebugMode -eq $True)
			{
				Write-host "|-> DEBUG: pip="
				$pip
			}			
			$nic=New-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -PrivateIpAddress $nicStaticPrivateIP -SubnetId $subnetId -PublicIpAddressId $pip.Id
		}
		Else
		{
			$nic=New-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -PrivateIpAddress $nicStaticPrivateIP -SubnetId $subnetId
		}
		$nic=Get-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName -ErrorAction SilentlyContinue	
		If($nic -ne $null)
		{
			Write-host "|--> Network Card $nicName successfully created" -fore Green
		}
		Else
		{
			Write-host "|--> Network Card $nicName creation failed" -fore Red
			Continue
		}	
		
		If ($DebugMode -eq $True)
		{
			Write-host "|-> DEBUG: nic="
			$nic
		}
	}
	Else
	{
		Write-host "|--> Network Card $nicName exist" -fore Green
	}
	
		
	Write-host "|-> Set the VM name, VM size, and VM availability set if needed" -fore Yellow
	If(($avName -ne $null) -and ($avName -ne ""))
	{		
		Write-host "|-> Check if Availability Set $avName exist" -fore Yellow
		$avSet=Get-AzureRMAvailabilitySet -ResourceGroupName $rgName | ?{$_.Name -eq $avName}
		If($avSet -eq $Null)
		{
			Write-host "|--> Create Availability Set $avName" -fore Yellow
			$avSet=New-AzureRMAvailabilitySet -Name $avName -ResourceGroupName $rgName -Location $locName
			$avSet=Get-AzureRMAvailabilitySet -ResourceGroupName $rgName | ?{$_.Name -eq $avName}
			If($avSet -ne $Null)
			{
				Write-host "|--> Availability Set $avName succesfully created" -fore Green
			}
			Else
			{
				Write-host "|--> Availability Set $avName creation failed" -fore Red
				Continue
			}
		}
		Else
		{
			Write-host "|--> Availability Set $avName exist" -fore Green
		}
		$vmToCreate=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id
		If ($DebugMode -eq $True)
		{
			Write-host "|-> DEBUG: avSet="
			$avSet
			Write-host "|-> DEBUG: vmToCreate="
			$vmToCreate
		}		
	}
	Else
	{
		$vmToCreate=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize
		If ($DebugMode -eq $True)
		{
			Write-host "|-> DEBUG: vmToCreate="
			$vmToCreate
		}
	}
	
	Write-host "|-> Get the local administrator account" -fore Yellow
	$cred=Get-Credential -Message "|-> Type the name and password of the local administrator account for VM $vmName"
	
	Write-host "|-> Set VM Operating System, VM Credential and Provision VM Agent" -fore Yellow
	If($pubName -eq "MicrosoftWindowsServer")
	{
		$vmToCreate=Set-AzureRMVMOperatingSystem -VM $vmToCreate -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
	}
	Else
	{
		$vmToCreate=Set-AzureRMVMOperatingSystem -VM $vmToCreate -Linux -ComputerName $vmName -Credential $cred
	}
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: vmToCreate="
		$vmToCreate
	}
	
	Write-host "|-> Set VM Source image" -fore Yellow
	$vmToCreate=Set-AzureRMVMSourceImage -VM $vmToCreate -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: vmToCreate="
		$vmToCreate
	}
	
	Write-host "|-> Add the Network Card to VM configuration" -fore Yellow
	$vmToCreate=Add-AzureRMVMNetworkInterface -VM $vmToCreate -Id $nic.Id
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: vmToCreate="
		$vmToCreate
	}
	
	Write-host "|-> Set the VM OS disk name and Uri" -fore Yellow
	$storageAcc=Get-AzureRMStorageAccount | ?{$_.StorageAccountName -eq $saName}
	$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + $coName + "/" + $vmName+ "-" + $OSdiskName  + ".vhd"
	$osDiskUri=$osDiskUri.ToLower()
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: storageAcc="
		$storageAcc
		Write-host "|-> DEBUG: osDiskUri="
		$osDiskUri
	}
	
	If(($VM.VMDataDiskSize -ne $null) -and ($VM.VMDataDiskSize -ne ""))
	{
		Write-host "|-> Set VM data disk name and Uri" -fore Yellow
		$DatavhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + $coName + "/" + $vmName+ "-" + $DatadiskName  + ".vhd"
		$DatavhdURI=$DatavhdURI.ToLower()
		If ($DebugMode -eq $True)
		{
		Write-host "|-> DEBUG: storageAcc="
		$storageAcc
		Write-host "|-> DEBUG: DatavhdURI="
		$DatavhdURI
		}
		Write-host "|-> Add VM data disk" -fore Yellow
		Add-AzureRMVMDataDisk -VM $vmToCreate -Name $DatadiskLabel -DiskSizeInGB $DatadiskSize -VhdUri $DatavhdURI -CreateOption empty
	}

	Write-host "|-> Create the VM" -fore Yellow
	$vmToCreate=Set-AzureRMVMOSDisk -VM $vmToCreate -Name $OSdiskName -VhdUri $osDiskUri -CreateOption fromImage
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: vmToCreate="
		$vmToCreate
	}
	New-AzureRMVM -ResourceGroupName $rgName -Location $locName -VM $vmToCreate

	Remove-variable rgName -ErrorAction SilentlyContinue
	Remove-variable locName -ErrorAction SilentlyContinue
	Remove-variable saName -ErrorAction SilentlyContinue
	Remove-variable saType -ErrorAction SilentlyContinue
	Remove-variable coName -ErrorAction SilentlyContinue
	Remove-variable saRgName -ErrorAction SilentlyContinue
	Remove-variable storageAcc -ErrorAction SilentlyContinue
	Remove-variable storageAccKey -ErrorAction SilentlyContinue
	Remove-variable ctx -ErrorAction SilentlyContinue
	Remove-variable Co -ErrorAction SilentlyContinue
	Remove-variable vnetName -ErrorAction SilentlyContinue
	Remove-variable vnet -ErrorAction SilentlyContinue	
	Remove-variable Subnet -ErrorAction SilentlyContinue	
	Remove-variable SubnetName -ErrorAction SilentlyContinue
	Remove-variable subnetId -ErrorAction SilentlyContinue
	Remove-variable nic -ErrorAction SilentlyContinue
	Remove-variable nicName -ErrorAction SilentlyContinue
	Remove-variable nicStaticPrivateIP -ErrorAction SilentlyContinue
	Remove-variable pip -ErrorAction SilentlyContinue
	Remove-variable pipName -ErrorAction SilentlyContinue
	Remove-variable pipDomLab -ErrorAction SilentlyContinue
	Remove-variable pipAllocMeth -ErrorAction SilentlyContinue
	Remove-variable vmName -ErrorAction SilentlyContinue
	Remove-variable vmSize -ErrorAction SilentlyContinue
	Remove-variable avSet -ErrorAction SilentlyContinue
	Remove-variable avName -ErrorAction SilentlyContinue
	Remove-variable vmToCreate -ErrorAction SilentlyContinue
	Remove-variable pubName -ErrorAction SilentlyContinue
	Remove-variable offerName -ErrorAction SilentlyContinue
	Remove-variable skuName -ErrorAction SilentlyContinue
	Remove-variable cred -ErrorAction SilentlyContinue
	Remove-variable storageAcc -ErrorAction SilentlyContinue
	Remove-variable OSdiskName -ErrorAction SilentlyContinue
	Remove-variable osDiskUri -ErrorAction SilentlyContinue
	Remove-variable DatadiskSize -ErrorAction SilentlyContinue
	Remove-variable DatadiskLabel -ErrorAction SilentlyContinue
	Remove-variable DatavhdURI -ErrorAction SilentlyContinue
	Remove-variable DatavhdURI -ErrorAction SilentlyContinue
	Remove-variable vmToCreate -ErrorAction SilentlyContinue
	
}
$EndTime = (Get-Date)
$duration = [math]::round($(($EndTime-$StartTime).totalminutes),2)
Write-host "============================================================================" -Fore Yellow
Write-Host "|-> the process took "$duration" minutes"  -Fore White

if ($TranscriptStatus -ne "Error")
{
Stop-Transcript
}