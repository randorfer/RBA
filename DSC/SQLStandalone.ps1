#requires -Version 4
Configuration SQLStandalone
{
    Import-DscResource -Module xSQLServer, psdesiredstateconfiguration

    $SourceDirectory = 'c:\temp\sqlsource'
    $FileshareAccessCred = Get-AutomationPSCredential -Name 'usfprbaprd@usac.mmm.com'
    $SQLSetupCred = Get-AutomationPSCredential -Name 'usfprbaprd@usac.mmm.com'
    
    Node SQL_2014_Ent_32bit_engine
    {
        $Version = '2014_Ent_32bit'
        File Sources_Directory
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = "$($SourceDirectory)"
            Force = $true
        }

        File SQL_Binaries
        {
            Ensure = 'Present'
            Type = 'Directory'
            Recurse = $true
            SourcePath = '\\usfile01\itdbsrvs-mssql-binaries\SQL2014\Enterprise_x86'
            DestinationPath = "$($SourceDirectory)\$($Version)\source"
            Force = $true
            Credential = $FileshareAccessCred
            Dependson = '[File]Sources_Directory'
        }

        WindowsFeature 'NET-Framework-Core'
        {
            Ensure = 'Present'
            Name = 'NET-Framework-Core'
            #           Source = $Node.SourcePath + "\WindowsServer2012R2\sources\sxs"
        }

        #SQL Setup
        xSqlServerSetup SQL_2014_Ent_32bit_engine
        {
            DependsOn = @('[WindowsFeature]NET-Framework-Core', '[File]Sql_Binaries')
            SourcePath = "$($SourceDirectory)\$($Version)"
            SetupCredential = $SQLSetupCred
            Features = 'SQLEngine,SSMS'
            SQLSysAdminAccounts = 'USAC\IT DBS MS SQL Admin'
            InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
            InstanceDir = 'F:\'
            InstallSQLDataDir = 'F:\'
            SQLUserDBDir = 'E:\MSSQL\DATA'
            SQLUserDBLogDir = 'G:\MSSQL\DATA'
            SQLTempDBDir = 'K:\MSSQL\DATA'
            SQLTempDBLogDir = 'L:\MSSQL\DATA'
            SQLBackupDir = 'J:\MSSQL\BACKUP'
            InstanceName = 'MSSQLSERVER'
        }
    }
}


