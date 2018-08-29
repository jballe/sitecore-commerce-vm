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
$destination = "c:\inetpub\wwwroot\${Sitename}\sitecore\admin\Packages"
@("Sitecore Powershell Extensions*.zip", "Sitecore Experience Accelerator*.zip") | ForEach-Object {
    $item = Get-Item $_ | Select-Object -First 1 -ExpandProperty Name
    try {
        Write-Host "  Installing ${item}... "
        $path = Join-Path $InstallToolsDir $item -Resolve
        Copy-Item $path $destination
        $urlInstallPackages = $BaseUrl + "/InstallPackages.aspx?package=" + $item
        Invoke-RestMethod $urlInstallPackages -TimeoutSec $TimeoutSec -UseBasicParsing
        Remove-Item (Join-Path $destination $item)
    } catch {
        Write-Warning "Error while installing ${item}"
    }
}

Write-Host "Done!" -ForegroundColor Green













