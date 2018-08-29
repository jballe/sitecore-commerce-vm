param(
    $InstallToolsDir = "c:\install"
)

Uninstall-WindowsFeature -Name Windows-Defender-Features;
Uninstall-WindowsFeature -Name BitLocker;

$ErrorActionPreference = "STOP"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;


If(-not (Test-Path $InstallToolsDir -PathType Container)) {
    New-Item $InstallToolsDir -ItemType Directory | Out-Null
}
Push-Location $InstallToolsDir

# Add windows features
Add-WindowsFeature Web-Server # Might require reboot
Add-WindowsFeature Web-Asp-Net45
Add-WindowsFeature NET-WCF-HTTP-Activation45

# Some tweaks and remove default IIS site
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord;
Remove-Website -Name 'Default Web Site';

