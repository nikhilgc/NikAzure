﻿<# 
.Synopsis 
    This PowerShell script provisions the DeviceM Microservice
.Description 
    This PowerShell script provisions the DeviceM Microservice
.Notes 
    File Name  : Provision-DeviceM.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Provision-DeviceM.ps1 [Null], [-Full], [-Detailed], [-Examples]

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
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The name of the Azure Subscription for which you've imported a *.publishingsettings file.")]
    [string]$Subscription,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The name of the Azure Region/Location: East US, Central US, West US.")]
    [string]$AzureLocation,
    [Parameter(Mandatory=$True, Position=3, HelpMessage="A unique user tag assigned for purposes of the lab")]
    [string]$UserTag

)

##########################################################################################
# V A R I A B L E S
##########################################################################################

# name for resource group
$HOL_RG = "HOL_RG_" + $UserTag

# names for app service plans
$DeviceM_SP = $UserTag + "DeviceM_SP" + $UserTag

# unique names for sites
$DevicePublicAPI = $UserTag + "DevicePublicAPI" + $UserTag
$DeviceAdminAPI = $UserTag + "DeviceAdminAPI" + $UserTag

##########################################################################################
# F U N C T I O N S
##########################################################################################

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

# mark the start time.
$StartTime = Get-Date

# Select Subscription
Select-Subscription $Subscription

# create app service plan
$command = $Repo + "\Automation\Common\Create-AppServicePlan"
&$command $Subscription $HOL_RG $DeviceM_SP $AzureLocation

# create web site containers
$command = $Repo + "\Automation\Common\Create-WebSite.ps1"
&$command $Subscription $DeviceAdminAPI  $HOL_RG $DeviceM_SP $AzureLocation
&$command $Subscription $DevicePublicAPI $HOL_RG $DeviceM_SP $AzureLocation

# mark the finish time.
$FinishTime = Get-Date

#Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime"
