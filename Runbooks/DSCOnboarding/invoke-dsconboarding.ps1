<#
        .SYNOPSIS
        Add a synopsis here to explain the PSScript. 

        .Description
        Give a description of the Script.

#>
Param(
    $computername
)
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$CompletedParameters = Write-StartingMessage -CommandName invoke-dsconboarding

$Vars = Get-BatchAutomationVariable -Name  'DomainCredentialName' `
-Prefix 'Global'

$Credential = Get-AutomationPSCredential -Name $Vars.DomainCredentialName

Try
{
    $tempdir = New-TempDirectory 
    $CurrentLocation = get-location
    Set-Location -Path $tempdir

    # The DSC configuration that will generate metaconfigurations
    Set-StrictMode -Off
    [DscLocalConfigurationManager()]
    Configuration DscMetaConfigs 
    { 
        param 
        ( 
            [Parameter(Mandatory = $True)] 
            [String]$RegistrationUrl,

            [Parameter(Mandatory = $True)] 
            [String]$RegistrationKey,

            [Parameter(Mandatory = $True)] 
            [String[]]$computername,

            [Int]$RefreshFrequencyMins = 30, 

            [Int]$ConfigurationModeFrequencyMins = 15, 

            [String]$ConfigurationMode = 'ApplyAndMonitor', 

            [String]$NodeConfigurationName,

            [Boolean]$RebootNodeIfNeeded = $False,

            [String]$ActionAfterReboot = 'ContinueConfiguration',

            [Boolean]$AllowModuleOverwrite = $False,

            [Boolean]$ReportOnly
        )

        if(!$NodeConfigurationName -or $NodeConfigurationName -eq '') 
        {
            $ConfigurationNames = $null
        } 
        else 
        {
            $ConfigurationNames = @($NodeConfigurationName)
        }

        if($ReportOnly)
        {
            $RefreshMode = 'PUSH'
        }
        else
        {
            $RefreshMode = 'PULL'
        }

        Node $computername
        {
            Settings 
            { 
                RefreshFrequencyMins = $RefreshFrequencyMins 
                RefreshMode = $RefreshMode 
                ConfigurationMode = $ConfigurationMode 
                AllowModuleOverwrite  = $AllowModuleOverwrite 
                RebootNodeIfNeeded = $RebootNodeIfNeeded 
                ActionAfterReboot = $ActionAfterReboot 
                ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins 
            }

            if(!$ReportOnly)
            {
                ConfigurationRepositoryWeb AzureAutomationDSC 
                { 
                    ServerUrl = $RegistrationUrl 
                    RegistrationKey = $RegistrationKey 
                    ConfigurationNames = $ConfigurationNames 
                }

                ResourceRepositoryWeb AzureAutomationDSC 
                { 
                    ServerUrl = $RegistrationUrl 
                    RegistrationKey = $RegistrationKey 
                }
            }

            ReportServerWeb AzureAutomationDSC 
            { 
                ServerUrl = $RegistrationUrl 
                RegistrationKey = $RegistrationKey 
            }
        } 
    }

    # Create the metaconfigurations
    # TODO: edit the below as needed for your use case
    $Params = @{
        RegistrationUrl                = 'https://eus2-agentservice-prod-1.azure-automation.net/accounts/3dfbd6d5-ad05-4d97-9fff-e91292260f82'
        RegistrationKey                = 'tUcYBGetsVTlRW0f3J5rM8BAHKE6R1fAr8Wrt0BnpGKwizTmfS0hJaJlaA+5fqnxReeEgdGyYvgo6Gj24bKMEA=='
        ComputerName                   = $computername
        NodeConfigurationName          = 'sqlstandalone.SQL_2014_Ent_32bit_engine'
        RefreshFrequencyMins           = 30
        ConfigurationModeFrequencyMins = 15
        RebootNodeIfNeeded             = $True
        AllowModuleOverwrite           = $True
        ConfigurationMode              = 'ApplyAndMonitor'
        ActionAfterReboot              = 'ContinueConfiguration'
        ReportOnly                     = $False
    }

    # Use PowerShell splatting to pass parameters to the DSC configuration being invoked
    # For more info about splatting, run: Get-Help -Name about_Splatting
    $null=DscMetaConfigs @Params
    Set-DscLocalConfigurationManager -Path .\DscMetaConfigs -ComputerName $computername -Credential $Credential
}
Catch
{
    $Exception = $_
    $ExceptionInfo = Get-ExceptionInfo -Exception $Exception
    Switch ($ExceptionInfo.FullyQualifiedErrorId)
    {
        Default
        {
            Write-Exception -Exception $Exception -Stream Warning
        }
    }
}
Finally
{
    Set-Location -Path $CurrentLocation
    if(Test-Path -Path $tempdir.fullname)
    {
        Remove-Item -Path $tempdir -Force -Recurse
    }
}


Write-CompletedMessage @CompletedParameters
