param(
    $SitenamePrefix = "testsite",
    $Sitename = "${SitenamePrefix}.sc",
    $adminUsername = "administrator",
    $adminPassword = "Passw0rd"
)

set-ItemProperty -Path IIS:\AppPools\${Sitename} -Name processModel.identityType -value SpecificUser
set-ItemProperty -Path IIS:\AppPools\${Sitename} -Name processModel.userName -value ".\${adminUsername}"
set-ItemProperty -Path IIS:\AppPools\${Sitename} -Name processModel.password -value $adminPassword

$result = Invoke-WebRequest http://localhost -Headers @{ Host=$Sitename }

set-ItemProperty -Path IIS:\AppPools\${Sitename} -Name processModel.identityType -value ApplicationPoolIdentity
set-ItemProperty -Path IIS:\AppPools\${Sitename} -Name processModel.userName -value ""
set-ItemProperty -Path IIS:\AppPools\${Sitename} -Name processModel.password -value ""

