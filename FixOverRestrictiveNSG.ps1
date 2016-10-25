Param (
  [string]  $region,
  [string]  $subscriptionID,
  [string]  $RGName,
  [string]  $NSGName
    )
	

#Log in to subscription
Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId $subscriptionId

#Download current list of Azure Public IP ranges
$downloadUri = 
    "https://www.microsoft.com/en-in/download/
     confirmation.aspx?id=41653"

$downloadPage = 
    Invoke-WebRequest -Uri $downloadUri

$xmlFileUri = 
    ($downloadPage.RawContent.Split('"') -like "https://*PublicIps*")[0]
$response = 
    Invoke-WebRequest -Uri $xmlFileUri

[xml]$xmlResponse = 
    [System.Text.Encoding]::UTF8.GetString($response.Content)

$regions = 
    $xmlResponse.AzurePublicIpAddresses.Region

#This the IP range that belong to datacenter we want to allow the traffic to
$ipRange = 
    ( $regions | 
      where-object Name -In $selectedRegions ).IpRange
	  
#Get NSG definition 
$NSGObj = Get-AzureRmNetworkSecurityGroup -Name $NSGName -resourceGroupName $RGName

#Add allow rules for each IP range in the datacenter
$rulePriority = 100

ForEach ($subnet in $ipRange.Subnet) {


    $ruleName = "Allow_Azure_Out_" + $subnet.Replace("/","-")

    Add-AzureRmNetworkSecurityRuleConfig -Name $ruleName -NetworkSecurityGroup $NSGObj ` 
    -Description "Allow outbound to Azure $subnet" `
    -Access Allow `
	-Protocol * `
	-Direction Outbound ` 
	-Priority $rulePriority `
	-SourceAddressPrefix VirtualNetwork `
    -SourcePortRange * `
    -DestinationAddressPrefix "$subnet" `
    -DestinationPortRange *

	$rulePriority++
}



