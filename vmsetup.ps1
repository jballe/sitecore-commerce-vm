# I prefer running from my local computer so the only commands I execute directory on VM is:
Enable-PSRemoting -SkipNetworkProfileCheck -Force;  
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any
# Disable UAC
reg save HKLM\Software\Microsoft\Windows\CurrentVersion\policies\system /v EnableLUA /t Reg_DWORD /d 0 
