# PSRPi

Collection of Powershell scripts to create Raspberry Pi images.



## Prerequisites

Requires [OSFMount](https://www.osforensics.com/tools/mount-disk-images.html). You can install it via Chocolatey with:

```
choco install osfmount -y
```

You may use [balenaEtcher](https://www.balena.io/etcher/) to write images to SD Card. You can install it via Chocolatey with:

```
choco install etcher -y
```



## Command summary
  - [Get-HypriotImage](#Get-HypriotImage)
  - [New-UserDataFile](#New-UserDataFile)
  - [New-CustomHypriotImage](#New-CustomHypriotImage) (*)

**(*) Requires administrative privileges**.



## Commands

### Get-HypriotImage

```
Get-HypriotImage.ps1 [[-OutputPath] <string>] [<CommonParameters>]
```

Downloads latest [Hypriot](https://blog.hypriot.com/) image and verify its integrity.

Use `-OutputPath` parameter to set download location. If not informed, the current folder will be used.

Returns the path of downloaded file.



### New-UserDataFile

```
New-UserDataFile.ps1 -HostName <string> -RootPassword <string> [-Path <string>] [-WiFiNetwork <string>] [-WiFiPassword <string>] [<CommonParam
eters>]
New-UserDataFile.ps1 -HostName <string> -RootPublicKey <string> [-Path <string>] [-WiFiNetwork <string>] [-WiFiPassword <string>] [<CommonPara
meters>]
```

Creates an `user-data` file for custom builds. See [New-CustomHypriotImage](#New-CustomHypriotImage).

You must use `-RootPassword` to set a password or `-RootPublicKey` to set a public key for default `root` user.

You may configure wireless network using `-WiFiNetwork` and `-WiFiPassword` options. 

Use `-Path` parameter to set the output file. If not informed, `.\user-data` will be used.

Returns the path of created file.



### New-CustomHypriotImage (*)

```
New-CustomHypriotImage.ps1 [-ImagePath] <string> [-UserDataPath] <string> [[-OutputPath] <string>] [<CommonParameters>]
```

Creates a custom Hypriot image for Raspberry Pi.

You must use `-ImagePath` to provide an image file. You can download Hypriot images from [here](https://github.com/hypriot/image-builder-rpi/releases). Or use [`Get-HypriotImage.ps1`](#Get-HypriotImage).

You must use `-UserDataPath` to provide an `user-data` file for initial configuration. See [New-UserDataFile](#New-UserDataFile).

Use `-OutputPath` parameter to set the output location. If not informed, the current folder will be used.

The script will temporarily mount the image on R: drive.

Returns the path of created file.

**(*) Requires administrative privileges**.



## Usage sample

```powershell
$hostname = 'rpi'
$rootPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

$userDataFile = .\New-UserDataFile.ps1 -HostName $hostname -RootPublicKey $rootPublicKey -WiFiNetwork 'darth' -WiFiPassword 'vader'

$imageFile = .\Get-HypriotImage.ps1

.\New-CustomHypriotImage.ps1 -ImagePath $imageFile -UserDataPath $userDataFile
```
