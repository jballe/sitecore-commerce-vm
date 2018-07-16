param(
    $VMName = "Sitecore XC9",
    $Sitename = "testsite.sc",
    $Lines = 100,
    $session = $null
)

if($session -eq $null) {
    $session = new-pssession -VMName $VMName
}
Invoke-Command -Session $session -ScriptBlock { `
    param($sitename, $lines) 
    Import-Module WebAdministration
    $path = Get-Website -Name $sitename | Select-Object -ExpandProperty PhysicalPath
    $file = get-childitem "${path}\App_data\logs" -Filter "log*.txt" | Select-Object -last 1 | Select-Object -ExpandProperty FullName
    Get-Content $file -Tail $lines
} -ArgumentList $Sitename, $Lines

