param(
    $SitecoreDownloadUser = $Null,
    $SitecoreDownloadPass = $Null,
    $InstallToolsDir = $PSScriptRoot
)

if($SitecoreDownloadUser -eq $Null) {
    $SitecoreDownloadUser = (Read-Host "Enter username for Sitecore site")
}
if($SitecoreDownloadPass -eq $Null) {
    $SitecoreDownloadPass = (Read-Host "Enter password for ${SitecoreDownloadUser}")
}

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
    "https://dev.sitecore.net/~/media/F53E9734518E47EF892AD40A333B9426.ashx" `
    -OutFile `
    "Sitecore 9.0.2 rev. 180604 (WDP XP0 packages).zip"
Invoke-WebRequest -WebSession $session -Uri `
    "https://dev.sitecore.net/~/media/3BFEB7C427D040178E619522EA272ECC.ashx" `
    -OutFile `
    "Web Forms for Marketers 9.0 rev. 180503.zip"

Invoke-WebRequest -WebSession $session -Uri `
    "https://dev.sitecore.net/~/media/1FF242BE683E4DE989925F74B78978FC.ashx" `
    -OutFile `
    "Sitecore Experience Accelerator 1.7.1 rev. 180604 for 9.0.zip"

# Extract Sitecore XP installation files
Expand-Archive "Sitecore * (WDP XP0 packages).zip" -Destination "XP"
Push-Location "XP"
Expand-Archive "XP0 Configuration files*.zip" -DestinationPath $PWD