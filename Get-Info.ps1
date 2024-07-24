function Get-Info {
    param($ComputerName)
    #Get-WmiObject -ComputerName $ComputerName -Class Win32_operatingsystem
    Get-WmiObject -ComputerName $ComputerName -Class Win32_OperatingSystem | Select-Object -Property *
}
Get-Info -ComputerName localhost