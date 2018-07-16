param(
    $VMName = "Sitecore XC9",
    $Sitename = "testsite.sc"
)

$ip = Get-VMNetworkAdapter -VMName $VMName | Select-object -expandproperty IPAddresses | select-object -first 1
invoke-webrequest -Uri "http://${ip}" -Headers @{ Host=$Sitename } -UseBasicParsing