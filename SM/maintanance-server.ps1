# Script name:      maintanance-server.ps1
# Version:          v1.3
# Created on:       21/07/2021
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

# Import Module for WebAdministration
Import-Module WebAdministration

# Create Application Pools
New-WebAppPool -Name $HOSTNAME

# Create Site
New-IISSite -Name $HOSTNAME -BindingInformation $IP":80:"$HOSTNAME -PhysicalPath $PhysicalPath -Passthru
New-IISSiteBinding -Name $HOSTNAME -BindingInformation $IP":443:"$HOSTNAME -CertificateThumbPrint $ThumbPrint -CertStoreLocation $StoreLocation -Protocol https -SslFlag 1

# Change Application Pools for Sites
Set-ItemProperty "IIS:\Sites\"$HOSTNAME applicationPool $HOSTNAME

# Change Hostname
Rename-Computer -ComputerName "SV48DXX" -NewName "$ALIAS" -Restart

# Change the server's SmarterMail
((Get-Content -path C:\SmarterTools\SmarterMail\Service\Settings\settings.json -Raw) -replace "sv48dxx.emailserver.vn","$HOSTNAME") | Set-Content -Path C:\SmarterTools\SmarterMail\Service\Settings\settings.json
((Get-Content -path C:\SmarterTools\SmarterMail\Service\Settings\settings.json -Raw) -replace "103.15.48.XX","$IP") | Set-Content -Path C:\SmarterTools\SmarterMail\Service\Settings\settings.json
((Get-Content -path C:\SmarterTools\SmarterMail\Service\Settings\settings.json -Raw) -replace "192.168.48.XX","$IPv4_LAN_NEW") | Set-Content -Path C:\SmarterTools\SmarterMail\Service\Settings\settings.json

# Change the server's Monitor
((Get-Content -path C:\zabbix-agent\zabbix_agentd.conf -Raw) -replace "sv48dxx.emailserver.vn","$HOSTNAME") | Set-Content -Path C:\zabbix-agent\zabbix_agentd.conf
((Get-Content -path C:\zabbix-agent\scripts\INFO-Master.ps1 -Raw) -replace "sv48dxx.emailserver.vn","$HOSTNAME") | Set-Content -Path C:\zabbix-agent\scripts\INFO-Master.ps1
((Get-Content -path C:\zabbix-agent\scripts\mailstorediskusage.ps1 -Raw) -replace "sv48dxx.emailserver.vn","$HOSTNAME") | Set-Content -Path C:\zabbix-agent\scripts\mailstorediskusage.ps1

# Change the server's Elastic
((Get-Content -path C:\Program Files\Filebeat\filebeat.yml -Raw) -replace "192.168.48.XX","$IPv4_LAN_NEW") | Set-Content -Path C:\Program Files\Filebeat\filebeat.yml
((Get-Content -path C:\Logstash\config\logstash.yml -Raw) -replace "192.168.48.XX","$IPv4_LAN_NEW") | Set-Content -Path C:\Logstash\config\logstash.yml
((Get-Content -path C:\Logstash\config\logstash.yml -Raw) -replace "XX","$ALIAS") | Set-Content -Path C:\Logstash\config\logstash.yml
((Get-Content -path C:\Logstash\config\conf.d\sm\11_sm.conf -Raw) -replace "192.168.48.XX","$IPv4_LAN_NEW") | Set-Content -Path C:\Logstash\config\conf.d\sm\11_sm.conf

# Start Up Logstash

# Start Up Filebeat

# Create Task Scheduler Backup Config SmarterMail
## Create a new task action
$Action = New-ScheduledTaskAction -Execute 'powershell' -Argument '-File C:\rclone\backup-smartermail.ps1'

## Create a new trigger (Daily at 5 AM)
$Trigger = New-ScheduledTaskTrigger -Daily -At 5am

## Set the task compatibility value to Windows Server 2019.
$Settings = New-ScheduledTaskSettingsSet -Compatibility Win8

## Set the task principal's user ID
$Principal = New-ScheduledTaskPrincipal -UserId 'Administrator' -LogonType "S4U" -Id Author

## Create a new Scheduled Task object using the imported values
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal

## Register the scheduled task
Register-ScheduledTask -TaskName 'SmarterMail-Backup-Settings' -InputObject $Task

