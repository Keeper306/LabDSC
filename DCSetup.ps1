if(!$credential){$credential=get-credential -message 'Domain Creds' }
$CIM=New-CimSession -ComputerName DC01 -Credential $credenetial
if(!$newadusercred){$NewADUserCred=get-credential -Message 'AD USer'} 
Configuration DCSetup
{
    Import-DscResource -Name xDNSServerAddress,xADDomain,xADUser,xWaitForADDomain,WindowsFeature,xADGroup
    Import-DscResource -module xDHCpServer
    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename
    {
        xDNSServerAddress DNS #ResourceName
        {
            AddressFamily ='IPv4'
            InterfaceAlias ='Ethernet'
            Address ='10.45.0.11'             
            
        }
        Foreach ($Feature in $Node.Features)
        {
            WindowsFeature $Feature
            {
                Ensure = "Present"
                Name = $Feature
            }
        }
        

        xADDomain LabDomain
        {
            DomainName='DC.LAB'
            DependsOn = '[xDNSServerAddress]DNS',"[WindowsFeature]AD-Domain-Services"
            DomainAdministratorCredential=$credential
            SafemodeAdministratorPassword=$credential
        }
     

        xADUser aivanov
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            UserName = "aivanov"
            Password = $NewADUserCred
            Ensure = "Present"
            DependsOn = "[xADDomain]LabDomain"
            PasswordNeverExpires = $true
        }
        xADGroup DomainAdmins
        {
           GroupName = 'Domain Admins'
           MembersToInclude = 'aivanov'
           DependsOn = "[xADUser]aivanov"
        }
        xDhcpServerAuthorization LocalServerActivation
        {
            Ensure = 'Present'
            DependsOn = "[WindowsFeature]DHCP"
        }
        
        xDhcpServerScope Scope45
        {
            IPStartRange = '10.45.0.65'
            IPEndRange = '10.45.0.128'
            Name = '10.45.0.0/24 Scope'
            SubnetMask = '255.255.255.0'
            AddressFamily = 'IPv4'
            Ensure = 'Present'
            LeaseDuration = ((New-TimeSpan -Hours 8 ).ToString())
            State = 'Active'
            DependsOn = "[xDhcpServerAuthorization]LocalServerActivation"
         }
         xDhcpServerOption Option
        {
            Ensure = 'Present'
            ScopeID = '10.45.0.0'
            DnsDomain = $Node.DomainName
            DnsServerIPAddress = '10.45.0.11'
            AddressFamily = 'IPv4'
            Router = '10.45.0.1'
            DependsOn = "[xDhcpServerScope]Scope45"
        }
    }
}
$configdata = 
    @{
        AllNodes = @(
            @{
                Role = "Primary DC"
                NodeName = "DC01"
                DomainName='DC.LAB'
                #CertificateFile = 'C:\DSCConfig\Certificate\DSCPublicCert.cer'
                #Thumbprint = "89FCE5329EE98B7685FBB45BC7C102F1D0ED4607"
                PSDscAllowPlainTextPassword = $true
                Features='DHCP','AD-Domain-Services'
            }
        )
    }

    DCSetup -ConfigurationData $configdata
    Start-DscConfiguration -CimSession $CIM -Path .\DCSetup -Verbose -Wait -Force