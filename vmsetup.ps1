# I prefer running from my local computer using Enter-PSSession so the only commands I execute directory on VM is:
Enable-PSRemoting -SkipNetworkProfileCheck -Force;
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any;
# Disable UAC
Set-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0;
