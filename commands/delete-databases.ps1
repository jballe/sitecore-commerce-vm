# Certificates
Get-ChildItem Cert:\CurrentUser\My\ | WHere-Object { $_.Subject -like "CN=DO_NOT_TRUST_Sitecore*" } | Remove-Item
Get-ChildItem Cert:\LocalMachine\Root\ | WHere-Object { $_.Subject -like "CN=DO_NOT_TRUST_Sitecore*" } | Remove-Item

# XConnect databases
sqlcmd -Q "drop database [testsite_Processing.Pools]"
sqlcmd -Q "drop database [testsite_MarketingAutomation]"
sqlcmd -Q "drop database [testsite_Messaging]"
sqlcmd -Q "drop database [testsite_ReferenceData]"
sqlcmd -Q "drop database [testsite_Xdb.Collection.ShardMapManager]"
sqlcmd -Q "drop database [testsite_Xdb.Collection.Shard0]"
sqlcmd -Q "drop database [testsite_Xdb.Collection.Shard1]"

# Sitecore instance
sqlcmd -Q "drop database [testsite_Core]"
sqlcmd -Q "drop database [testsite_Master]"
sqlcmd -Q "drop database [testsite_Web]"
sqlcmd -Q "drop database [testsite_ExperienceForms]"
sqlcmd -Q "drop database [testsite_EXM.Master]"
sqlcmd -Q "drop database [testsite_Reporting]"
sqlcmd -Q "drop database [testsite_Processing.Tasks]"

sqlcmd -Q "SELECT name from sysdatabases"