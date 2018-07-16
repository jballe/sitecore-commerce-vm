param(
    $password = "Passw0rd",
    $localLicenseFile = "E:\Install\Sitecore\license.xml"
)
K# $serverip = "WIN-A72Q3IPEUF8"
$hypervname = "Sitecore Experience Commerce Passw0rd"
$serverip = (Get-VMNetworkAdapter -VmName $hypervname | Select-Object -ExpandProperty IPAddresses)[0]
# This should just be run initially (and as administrator)
set-item WSMan:\localhost\Client\allowunencrypted $true
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $serverip # or just "*"

$localScript = "${PSScriptRoot}\install.ps1"

# Now connect...
if($password -eq $Null) {
    $password = (Read-Host "Enter vm administrator password...")
}

$password = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("administrator", $password)
$session = New-PSSession -ComputerName $serverip -Credential $cred -EnableNetworkAccess -Authentication Negotiate
copy-item -ToSession $session -Destination c:\ -Path $localLicenseFile

$sitecoreUser = (Read-Host "Enter username for Sitecore site")
$sitecorePass = (Read-Host "Enter password for ${sitecoreUser}")

$fileArgs = @{
    SitecoreDownloadUser= $sitecoreUser; 
    SitecoreDownloadPass=$sitecorePass;
    InstallToolsDir="c:\install"
}
Invoke-Command -Session $session -File install-sitecore.ps1 -ArgumentList $fileArgs
