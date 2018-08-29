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

Push-Location (Join-Path $InstallToolsDir "XP")

## INSTALL SITECORE XP
# define parameters
$prefix = $SitenamePrefix
$InstallRoot = $PWD
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


Write-Host "Install client certificate for xconnect"
$certParams = @{
    Path            = "xconnect-createcert.json"
    CertificateName = "${Sitename}-xconnect_client"
}
#Install-SitecoreConfiguration @certParams  -Verbose

Write-Host "install solr cores for xdb"
$solrParams = @{
    Path        = "$InstallRoot\xconnect-solr.json"
    SolrUrl     = $SolrUrl
    SolrRoot    = $SolrRoot
    SolrService = $SolrService
    CorePrefix  = $sitename
}
#Install-SitecoreConfiguration @solrParams

Write-Host "deploy xconnect instance"
$xconnectParams = @{
    Path             = (Resolve-Path "$InstallRoot\xconnect-xp0.json")
    Package          = (Join-Path $InstallRoot "Sitecore * (OnPrem)_xp0xconnect.scwdp.zip" -Resolve)
    LicenseFile      = (Resolve-Path "C:\install\license.xml")
    Sitename         = $XConnectCollectionService
    XConnectCert     = $certParams.CertificateName
    SqlDbPrefix      = $prefix
    SqlServer        = $SqlServer
    SqlAdminUser     = $SqlAdminUser
    SqlAdminPassword = $SqlAdminPassword
    SolrCorePrefix   = $prefix
    SolrURL          = $SolrUrl
}
#Install-SitecoreConfiguration @xconnectParams

Write-Host "install solr cores for sitecore"
$solrParams = @{
    Path        = Resolve-Path "$InstallRoot\sitecore-solr.json"
    SolrUrl     = $SolrUrl
    SolrRoot    = $SolrRoot
    SolrService = $SolrService
    CorePrefix  = $prefix
}
#Install-SitecoreConfiguration @solrParams

Write-Host "install sitecore instance"
$sitecoreParams = @{
    Path                      = Resolve-Path "$InstallRoot\sitecore-XP0.json"
    Package                   = (Join-Path $InstallRoot "Sitecore * (OnPrem)_single.scwdp.zip" -Resolve)
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
