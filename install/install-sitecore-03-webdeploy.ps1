param(
    $InstallToolsDir = "c:\install"
)

push-Location $InstallToolsDir

# Install dependencies
Invoke-WebRequest -Uri "http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi" -OutFile "webdeploy.msi" ;
Start-Process msiexec.exe -ArgumentList '/i', "webdeploy.msi", '/quiet', '/norestart' -NoNewWindow -Wait;
Invoke-WebRequest -Uri "http://download.microsoft.com/download/D/D/E/DDE57C26-C62C-4C59-A1BB-31D58B36ADA2/rewrite_amd64_en-US.msi" -OutFile "rewrite.msi";
Start-Process msiexec.exe -ArgumentList '/i', "rewrite.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Invoke-WebRequest -Uri "https://aka.ms/vs/15/release/VC_redist.x64.exe" -OutFile "VC_redist.msi";
Start-Process msiexec.exe -ArgumentList '/i', "VC_redist.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Invoke-WebRequest -Uri "https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x86/DacFramework.msi" -OutFile "DacFramework86.msi";
Invoke-WebRequest -Uri "https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x64/DacFramework.msi" -OutFile "DacFramework64.msi";
Start-Process msiexec.exe -ArgumentList '/i', "DacFramework86.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Start-Process msiexec.exe -ArgumentList '/i', "DacFramework64.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?LinkID=849415&clcid=0x409" -OutFile "SqlSysClrTypes.msi";
Start-Process msiexec.exe -ArgumentList '/i', "SqlSysClrTypes.msi", '/quiet', '/norestart' -NoNewWindow -Wait; 
Remove-Item webdeploy.msi ;
Remove-Item rewrite.msi ;
Remove-Item VC_redist.msi ;
Remove-Item DacFramework86.msi;
Remove-Item DacFramework64.msi;
Remove-Item SqlSysClrTypes.msi;
