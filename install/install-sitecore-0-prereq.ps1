param(
    $SitecoreDownloadUser = $Null,
    $SitecoreDownloadPass = $Null,
    $Sitename = "testsite",
    $SqlSaPassword = "HASH-posh-123-hjuG",
    $InstallToolsDir = $PSScriptRoot
)

Uninstall-WindowsFeature -Name Windows-Defender-Features;
Uninstall-WindowsFeature -Name BitLocker;

$ErrorActionPreference = "STOP"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;


If(-not (Test-Path $InstallToolsDir -PathType Container)) {
    New-Item $InstallToolsDir -ItemType Directory | Out-Null
}
Push-Location $InstallToolsDir

if($SitecoreDownloadUser -eq $Null) {
    $SitecoreDownloadUser = (Read-Host "Enter username for Sitecore site")
}
if($SitecoreDownloadPass -eq $Null) {
    $SitecoreDownloadPass = (Read-Host "Enter password for ${SitecoreDownloadUser}")
}

# Add windows features
Add-WindowsFeature Web-Server
Add-WindowsFeature Web-Asp-Net45
Add-WindowsFeature NET-HTTP-Activation

# Some tweaks and remove default IIS site
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord;
Remove-Website -Name 'Default Web Site';

# SQL Server from https://github.com/Microsoft/mssql-docker/blob/master/windows/mssql-server-windows-developer/dockerfile
$exe = "https://go.microsoft.com/fwlink/?linkid=840945"
$box = "https://go.microsoft.com/fwlink/?linkid=840944"

Invoke-WebRequest -Uri $box -OutFile SQL.box ;
Invoke-WebRequest -Uri $exe -OutFile SQL.exe ;
Start-Process -Wait -FilePath .\SQL.exe -ArgumentList /qs, /x:setup ;
.\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS
Remove-Item -Recurse -Force SQL.exe, SQL.box, setup

stop-service MSSQLSERVER ;
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value '' ;
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433 ;
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\' -name LoginMode -value 2 ;
start-service MSSQLSERVER
& sqlcmd -Q ("ALTER LOGIN sa with password=" +"'" + $SqlSaPassword + "'")
& sqlcmd -Q "ALTER LOGIN sa ENABLE;"
& sqlcmd -Q "sp_configure 'show advanced options', 1;"
& sqlcmd -Q "RECONFIGURE WITH OVERRIDE;"
& sqlcmd -Q "sp_configure 'contained database authentication', 1;"
& sqlcmd -Q "RECONFIGURE WITH OVERRIDE;"


# Install chocolatey to handle dependencies
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Invoke-WebRequest -Uri "http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi" -OutFile "webdeploy.msi" ;
Start-Process msiexec.exe -ArgumentList '/i', "webdeploy.msi", '/quiet', '/norestart' -NoNewWindow -Wait;
Invoke-WebRequest -Uri "http://download.microsoft.com/download/D/D/E/DDE57C26-C62C-4C59-A1BB-31D58B36ADA2/rewrite_amd64_en-US.msi" -OutFile "rewrite.msi";
Start-Process msiexec.exe -ArgumentList '/i', "rewrite.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Invoke-WebRequest -Uri "https://aka.ms/vs/15/release/VC_redist.x64.exe" -OutFile "VC_redist.msi";
Start-Process msiexec.exe -ArgumentList '/i', "VC_redist.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Invoke-WebRequest -Uri "https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x86/DacFramework.msi" -OutFile "DacFramework86.msi";
Invoke-WebRequest -Uri "https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x64/DacFramework.msi" -OutFile "DacFramework64.msi";
Start-Process msiexec.exe -ArgumentList '/i', "DacFramework86.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Start-Process msiexec.exe -ArgumentList '/i', "DacFramework64.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?LinkID=849415&clcid=0x409" -OutFile "SqlSysClrTypes.msi";
Start-Process msiexec.exe -ArgumentList '/i', "SqlSysClrTypes.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Remove-Item webdeploy.msi ;
Remove-Item rewrite.msi ;
Remove-Item VC_redist.msi ;
Remove-Item DacFramework86.msi;
Remove-Item DacFramework64.msi;
Remove-Item SqlSysClrTypes.msi;

& sqlcmd -Q "sp_configure 'contained database authentication', 1"
& sqlcmd -Q "RECONFIGURE"

