param(
    $SitenamePrefix = "testsite",
    $Sitename = "${SitenamePrefix}.sc",
    $SolrPath = "c:\tools\solr-6.6.2",
    $solrServiceName = "Solr${Sitename}",
    $SqlSaPassword = "HASH-posh-123-hjuG",
    $InstallToolsDir = $PSScriptRoot,
    $LicenseFile = "c:\license.xml"
)

$ErrorActionPreference = "STOP"

## INSTALL SITECORE XP
# define parameters
$prefix = $SitenamePrefix
$InstallRoot = (Join-Path $InstallToolsDir "Sitecore 9.0.1 rev. 171219 (WDP XP0 packages)") 
$XConnectCollectionService = "$prefix.xconnect"
$sitecoreSiteName = $Sitename
$SolrUrl = "https://localhost:8983/solr"
$SolrRoot = $SolrPath
$SolrService = $solrServiceName
$SqlServer = "."
$SqlAdminUser = "sa"
$SqlAdminPassword = $SqlSaPassword

# Verify
& sqlcmd -Q "SELECT name from sysdatabases" -U sa -P $SqlSaPassword
& Invoke-WebRequest -UseBasicParsing -Uri $SolrUrl


# Install client certificate for xconnect
$certParams = @{
    Path            = "xconnect-createcert.json"
    CertificateName = "${Sitename}-xconnect_client"
}
Install-SitecoreConfiguration @certParams  -Verbose
#install solr cores for xdb
$solrParams = @{
    Path        = "$InstallRoot\xconnect-solr.json"
    SolrUrl     = $SolrUrl
    SolrRoot    = $SolrRoot
    SolrService = $SolrService
    CorePrefix  = $sitename
} 
Install-SitecoreConfiguration @solrParams
#deploy xconnect instance
$xconnectParams = @{
    Path             = "$InstallRoot\xconnect-xp0.json"
    Package          = "$InstallRoot\Sitecore 9.0.1 rev. 171219 (OnPrem)_xp0xconnect.scwdp.zip"
    LicenseFile      = "C:\license.xml"
    Sitename         = $XConnectCollectionService
    XConnectCert     = $certParams.CertificateName
    SqlDbPrefix      = $prefix
    SqlServer        = $SqlServer
    SqlAdminUser     = $SqlAdminUser
    SqlAdminPassword = $SqlAdminPassword
    SolrCorePrefix   = $prefix
    SolrURL          = $SolrUrl
} 
Install-SitecoreConfiguration @xconnectParams
#install solr cores for sitecore
$solrParams = @{
    Path        = "$InstallRoot\sitecore-solr.json"
    SolrUrl     = $SolrUrl
    SolrRoot    = $SolrRoot
    SolrService = $SolrService
    CorePrefix  = $prefix
}
Install-SitecoreConfiguration @solrParams

#install sitecore instance
$sitecoreParams = @{
    Path                      = "$InstallRoot\sitecore-XP0.json"
    Package                   = "$InstallRoot\Sitecore 9.0.1 rev. 171219 (OnPrem)_single.scwdp.zip"
    LicenseFile               = $LicenseFile
    SqlDbPrefix               = $prefix
    SqlServer                 = $SqlServer
    SqlAdminUser              = $SqlAdminUser
    SqlAdminPassword          = $SqlAdminPassword
    SolrCorePrefix            = $prefix
    SolrUrl                   = $SolrUrl
    XConnectCert              = $certParams.CertificateName
    Sitename                  = $sitecoreSiteName
    XConnectCollectionService = "https://$XConnectCollectionService"
}
Install-SitecoreConfiguration @sitecoreParams


# Assign permissions
Add-LocalGroupMember -Group "Performance Log Users" -Member "IIS AppPool\${sitecoreSiteName}"