<#
.SYNOPSIS
Used for installing a basis domain controller and domain forest

.DESCRIPTION
This script installs a standard domain controller and domain forest.

.PARAMETER AdminPassword
Mandatory string paramater. It sets the value to be the local administrator password.

.PARAMETER IPAddress
Mandatory string paramater. It sets the ip address of the domain controller.

.PARAMETER DomainName
Mandatory string paramater. It sets the name fot the new domain forest

.PARAMETER DHCPRangeStart
Mandatory string paramater. It sets the start range used for DHCP in RAS

.PARAMETER DCHPRangeEnd
Mandatory string paramater. It sets the end range used for DHCP in RAS

.PARAMETER LanAdapterName
Mandatory string parameter. It sets the LAN adapters' name

.PARAMETER NatAdapterName
Mandatory string parameter. It sets the NAT adapters' name

.NOTES
File Name      : Install-AD.ps1
Author         : RoMinjun
Prerequisite   : PowerShell V5

.EXAMPLE
.\Install-AD.ps1 -AdminPassword Welkom123! -IPAddress 192.168.0.1 -DomainName kleeman.lab -DHCPRangeStart 192.168.0.50 -DHCPRangeEnd 192.168.0.150 -LanAdapterName LanConnectie -NatAdapterName NatConnectie
#>

param (
    [Parameter(Mandatory=$true,
        HelpMessage="Password used for the local administrator")]
    [SecureString]$AdminPassword,
    [Parameter(Mandatory=$true,
        HelpMessage="IPAddress used to set as IP for the domain controller")]
    [string]$IPAddress,
    [Parameter(Mandatory=$true,
        HelpMessage="The name of your domain (kleeman.lab e.g.)")]
    [string]$DomainName,
    [Parameter(Mandatory=$true,
        HelpMessage="The start of the DHCP range used for internet access on workstations in the domain")]
    [string]$DHCPRangeStart,
    [Parameter(Mandatory=$true,
        HelpMessage="The end of the DHCP range used for internet access on workstations in the domain")]
    [string]$DHCPRangeEnd,
    [Parameter(Mandatory=$true,
        HelpMessage="Name of the Adapter used for LAN")]
    [string]$LanAdapterName,
    [string]$NatAdapterName
)

Out-Null
Import-Module ADDSDeployment

#Uitzetten van de Windows Update Services
sc.exe stop wuauserv
sc.exe config wuauserv start=disabled

#Change Administrator password
net user Administrator $AdminPassword

#Adding NetAdapters and configuring with given ip address and disabling IPv6"
#Make sure you've added the NAT Adapter before you installed the custom vmnet adapter, else it's possible the wrong Ethernet adapter is used for RAS
Get-NetAdapter -Name "Ethernet0" | Rename-NetAdapter -NewName $NatAdapterName
Get-NetAdapter -Name "Ethernet1" | Rename-NetAdapter -NewName $LanAdapterName
New-NetIPAddress -InterfaceAlias $LanAdapterName -IPAddress "$IPAddress" -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "$LanAdapterName" -ServerAddresses ("$IPAddress,8.8.8.8")
Disable-NetAdapterBinding -InterfaceAlias * -ComponentID ms_tcpip6
#Installing roles & features
Install-WindowsFeature -Name AD-Domain-Services,RemoteAccess,DirectAccess-VPN,Routing,DHCP,FS-DFS-Namespace -IncludeManagementTools -Verbose

#Get Server ready for ADDS promotion
#Configuring Domain
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainNetbiosname $DomainName.split(".")[0] -DomainName "$DomainName" -DomainMode "WinThreshold" -ForestMode "WinThreshold" -InstallDNS -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -NoRebootOnCompletion -Confirm:$false -WarningAction silentlyContinue -Force:$true

#Configuring RAS
Install-RemoteAccess -VpnType Vpn
netsh routing ip nat install
netsh routing ip nat add interface $NatAdapterName
netsh routing ip nat set interface $NatAdapterName mode=full
netsh routing ip nat add interface $LanAdapterName

#Configuring DHCP scope for IPv4
$lan = Get-NetIPAddress -InterfaceAlias $LanAdapterName | Select-Object IPAddress
Add-DhcpServerInDC -IPAddress $lan
Add-DhcpServerV4Scope -Name "$DomainName Scope" -StartRange $DHCPRangeStart -EndRange $DCHPRangeEnd -SubnetMask 255.255.255.0 -LeaseDuration 7

#Disabling Enhanced security
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer

#Restart Computer
Restart-Computer -Force
