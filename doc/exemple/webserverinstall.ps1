import-module -name Requirements



$Requirement = @(

    @{
        Name     = "WebServer"
        Describe = "Web Server feature is present in the system"
        Test     = { (Get-WindowsFeature -Name web-server -ErrorAction SilentlyContinue).installed }
        Set      = { Add-WindowsFeature Web-Server | Out-Null; Start-Sleep 1 }
    },
    @{
        Name     = "Localcert"
        Describe = "Create a selfsigned certificat for internal.mydomain.com"
        Test     = { 
                    "CN=internal.mydomain.com" -in (Get-ChildItem "Cert:\LocalMachine\My").Subject
                   }
        Set      = { New-SelfSignedCertificate -DnsName internal.mydomain.com -CertStoreLocation cert:\LocalMachine\My }
        DependsOn = "WebServer"
    },
    @{
        Name     = "LocalWebSite"
        Describe = "Create a web site binding with the certificat for internal.mydomain.com"
        Test     = { 
                    Import-Module IISAdministration
                    $CertObject = (Get-ChildItem "Cert:\LocalMachine\My") | where-object subject -eq CN=internal.mydomain.com

                    }
        Set      = { $mySystem.Add(1) | Out-Null; Start-Sleep 1 }
        DependsOn = "WebServer","Localcert"
    }
)

$requirements | Invoke-Requirement