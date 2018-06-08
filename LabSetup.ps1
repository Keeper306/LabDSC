if(!$credential){$credential=get-credential -message 'Domain Creds' }
$CIM=New-CimSession -ComputerName SQL01 -Credential $credenetial
$Adapter=Get-Netadapter -CimSession $cim


$config= 
@{
    AllNodes = @(
        @{
            NodeName = "SQL01"
            InterfaceAlias=$Adapter.InterfaceAlias
            PSDscAllowPlainTextPassword = $true
            Role='SQL'
        }
    )

    Data= 
    @{
        DnsServerAddress='10.45.0.11'
        DomainName='DC.LAB'


    }

    
}

Configuration Labsetup
{
    Import-DscResource -Name xDNSServerAddress,xDSCDomainjoin
    Node $AllNodes.where{$_.Role -eq 'SQL'}.nodename
    {    
        
        xDNSServerAddress DNS #ResourceName
        {
            AddressFamily ='IPv4'
            InterfaceAlias =$Node.InterfaceAlias
            Address =$Config.Data.DnsServerAddress            
            Validate = $true
        }
        xDSCDomainjoin DomainJoin #ResourceName
        {
            Domain = $config.Data.DomainName
            Credential = $credential
            DependsOn = '[xDNSServerAddress]DNS'
            
        }
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true    
        }
    }
    
}

Labsetup -ConfigurationData $config -Verbose
<#
Set-DscLocalConfigurationManager -Path .\Labsetup\SQL01.meta.mof -CimSession $cim
Start-DscConfiguration -path .\ -CimSession $cim -verbose -wait
#>