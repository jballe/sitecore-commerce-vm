param(
    $SitenamePrefix = "testsite",
    $Sitename = "${SitenamePrefix}.sc",
    $InstallToolsDir = $PSScriptRoot,
    $BaseUrl = "http://${Sitename}",
    [int]$TimeoutSec = 720
)

$ErrorActionPreference = "STOP"

# Warmup site
Write-Host "Verify website..."
Invoke-WebRequest $BaseUrl -UseBasicParsing -TimeoutSec $TimeoutSec
Write-Host "Website is ok"

# Install packages
Write-Host "Install packages..."
$destination = "c:\inetpub\wwwroot\${Sitename}.sc\sitecore\admin\Packages"
@("Sitecore Powershell Extensions WDP 4.7.2.zip", "Sitecore Experience Accelerator WDP for 9.0.zip") | ForEach-Object {
    Write-Host ("  Instal {0}... " -f $_)
    $path = Join-Path $InstallToolsDir $_ -Resolve
    Copy-Item $path $destination
    $urlInstallPackages = $BaseUrl + "/InstallPackages.aspx?package=" + $_
    Invoke-RestMethod $urlInstallPackages -TimeoutSec $TimeoutSec -UseBasicParsing
}

Write-Host "Done!" -ForegroundColor Green