# OpenJdk and Solr
choco install zulu8 --version 8.28.0.1 -y
$javaHome = "C:\Program Files (x86)\Java\jre1.8.0_171"
[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
choco install solr --version 6.6.2 -y
$SolrPath = "c:\tools\solr-6.6.2"
# NSSM to start Solr as service
Invoke-WebRequest -Uri "https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip" -OutFile "nssm.zip"
Expand-Archive "nssm.zip" -DestinationPath $SolrPath
$nssmSolrPath = "${SolrPath}\nssm-2.24-101-g897c7ad\win64\nssm.exe"
$solrServiceName = "Solr${sitename}"
Start-Process $nssmSolrPath -ArgumentList "install $solrServiceName ${SolrPath}\bin\solr.cmd" -Wait -NoNewWindow -PassThru
Start-Process $nssmSolrPath -ArgumentList "set $solrServiceName AppDirectory ${SolrPath}\bin" -Wait -NoNewWindow -PassThru
Invoke-Expression ($nssmSolrPath + " set " + $solrServiceName + " AppParameters " + "start -f -p 8983")
# SolR SSL
$keytool = (Join-Path $javaHome "bin\keytool.exe")
$KeystoreName = "solr-ssl.keystore.jks"
$KeystoreFile = (Join-Path $SolrPath "server\etc\${KeystoreName}")
$KeystorePassword = "secret" # Must be "secret" because Solr apparently ignores the parameter'
$ErrorActionPreference = "Continue"
# Generate java JKS keystore
& $keytool -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $KeystorePassword -storepass $KeystorePassword -validity 9999 -keystore $KeystoreFile -ext SAN=DNS:localhost,IP:127.0.0.1 -dname "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country"
# Generating .p12 for Windows
$P12Path = [IO.Path]::ChangeExtension($KeystoreFile, 'p12')
& $keytool -importkeystore -srckeystore $KeystoreFile -destkeystore $P12Path -srcstoretype jks -deststoretype pkcs12 -srcstorepass $KeystorePassword -deststorepass $KeystorePassword
$secureStringKeystorePassword = ConvertTo-SecureString -String $KeystorePassword -Force -AsPlainText
Import-PfxCertificate -FilePath $P12Path -Password $secureStringKeystorePassword -CertStoreLocation Cert:\LocalMachine\Root
$ErrorActionPreference = "STOP"

# Configure solr to use ssl
Invoke-Expression ($nssmSolrPath + " set " + $solrServiceName + " AppEnvironmentExtra " `
                        + "SOLR_SSL_KEY_STORE=etc/${KeystoreName} "  `
                        + "SOLR_SSL_KEY_STORE_PASSWORD=${KeystorePassword} " `
                        + "SOLR_SSL_TRUST_STORE=etc/${KeystoreName} " `
                        + "SOLR_SSL_TRUST_PASSWORD=${KeystorePassword}")

start-service $solrServiceName



# Install Sitecore Installation Framework
Install-PackageProvider -Name NuGet -Force | Out-Null;
Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2; 
Install-Module SitecoreInstallFramework -RequiredVersion 1.2.1 -Force;

# Download sitecore files
$credentials = @{
    username = $SitecoreDownloadUser
    password = $SitecoreDownloadPass
}
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$login = Invoke-RestMethod -Method Post -Uri "https://dev.sitecore.net/api/authorization" -Body (ConvertTo-Json $credentials) -ContentType "application/json;charset=UTF-8" -WebSession $session
If($login -ne $True) {
    Write-Warning "Incorrect username or password"
    return
}

Invoke-WebRequest -WebSession $session -Uri `
    "https://dev.sitecore.net/~/media/8551EF0996794A7FA9FF64943B391855.ashx" `
    -OutFile `
    "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages).zip"
Invoke-WebRequest -WebSession $session -Uri `
    "https://dev.sitecore.net/~/media/26FDFBD5E8C04F41A545098F3E7DB2C6.ashx" `
    -OutFile `
    "Web Forms for Marketers 9.0 rev. 171209.zip"
Invoke-WebRequest -WebSession $session -Uri `
    "https://dev.sitecore.net/~/media/573443081B494E2B9D83D3208B549E49.ashx" `  
    -OutFile `
    "Sitecore Experience Accelerator WDP for 9.0.zip"
Invoke-WebRequest -WebSession $session -Uri `
    "https://dev.sitecore.net/~/media/4918E7ADAAF049F4BC7BA5B73561F24F.ashx" `
    -OutFile `
    "Sitecore Powershell Extensions WDP 4.7.2.zip"

# Extract Sitecore XP installation files
Expand-Archive "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages).zip"
Push-Location "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages)"
Expand-Archive "XP0 Configuration files 9.0.1 rev. 171219.zip" -DestinationPath $PWD

