[CmdletBinding()]
param(
    [string]$Path,
    
    [Parameter(Mandatory=$true)]
    [string]$HostName,

    [Parameter(Mandatory=$true)]
    [string]$UserName,

    [Parameter(Mandatory=$true, ParameterSetName='UserPassword')]
    [string]$UserPassword,

    [Parameter(Mandatory=$true, ParameterSetName='UserPublicKey')]
    [string]$UserPublicKey,

    [string]$WiFiSsid,

    [string]$WiFiPassword
)

$ErrorActionPreference = 'Stop'

if (-not $Path) {
    $Path = '.\user-data'
}

if ($WiFiSsid) {
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
           ssid="$WiFiSsid"
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

$sectionUsersPassword = if ($UserPassword) {
    @"
    plain_text_passwd: $UserPassword
    lock_passwd: false
    ssh_pwauth: true
"@
} elseif ($UserPublicKey) {
    @"
    ssh_authorized_keys:
      - $UserPublicKey
"@
}

$sectionUsers = @"
users:
  - name: $UserName
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: users,docker,video,input
$sectionUsersPassword
    chpasswd: { expire: false }
"@

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

$sectionUsers

$sectionWriteFiles
$sectionRunCmd
"@

# Save output file
$userdata | Out-File $Path -Encoding ascii

# Returns the path of created file
$Path
