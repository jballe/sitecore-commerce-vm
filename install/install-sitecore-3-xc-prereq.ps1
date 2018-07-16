Push-Location "C:\Install"

$DOTNET_DOWNLOAD_URL="https://download.microsoft.com/download/8/8/5/88544F33-836A-49A5-8B67-451C24709A8F/dotnet-sdk-2.1.300-win-gs-x64.exe"
Invoke-WebRequest $DOTNET_DOWNLOAD_URL -OutFile dotnet.exe; `
& ./dotnet.exe /install /passive

choco install nuget.commandline

Invoke-WebRequest -WebSession $session -Uri `
    "https://dev.sitecore.net/~/media/F08E9950D0134D1DA325801057C96B35.ashx" `
    -OutFile `
    "Sitecore Experience Commerce 9.0.zip"
Expand-Archive "Sitecore Experience Commerce 9.0.zip" -DestinationPath "Sitecore XC9"
Push-Location "Sitecore XC9"

nuget install MSBuild.Microsoft.VisualStudio.Web.targets -version 14.0.0.3 -outputdir .

# Download powershell extensions
New-Item "Sitecore.Powershell.Extensions.4.7\content" -ItemType Directory | Out-Null
Invoke-WebRequest "https://github.com/SitecorePowerShell/Console/releases/download/4.7/Sitecore.PowerShell.Extensions-4.7.for.Sitecore.8.zip" -OutFile "Sitecore.Powershell.Extensions.4.7\content\Sitecore PowerShell Extensions.4.7.zip"
