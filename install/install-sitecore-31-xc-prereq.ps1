param(
    $SitecoreDownloadUser = $Null,
    $SitecoreDownloadPass = $Null,
    $InstallToolsDir = $PSScriptRoot
)

Push-Location $InstallToolsDir

$DOTNET_DOWNLOAD_URL="https://download.microsoft.com/download/1/f/7/1f7755c5-934d-4638-b89f-1f4ffa5afe89/dotnet-hosting-2.1.2-win.exe"
Invoke-WebRequest $DOTNET_DOWNLOAD_URL -OutFile dotnet-hosting.exe; `
& ./dotnet-hosting.exe /install /passive

choco install nuget.commandline

# Download sitecore files
if($SitecoreDownloadUser -eq $Null) {
    $SitecoreDownloadUser = (Read-Host "Enter username for Sitecore site")
}
if($SitecoreDownloadPass -eq $Null) {
    $SitecoreDownloadPass = (Read-Host "Enter password for ${SitecoreDownloadUser}")
}

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
    "https://dev.sitecore.net/~/media/F374366CA5C649C99B09D35D5EF1BFCE.ashx" `
    -OutFile `
    "Sitecore.Commerce.2018.07-2.2.126.zip"
Expand-Archive "Sitecore.Commerce.*.zip" -DestinationPath "Sitecore XC9"
Push-Location "Sitecore XC9"

nuget install MSBuild.Microsoft.VisualStudio.Web.targets -version 14.0.0.3 -outputdir .

# Download powershell extensions
New-Item "Sitecore.Powershell.Extensions.4.7\content" -ItemType Directory | Out-Null
Invoke-WebRequest "https://github.com/SitecorePowerShell/Console/releases/download/4.7/Sitecore.PowerShell.Extensions-4.7.for.Sitecore.8.zip" -OutFile "Sitecore.Powershell.Extensions.4.7\content\Sitecore PowerShell Extensions.4.7.zip"
