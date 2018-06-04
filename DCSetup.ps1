if(!$credential){$credential=get-credential -message 'Domain Creds' }
$CIM=New-CimSession -ComputerName DC01 -Credential $credenetial
if(!$newadusercred){$NewADUserCred=get-credential -Message 'AD USer'} 
Configuration DCSetup
{
    Import-DscResource -Name xDNSServerAddress,xADDomain,xADUser,xWaitForADDomain,WindowsFeature,xADGroup
    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename
    {
        xDNSServerAddress DNS #ResourceName
        {
            AddressFamily ='IPv4'
            InterfaceAlias ='Ethernet'
            Address ='10.45.0.11'             
            
        }
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        xADDomain LabDomain
        {
            DomainName='DC.LAB'
            DependsOn = '[xDNSServerAddress]DNS','[WindowsFeature]ADDSInstall'
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
            }
        )
    }
    DCSetup -ConfigurationData $configdata
    Start-DscConfiguration -CimSession $CIM -Path .\DCSetup -Verbose -Wait -Force