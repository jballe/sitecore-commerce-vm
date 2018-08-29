param(
    $password = "Passw0rd",
    $username = "administrator",
    $vmName = "SitecoreXC902",
    $localLicenseFile = "E:\Install\Sitecore\license.xml",
    $scriptFile = "$PSScriptRoot\..\install\install-sitecore-0-prereq.ps1",
    $InstallToolsDir = "c:\install",
    $sitecoreUser = "balle@scouts.dk",
    $sitecorePass = ""

)

$ErrorActionPreference = "STOP"

# Now connect...
if($password -eq $Null) {
    $password = (Read-Host "Enter vm administrator password...")
}

$password = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("administrator", $password)
$session = New-PSSession -VMName $vmName -Credential $cred
Invoke-Command -Session $session -ScriptBlock { If(-not (Test-Path c:\install)) { mkdir c:\install } }
copy-item -ToSession $session -Destination $InstallToolsDir\license.xml -Path $localLicenseFile -Force
copy-item -ToSession $session -Destination $InstallToolsDir -Path (Join-Path $PSScriptRoot "..\install\*.ps1") -Force

If($sitecoreUser -eq $Null) { $sitecoreUser = (Read-Host "Enter username for Sitecore site") }
If($sitecorePass -eq $Null) { $sitecorePass = (Read-Host "Enter password for ${sitecoreUser}")  }

$fileArgs = @{
    SitecoreDownloadUser= $sitecoreUser
    SitecoreDownloadPass=$sitecorePass
    InstallToolsDir=$InstallToolsDir
    adminUsername=$username
    adminPassword=$password
}
Write-Host "Running $localScript"
Invoke-Command -Session $session -File "${scriptFile}" -ArgumentList $fileArgs

Remove-Session $session