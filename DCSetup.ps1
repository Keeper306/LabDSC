if(!$credential){$credential=get-credential}
$CIM=New-CimSession -ComputerName DC01 -Credential

Configuration DCSetup
{
    Import-DscResource -Name xDNSServerAddress,xADDomain
    xDNSServerAddress DNS #ResourceName
    {
        AddressFamily ='IPv4'
        InterfaceAlias =(get-ne)
        Address ='10.45.0.11'             
        Validate = $true
    }
    xADDomain LabDomain
    {
        DomainName='DC.LAB'
        DependsOn = '[xDNSServerAddress]DNS'
        DomainAdministratorCredential=$credential
        
    }
}