param(
    $SitecoreDownloadUser = $Null,
    $SitecoreDownloadPass = $Null,
    $SitenamePrefix = "testsite",
    $InstallToolsDir = "c:\install"
)

$ErrorActionPreference = "STOP"
Push-Location $InstallToolsDir

# Install chocolatey to handle dependencies
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# OpenJdk and Solr
#choco install zulu8 --version 8.28.0.1 -y
#$javaHome = "C:\Program Files\Zulu\zulu-8\jre"

choco install server-jre8 --version 8.0.181 -y
choco install solr --version 6.6.2 -y
$javaHome = Resolve-Path "C:\tools\Java\server-jre\jdk1.8.0_181\"
[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
$env:JAVA_HOME = $javaHome
$SolrPath = Resolve-Path "c:\tools\solr-6.6.2"
# NSSM to start Solr as service
Invoke-WebRequest -Uri "https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip" -OutFile "nssm.zip"
Expand-Archive "nssm.zip" -DestinationPath $SolrPath
$nssmSolrPath = Join-Path $SolrPath "\nssm-2.24-101-g897c7ad\win64\nssm.exe" -Resolve
$solrServiceName = "Solr${SitenamePrefix}"
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
& $keytool -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $KeystorePassword -storepass $KeystorePassword -validity 9999 -keystore $KeystoreFile -ext SAN=DNS:localhost,IP:127.0.0.1 -dname "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country" 2>&1
# Generating .p12 for Windows
$P12Path = [IO.Path]::ChangeExtension($KeystoreFile, 'p12')
& $keytool -importkeystore -srckeystore $KeystoreFile -destkeystore $P12Path -srcstoretype jks -deststoretype pkcs12 -srcstorepass $KeystorePassword -deststorepass $KeystorePassword 2>&1
$secureStringKeystorePassword = ConvertTo-SecureString -String $KeystorePassword -Force -AsPlainText
Import-PfxCertificate -FilePath $P12Path -Password $secureStringKeystorePassword -CertStoreLocation Cert:\LocalMachine\Root
$ErrorActionPreference = "STOP"

# Configure solr to use ssl
Invoke-Expression ($nssmSolrPath + " set " + $solrServiceName + " AppEnvironmentExtra " `
                        + "JAVA_HOME=${javaHome} "  `
                        + "SOLR_SSL_KEY_STORE=etc/${KeystoreName} "  `
                        + "SOLR_SSL_KEY_STORE_PASSWORD=${KeystorePassword} " `
                        + "SOLR_SSL_TRUST_STORE=etc/${KeystoreName} " `
                        + "SOLR_SSL_TRUST_PASSWORD=${KeystorePassword}")

$now = [System.DateTime]::Now
start-service $solrServiceName
Start-Sleep 5
get-eventlog -LogName Application -Source nssm -After $now | Sort-Object -Descending | Format-List -Property TimeGenerated, EntryType, Message

Invoke-WebRequest "https://localhost:8983" -UseBasicParsing
