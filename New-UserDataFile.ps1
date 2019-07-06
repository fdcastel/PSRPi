[CmdletBinding()]
param(
    [string]$Path,
    
    [Parameter(Mandatory=$true)]
    [string]$HostName,

    [Parameter(Mandatory=$true, ParameterSetName='RootPassword')]
    [string]$RootPassword,

    [Parameter(Mandatory=$true, ParameterSetName='RootPublicKey')]
    [string]$RootPublicKey,

    [string]$WiFiNetwork,

    [string]$WiFiPassword
)

$ErrorActionPreference = 'Stop'

if (-not $Path) {
    $Path = '.\user-data'
}

if ($WiFiNetwork) {
    $WiFiContent = @"

 - content: |
       allow-hotplug wlan0
       iface wlan0 inet dhcp
       wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
       iface default inet dhcp
   path: /etc/network/interfaces.d/wlan0

 - content: |
       ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
       update_config=1
       network={
           ssid="$WiFiNetwork"
           psk="$WiFiPassword"
           proto=RSN
           key_mgmt=WPA-PSK
           pairwise=CCMP
           auth_alg=OPEN
       }
   path: /etc/wpa_supplicant/wpa_supplicant.conf

"@

    $WiFiRunCmd = @"
 - 'ifup wlan0'                        # Activate WiFi interface

"@
}

$sectionPasswd = if ($RootPassword) {
    @"
password: $RootPassword
chpasswd: { expire: False }
ssh_pwauth: True
"@
} elseif ($RootPublicKey) {
    @"
ssh_authorized_keys:
  - $RootPublicKey
"@
}

$sectionWriteFiles = @"
write_files:
 - content: |
     \S{PRETTY_NAME} \n \l

     eth0: \4{eth0}
     wlan0: \4{wlan0}
     
   path: /etc/issue
   owner: root:root
   permissions: '0644'
$WiFiContent
"@

$sectionRunCmd = @"
runcmd:
 - 'systemctl restart avahi-daemon'    # Pickup the hostname changes
$WiFiRunCmd
"@

$userdata = @"
#cloud-config
# vim: syntax=yaml
#

hostname: $HostName
manage_etc_hosts: true

$sectionPasswd

$sectionWriteFiles
$sectionRunCmd
"@

# Save output file
$userdata | Out-File $Path -Encoding ascii

# Returns the path of created file
$Path
