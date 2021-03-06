﻿<#
.Synopsis 
    This PowerShell script deploys the DeviceM Microservice
.Description 
    This PowerShell script deploys the DeviceM Microservice
    You must provide the connection strings from your DocumentDb and Redis Cache instances for this script to function
.Notes 
    File Name  : Deploy-DeviceM.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Deploy-DeviceM.ps1 [Null], [-Full], [-Detailed], [-Examples]

.Link   
    https://microservices.codeplex.com/

.Parameter Repo
    Example:  c:\users\bob\source\repos\looksfamiliar
.Parameter Subscription
    Example:  MySubscription
.Parameter AzureLocation
    Example:  East US
.Parameter Prefix
    Example:  looksfamiliar
.Parameter Suffix
    Example:  test
.Inputs
    The [Repo] parameter is the path to the Git Repo
    The [Subscription] parameter is the name of the client Azure subscription.
    The [AzureLocation] parameter is the name of the Azure Region/Location to host the Virtual Machines for this subscription.
    The [Prefix] parameter is the common prefix that will be used to name resources
    The [Suffix] parameter is one of 'dev', 'test' or 'prod'
.Outputs
    Console
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The path to the Git Repo.")]
    [string]$Repo,
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The name of the Azure Subscription.")]
    [string]$Subscription,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The name of the Azure Region/Location: East US, Central US, West US.")]
    [string]$AzureLocation,
    [Parameter(Mandatory=$True, Position=3, HelpMessage="The common prefix for resource naming")]
    [string]$Prefix,
    [Parameter(Mandatory=$True, Position=4, HelpMessage="The suffix for resource naming: 'dev, 'test' or 'prod'")]
    [string]$Suffix,
    [switch]$DeployData
)

#######################################################################################
# V A R I A B L E S
#######################################################################################

$includePath = $Repo + "\Automation\Include-ConnectionStrings.ps1"
."$includePath"

$DeviceM_RG = "DeviceM_RG" 
$DeviceM_SP = "DeviceM_SP" 
$DeviceM_DB = "DeviceM"

$RefAdminAPI = $Prefix + "RefAdminAPI" + $Suffix
$DevicePublicAPI = $Prefix + "DevicePublicAPI" + $Suffix
$DeviceAdminAPI = $Prefix + "DeviceAdminAPI" + $Suffix

#######################################################################################
# F U N C T I O N S
#######################################################################################

Function Select-Subscription()
{
    Param([String] $Subscription)

    Try
    {
        Select-AzureSubscription -SubscriptionName $Subscription -ErrorAction Stop

        # List Subscription details if successfully connected.
        Get-AzureSubscription -Current -ErrorAction Stop

        Write-Verbose -Message "Currently selected Azure subscription is: $Subscription."
    }
    Catch
    {
        Write-Verbose -Message $Error[0].Exception.Message
        Write-Verbose -Message "Exiting due to exception: Subscription Not Selected."
    }
}

##########################################################################################
# M A I N
##########################################################################################

$Error.Clear()

# Mark the start time.
$StartTime = Get-Date

# Select Subscription
Select-Subscription $Subscription 

# Load DocumentDb with the device registry
if ($DeployData)
{
    $connStr = $docdbconnstr + "Database=" + $DeviceM_DB
    .\..\..\..\Automation\Common\Load-DocDb.ps1 -Repo $Repo -Subscription $Subscription -DocDbConnStr $connStr -CollectionName Registry
}

# Package the APIs
.\Package-DeviceM.ps1 $Repo

# Deploy the APIs and update their app settings for documentdb and redis
.\..\..\..\Automation\Common\Publish-WebSite.ps1 -Repo $Repo -ResourceGroupName $DeviceM_RG -DeploymentName DeviceAdminAPI  -Location $AzureLocation -SiteName $DeviceAdminAPI  -ServicePlan $DeviceM_SP -DocDbURI $docdburi -DocDbKEY $docdbkey -RedisURI $redisuri 
.\..\..\..\Automation\Common\Publish-WebSite.ps1 -Repo $Repo -ResourceGroupName $DeviceM_RG -DeploymentName DevicePublicAPI -Location $AzureLocation -SiteName $DevicePublicAPI -ServicePlan $DeviceM_SP -DocDbURI $docdburi -DocDbKEY $docdbkey -RedisURI $redisuri 

# Mark the finish time.
$FinishTime = Get-Date

# Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime"
