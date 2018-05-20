$computername="SCSI01"
if(!$credentials){$credentials=get-credential}
Configuration Labsetup
{
    Import-DscResource -Name xDNSServerAddress,xDSCDomainjoin
    Node $configdata.AllNodes.nodename
    {    
        
        xDNSServerAddress DNS #ResourceName
        {
            AddressFamily ='IPv4'
            InterfaceAlias ='Ethernet 2'
            Address ='192.168.137.11'             
            Validate = $true
        }
        xDSCDomainjoin DomainJoin #ResourceName
        {
            Domain = 'l745.lab'
            Credential = ($credentials)
            DependsOn = '[xDNSServerAddress]DNS'
            
        }
        <# LocalConfigurationManager
        {
             CertificateId = $node.Thumbprint
        }#>
    }
    
}

$configdata = 
@{
    AllNodes = @(
        @{
            NodeName = "$computername"
            #CertificateFile = 'C:\DSCConfig\Certificate\DSCPublicCert.cer'
            #Thumbprint = "89FCE5329EE98B7685FBB45BC7C102F1D0ED4607"
            PSDscAllowPlainTextPassword = $true
        }
    )
}

Labsetup -ConfigurationData $configdata

