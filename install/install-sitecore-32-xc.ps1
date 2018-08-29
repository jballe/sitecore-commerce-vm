param(
    $SitenamePrefix = "testsite",
    $Sitename = "${SitenamePrefix}.sc"
)

Push-Location "c:\install\Sitecore XC9"

# Extract files
get-childitem -filter *.zip | Where-Object { $_.Name -like "SIF.*" -or $_.Name -like "Sitecore.Commerce.Engine.SDK.*" -or $_.Name -like "Sitecore.BizFX.1*" } | ForEach-Object { Expand-Archive $_ }

# Generate certificate
$thumbprint = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $Sitename | Select-Object -ExpandProperty Thumbprint
Export-Certificate -Cert cert:\localMachine\my\${thumbprint} -FilePath storefront.engine.cer

Stop-Website "${SitenamePrefix}.xconnect"


# Rename files to prevent deploy script to accidentially use those
Get-ChildItem "Sitecore.BizFX.*.zip" | ForEach-Object { Move-Item -Path $_.Name -Destination ("Source_{0}" -f $_.Name) }
Get-ChildItem "Sitecore.Commerce.Engine.*.zip" -Exclude "Sitecore.Commerce.Engine.2.*.zip" | ForEach-Object { Move-Item -Path $_.Name -Destination ("Source_{0}" -f $_.Name) }
Get-ChildItem "Sitecore.IdentityServer.SDK.*.zip" | ForEach-Object { Move-Item -Path $_.Name -Destination ("Source_{0}" -f $_.Name) }

# Rename files to match installation script
Get-Item "Sitecore Commerce Experience Accelerator Habitat Catalog*.zip" | ForEach-Object { Move-Item -Path $_.Name -Destination ($_.Name -replace "Habitat", "Storefront Habitat") }
New-Item "Sitecore.Experience.Accelerator.Dummy\content" -ItemType Directory | Out-Null
Copy-Item "..\Sitecore Experience Accelerator WDP for 9.0.zip" -Destination "Sitecore.Experience.Accelerator.Dummy\content"

# Start installation
$sifFolder = get-childitem -filter "SIF.*" -Directory | select-object -first 1 -ExpandProperty FullName
Push-Location $sifFolder
& "./deploy-sitecore-commerce.ps1" -SiteName testsite.sc -SiteHostHeaderName testsite.sc
Pop-location