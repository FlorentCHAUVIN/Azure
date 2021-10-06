#*===============================================================================
# Filename : Azure-Deploy-NSG-Rules.ps1
# Version : 1.0.0
#*===============================================================================
# Author : Florent CHAUVIN
#*===============================================================================
# Created: FCH - 3 january 2016
# Modified: FCH - 4 january 2016
#*===============================================================================
# Description :
# Script to deploy Network Security Group and rules
# Currently Resource Group, Virtual Network, Subnet must be created before
#*===============================================================================

#*===============================================================================
# Variables Configuration
#*===============================================================================

#Path for script logging
$Global:Log = ".\" + (get-date -uformat '%Y%m%d-%H%M') + "-Azure-Deploy-NSG-Rules.log"
#Path for configuration file
$Global:ConfigFile = ".\Azure-Deploy-NSG-Rules_Config-Client.csv"
#Number of header in configuration file (Verify if csv import is done correctly)
$Global:ConfigFileHeaderNumber = 15
#Enable request to remove all rules in Security Group
$Global:EnableRequestToRemoveAllRules = $False
#Debug mode, use to see all variables configuration.
$Global:DebugMode = $False
$StartTime = (Get-Date)

#*===============================================================================
# Main
#*===============================================================================

Try
{
	Start-Transcript $Log
}
Catch
{
	Stop-Transcript
	Start-Transcript $Log
	if (!$?)
	{
		Write-Host "Transcript cannot start because path is unavailable" -Fore Red
		$TranscriptStatus= "Error"
	}
}

Write-host "============================================================================" -fore Yellow
Write-host "==     Script to deploy NSG and rules from configuration file (csv)       ==" -fore Yellow
Write-host "============================================================================" -fore Yellow
Write-host "|-> Launch this script in last version of Microsoft Azure Powershell (ARM)" -fore Yellow
Write-host "|-> Login to subscription (Default command to adapt in script if needed)" -fore Yellow
Connect-AzAccount

Write-host "|-> Get default Azure susbscription Id" -fore Yellow
$subscriptionId = (Get-AzSubscription).SubscriptionId

Write-host "|-> Import NSG and rules configuration file (csv)" -fore Yellow
If((Get-Content $ConfigFile) -match ",")
{
	$RulesConfig = import-csv $ConfigFile -delimiter ","
}
ElseIf((Get-Content $ConfigFile) -match ";")
{
	$RulesConfig = import-csv $ConfigFile -delimiter ";"
}
Else
{
	$RulesConfig = import-csv $ConfigFile -UseCulture
}

Write-host "|-> Check if NSG and rules configuration file (csv) have correct number of header" -fore Yellow
$RulesConfigHeader = $RulesConfig | Get-Member | Where-object{$_.MemberType -eq "NoteProperty"}
$RulesConfigHeaderCount = $RulesConfigHeader.Count
If($RulesConfigHeader.Count -eq $ConfigFileHeaderNumber)
{
	Write-Host "|--> We get correct number of header ($ConfigFileHeaderNumber)" -fore Green
}
Else
{
	Write-Host "|--> There is an error when loading rule configuration, we get $RulesConfigHeaderCount header instead of $ConfigFileHeaderNumber" -fore Red
	Exit
}

#Define global variable
[array]$Global:NSGList = @()

Write-host "|-> Starting actions"

