# Script name:      maintanance-server.ps1
# Version:          v1.1
# Created on:       19/07/2021
# Author:           Mikel
# On Github:        https://github.com/willemdh/check_ms_iis_application_pool
# Copyright:
#   This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published
#   by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed 
#   in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
#   PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public 
#   License along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Requires -Version 2.0
$ALIAS = read-host "ALIAS"

$HOSTNAME = read-host "HOSTNAME"

$IP = read-host "IP"

$PhysicalPath = "C:\SmarterTools\SmarterMail\MRS"

$ThumbPrint = "CAD5EC9ABE94BB6CEC4FEFDC6E5B8A0EB828434F"

$StoreLocation = "Cert:\LocalMachine\My"

#Import Module for WebAdministration
Import-Module WebAdministration

#Create Application Pools
New-WebAppPool -Name $HOSTNAME

#Create Site
New-IISSite -Name $HOSTNAME -BindingInformation $IP":80:"$HOSTNAME -PhysicalPath $PhysicalPath -Passthru
New-IISSiteBinding -Name $HOSTNAME -BindingInformation $IP":443:"$HOSTNAME -CertificateThumbPrint $ThumbPrint -CertStoreLocation $StoreLocation -Protocol https -SslFlag 1

#Change Application Pools for Sites
Set-ItemProperty "IIS:\Sites\"$HOSTNAME applicationPool $HOSTNAME

#Change Hostname
Rename-Computer -ComputerName "SV48DXX" -NewName "$ALIAS" -Restart