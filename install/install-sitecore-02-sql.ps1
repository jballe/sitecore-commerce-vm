param(
    $SitecoreDownloadUser = $Null,
    $SitecoreDownloadPass = $Null,
    $SqlSaPassword = "HASH-posh-123-hjuG",
    $InstallToolsDir = "c:\install"
)

Push-Location $InstallToolsDir

# SQL Server from https://github.com/Microsoft/mssql-docker/blob/master/windows/mssql-server-windows-developer/dockerfile
$box = "https://go.microsoft.com/fwlink/?linkid=840944"
$exe = "https://go.microsoft.com/fwlink/?linkid=840945"

Invoke-WebRequest -Uri $box -OutFile SQL.box ;
Invoke-WebRequest -Uri $exe -OutFile SQL.exe ;
Start-Process -Wait -FilePath .\SQL.exe -ArgumentList /qs, /x:setup ;
.\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS
Remove-Item -Recurse -Force SQL.exe, SQL.box, setup

stop-service MSSQLSERVER ;
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value '' ;
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433 ;
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\' -name LoginMode -value 2 ;
start-service MSSQLSERVER
$sqlcmd = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\sqlcmd.exe"
& $sqlcmd -Q ("ALTER LOGIN sa with password=" +"'" + $SqlSaPassword + "'")
& $sqlcmd -Q "ALTER LOGIN sa ENABLE;"
& $sqlcmd -Q "sp_configure 'show advanced options', 1;"
& $sqlcmd -Q "RECONFIGURE WITH OVERRIDE;"
& $sqlcmd -Q "sp_configure 'contained database authentication', 1;"
& $sqlcmd -Q "RECONFIGURE WITH OVERRIDE;"