Foreach ($Rule in $RulesConfig)
{
	Try{
		#Define rule variables
		$RuleNSGName = $Rule.NSGName
		$RuleVirtualNetworkName = $Rule.VirtualNetworkName
		$RuleSubnetName = $Rule.SubnetName
		$RuleResourceGroupName = $Rule.ResourceGroupName
		$RuleLocation = $Rule.Location
		$RuleRuleName = $Rule.RuleName
		$RuleDescription = $Rule.Description
		$RuleDirection = $Rule.Direction
		$RulePriority = $Rule.Priority
		$RuleAccess = $Rule.Access
		$RuleSourceAddressPrefix = $Rule.SourceAddressPrefix
		$RuleSourcePortRange = $Rule.SourcePortRange
		$RuleDestinationAddressPrefix = $Rule.DestinationAddressPrefix	
		$RuleDestinationPortRange = $Rule.DestinationPortRange	
		$RuleProtocol = $Rule.Protocol
	}
	Catch
	{
		$errText = $error[0].Exception.Message
		Write-Host "|--> There is an error when loading rule configuration, verify you csv file: $errText" -fore Red
		Exit
	}
	
	Write-Host "----------------------------------------------------------------------------" -fore Yellow
	Write-host "- Configuration of rule $RuleRuleName in Network Security Group $RuleNSGName"-fore Yellow
	Write-Host "----------------------------------------------------------------------------" -fore Yellow
	Write-host "|-> Rule Configuration summary:" -fore White
	$Rule
	Write-Host "----------------------------------------------------------------------------" -fore Yellow
	Write-host "|-> Check if VNet $RuleVirtualNetworkName exist" -fore Yellow
	if($VNet.name -ne $RuleVirtualNetworkName)
	{
		$VNet = Get-AzVirtualNetwork | Where-Object{$_.name -eq $RuleVirtualNetworkName}	
	}
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: vnet="
		$vnet
	}	
	If ($null -eq $VNet)
	{
		Write-host "|--> VNet $RuleVirtualNetworkName don't exist, Virtual Network must be created before use this script." -fore Red
		Break
	}
	Else
	{
		Write-host "|--> VNet $RuleVirtualNetworkName exist." -fore Green
	}

	Write-host "|-> Check if Subnet $RuleSubnetName exist" -fore Yellow
	if($Subnet.name -ne $RuleSubnetName)
	{
		$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet | Where-Object{$_.Name -eq $RuleSubnetName}
	}
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: Subnet="
		$Subnet
	}
	If ($null -eq $Subnet)
	{
		Write-host "|--> Subnet $RuleSubnetName don't exist, Subnet must be created before use this script." -fore Red
		Break
	}
	Else
	{
		Write-host "|--> Subnet $RuleSubnetName exist." -fore Green
	}
	
	Write-host "|-> Check if Network Security Group $RuleNSGName exist" -fore Yellow
	if($NSG.name -ne $RuleNSGName)
	{
		$NSG = Get-AzNetworkSecurityGroup | Where-Object{$_.Name -eq $RuleNSGName}
	}
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: NSG="
		$NSG
	}
	If ($null -eq $NSG)
	{
		Write-host "|--> Network Security Group $RuleNSGName don't exist, we will create it"
		New-AzNetworkSecurityGroup -Name $RuleNSGName -ResourceGroupName $RuleResourceGroupName -Location $RuleLocation
		$NSG = Get-AzNetworkSecurityGroup | Where-Object{$_.Name -eq $RuleNSGName}
	}
	Else
	{
		Write-host "|--> Subnet $RuleNSGName exist." -fore Green
	}
		
	If($NSGList.Name -notcontains $RuleNSGName)
	{		
		Write-host "|-> Check if there are rules in the Network Security Group $RuleNSGName" -fore Yellow
		$NSGRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG
		If ($DebugMode -eq $True)
		{
			Write-host "|-> DEBUG: NSGRules="
			$NSGRules
		}
		If($null -ne $NSGRules)
		{
			If($EnableRequestToRemoveAllRules -eq $True)
			{
				$title = "|--> There are rules in the Network Security Group $RuleNSGName"
				$message = "|--> Do you want to remove all existing rules ?"
				$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Remove all Security Rules in this Network Security Group except Default. Before deleting, the current rules will be exported to a CSV file which can be used as a configuration file for the script"
				$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","No rules will be deleted in this Network Security Group."
				$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
				$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

				switch ($result)
				{
					0 {
						$title = "|--> Warning"
						$message = "|--> Are you sure ?"
						$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Confirm removal."
						$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Cancel removal."
						$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
						$resultConfirmation = $host.ui.PromptForChoice($title, $message, $options, 0)					
						switch ($resultConfirmation)
						{
							0 {	
								Write-host "|--> Backup actual rules" -fore Yellow
								[array]$NSGRulesBackup= @()
								Foreach($RuleToBackup in $NSGRules)
								{
									$RuleBackupProperties = @{
									NSGName=$RuleNSGName
									ResourceGroupName=$RuleResourceGroupName
									Location=$RuleLocation
									VirtualNetworkName=$RuleVirtualNetworkName
									SubnetName=$RuleSubnetName
									RuleName=$RuleToBackup.Name
									Description=$RuleToBackup.Description
									Direction=$RuleToBackup.Direction
									Priority=$RuleToBackup.Priority
									Access=$RuleToBackup.Access
									SourceAddressPrefix=$RuleToBackup.SourceAddressPrefix
									SourcePortRange=$RuleToBackup.SourcePortRange
									DestinationAddressPrefix=$RuleToBackup.DestinationAddressPrefix
									DestinationPortRange=$RuleToBackup.DestinationPortRange
									Protocol=$RuleToBackup.Protocol
									}
									$RuleBackup = New-Object PSObject -Property $RuleBackupProperties
									$NSGRulesBackup +=$RuleBackup 
								}
								$NSGRulesBackupFile = ".\Backup-NSG-Rules_" + $RuleNSGName + "_" + (get-date -uformat '%Y%m%d-%H%M') + ".csv"
								Write-host "|--> Export backup to csv file : $NSGRulesBackupFile" -fore Yellow
								$NSGRulesBackup | Export-csv $NSGRulesBackupFile -notype
								
								Write-host "|--> Execute remove all Security Rules in this Network Security Group except Default."
								$NSGSecurityRulesName = $NSGRules | %{$_.Name}
								If ($DebugMode -eq $True)
								{
									Write-host "|--> DEBUG: NSGSecurityRules="
									$NSGSecurityRulesName
								}
								Foreach ($SecurityRuleName in $NSGSecurityRulesName)
								{
									Remove-AzNetworkSecurityRuleConfig -Name $SecurityRuleName -NetworkSecurityGroup $NSG
								}
								Write-host "|--> Save Network Security Group configuration" -fore Yellow
								Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG 
								$NSG = Get-AzNetworkSecurityGroup | Where-Object{$_.Name -eq $RuleNSGName}
								Write-host "|-> Save Virtual Network configuration" -fore Yellow
								Set-AzVirtualNetwork -VirtualNetwork $VNet
								$VNet = Get-AzVirtualNetwork | Where-Object{$_.name -eq $RuleVirtualNetworkName}
								If ($DebugMode -eq $True)
								{
									Write-host "|--> DEBUG: NSG="
									$NSG
									Write-host "|-> DEBUG: vnet="
									$vnet
								}

							}
						}
					}
				}
			}
			Else
			{
				Write-Host "|--> There are rules in the Network Security Group $RuleNSGName :" -fore white
				$NSGRules
			}
		}		
		Write-host "|-> Add Network Security Group $RuleNSGName to list of firts check of rules" -fore Yellow
		$NSGList += $NSG
		If ($DebugMode -eq $True)
		{
			Write-host "|-> DEBUG: NSGList="
			$NSGList
		}
	}
	
	Write-host "|-> Check if Network Security Group $RuleNSGName is associated with subnet $RuleSubnetName" -fore Yellow
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: Subnet="
		$Subnet
	}
	If (($null -eq $Subnet.NetworkSecurityGroupText) -or ($Subnet.NetworkSecurityGroupText -eq "null"))
	{
		Write-host "|--> Network Security Group $RuleNSGName is not associated with subnet $RuleSubnetName, we will associate it" -fore Yellow
		Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $Subnet.Name -AddressPrefix $Subnet.AddressPrefix -NetworkSecurityGroup $NSG
		Write-host "|--> Save VNet configuration" -fore Yellow
		Set-AzVirtualNetwork -VirtualNetwork $VNet
		$VNet = Get-AzVirtualNetwork | Where-Object{$_.name -eq $RuleVirtualNetworkName}
		$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet | Where-Object{$_.Name -eq $RuleSubnetName}
		$NSG = Get-AzNetworkSecurityGroup | Where-Object{$_.Name -eq $RuleNSGName}
		If ($DebugMode -eq $True)
		{
			Write-host "|--> DEBUG: VNet="
			$VNet
			Write-host "|--> DEBUG: Subnet="
			$Subnet
			Write-host "|--> DEBUG: NSG="
			$NSG
		}
	}
	ElseIf ($Subnet.NetworkSecurityGroupText -match ("/providers/Microsoft.Network/networkSecurityGroups/" + $SubnetName))
	{
		Write-host "|--> Network Security Group $RuleNSGName is already associated with this subnet $RuleSubnetName." -fore Green
		$Subnet.NetworkSecurityGroupText
	}
	Else
	{
		Write-host "|--> Network Security Group $RuleNSGName is already associated with a subnet $RuleSubnetName." -fore Red
		$Subnet.NetworkSecurityGroupText
	}
	
	Write-host "|-> Check if rule exist in the Network Security Group $RuleNSGName" -fore Yellow
	$NSGRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG
	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: NSGRules="
		$NSGRules
	}
	If($null -ne $NSGRules)
	{
		$NSGSpecificRule = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG | Where-object {$_.Name -eq $RuleRuleName}
	}
	Else
	{
		$NSGSpecificRule = $null
	}

	If ($DebugMode -eq $True)
	{
		Write-host "|-> DEBUG: NSGSpecificRule="
		$NSGSpecificRule
	}

	If (($null -eq $NSGRule) -and ($null -eq $NSGSpecificRule))
	{
		Write-host "|--> Rule $RuleRuleName don't exist in the Network Security Group $RuleNSGName, we will create it" -fore Yellow
		Add-AzNetworkSecurityRuleConfig -Name $RuleRuleName -NetworkSecurityGroup $NSG -Access $RuleAccess -Description $RuleDescription -DestinationAddressPrefix $RuleDestinationAddressPrefix -DestinationPortRange $Rule.DestinationPortRange -Direction $RuleDirection -Priority $RulePriority -Protocol $RuleProtocol -SourceAddressPrefix $RuleSourceAddressPrefix -SourcePortRange $RuleSourcePortRange
		Write-host "|--> Save Network Security Group configuration" -fore Yellow
		Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG 
		Write-host "|-> Save Virtual Network configuration" -fore Yellow
		Set-AzVirtualNetwork -VirtualNetwork $VNet
	}
	Else
	{
		If(($Rule.Description -ne $NSGSpecificRule.Description) -or ($Rule.Direction -ne $NSGSpecificRule.Direction) -or ($Rule.Priority -ne $NSGSpecificRule.Priority) -or ($Rule.Access -ne $NSGSpecificRule.Access) -or ($Rule.SourceAddressPrefix -ne $NSGSpecificRule.SourceAddressPrefix) -or ($Rule.SourcePortRange -ne $NSGSpecificRule.SourcePortRange) -or ($Rule.DestinationAddressPrefix -ne $NSGSpecificRule.DestinationAddressPrefix) -or ($Rule.DestinationPortRange -ne $NSGSpecificRule.DestinationPortRange) -or ($Rule.Protocol -ne $NSGSpecificRule.Protocol))
		{
			Write-host "|--> Same Rule $RuleRuleName with different configuration exist in the Network Security Group $RuleNSGName." -fore Red
			$title = "|--> Warning"
			$message = "|--> Do you want to update existing rule ?"
			$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Confirm update."
			$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Cancel update."
			$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
			$resultConfirmation = $host.ui.PromptForChoice($title, $message, $options, 0)					
			switch ($resultConfirmation)
			{
				0 {					
					Write-host "|--> Backup actual rule" -fore Yellow
					$RuleBackupProperties = @{
					NSGName=$RuleNSGName
					ResourceGroupName=$RuleResourceGroupName
					Location=$RuleLocation
					VirtualNetworkName=$RuleVirtualNetworkName
					SubnetName=$RuleSubnetName
					RuleName=$NSGSpecificRule.Name
					Description=$NSGSpecificRule.Description
					Direction=$NSGSpecificRule.Direction
					Priority=$NSGSpecificRule.Priority
					Access=$NSGSpecificRule.Access
					SourceAddressPrefix=$NSGSpecificRule.SourceAddressPrefix
					SourcePortRange=$NSGSpecificRule.SourcePortRange
					DestinationAddressPrefix=$NSGSpecificRule.DestinationAddressPrefix
					DestinationPortRange=$NSGSpecificRule.DestinationPortRange
					Protocol=$NSGSpecificRule.Protocol
					}
					$NSGRuleBackup = New-Object PSObject -Property $RuleBackupProperties
					$NSGRuleBackupFile = ".\Backup-NSG-Specific-Rule_" + $RuleNSGName + "_" + $NSGSpecificRule.Name + "_" + (get-date -uformat '%Y%m%d-%H%M') + ".csv"
					Write-host "|--> Export backup to csv file : $NSGRuleBackupFile" -fore Yellow
					$NSGRuleBackup | Export-csv $NSGRuleBackupFile -notype
					Write-host "|--> Update of rule $RuleNSGName" -fore Yellow
					Set-AzNetworkSecurityRuleConfig -Name $RuleRuleName -NetworkSecurityGroup $NSG -Access $RuleAccess -Description $RuleDescription -DestinationAddressPrefix $RuleDestinationAddressPrefix -DestinationPortRange $Rule.DestinationPortRange -Direction $RuleDirection -Priority $RulePriority -Protocol $RuleProtocol -SourceAddressPrefix $RuleSourceAddressPrefix -SourcePortRange $RuleSourcePortRange
					Write-host "|--> Save Network Security Group configuration" -fore Yellow
					Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG
					Write-host "|-> Save Virtual Network configuration" -fore Yellow
					Set-AzVirtualNetwork -VirtualNetwork $VNet
				}
			}
		}
		Else
		{
			Write-host "|--> Same Rule $RuleRuleName with same configuration exist in the Network Security Group $RuleNSGName." -fore Green
		}
	}	
	
	Remove-variable NSGSecurityRulesName -ErrorAction SilentlyContinue
	Remove-variable RuleNSGName -ErrorAction SilentlyContinue
	Remove-variable RuleVirtualNetworkName -ErrorAction SilentlyContinue
	Remove-variable RuleSubnetName -ErrorAction SilentlyContinue
	Remove-variable RuleResourceGroupName -ErrorAction SilentlyContinue
	Remove-variable RuleLocation -ErrorAction SilentlyContinue
	Remove-variable RuleRuleName -ErrorAction SilentlyContinue	
	Remove-variable RuleDescription -ErrorAction SilentlyContinue	
	Remove-variable RuleDirection -ErrorAction SilentlyContinue
	Remove-variable RulePriority -ErrorAction SilentlyContinue
	Remove-variable RuleAccess -ErrorAction SilentlyContinue
	Remove-variable RuleSourceAddressPrefix -ErrorAction SilentlyContinue
	Remove-variable RuleSourcePortRange -ErrorAction SilentlyContinue
	Remove-variable RuleDestinationAddressPrefix -ErrorAction SilentlyContinue
	Remove-variable RuleDestinationPortRange -ErrorAction SilentlyContinue
	Remove-variable RuleProtocol -ErrorAction SilentlyContinue
	#Remove-variable VNet -ErrorAction SilentlyContinue
	#Remove-variable Subnet -ErrorAction SilentlyContinue
	#Remove-variable NSG -ErrorAction SilentlyContinue
	Remove-variable NSGRules -ErrorAction SilentlyContinue
	Remove-variable NSGSpecificRule -ErrorAction SilentlyContinue
	Remove-variable NSGRulesBackup -ErrorAction SilentlyContinue
	Remove-variable NSGRulesBackupFile -ErrorAction SilentlyContinue
	
}
$EndTime = (Get-Date)
$duration = [math]::round($(($EndTime-$StartTime).totalminutes),2)
Write-host "============================================================================" -Fore Yellow
Write-Host "|-> the process took "$duration" minutes"  -Fore White

if ($TranscriptStatus -ne "Error")
{
Stop-Transcript
}