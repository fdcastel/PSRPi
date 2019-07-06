#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ImagePath,
    
    [Parameter(Mandatory=$true)]
    [string]$UserDataPath,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if (-not $OutputPath) {
    $OutputPath = Get-Item '.\'
}

$image = Get-Item $ImagePath
if ($image.Extension -eq '.zip') {
    Write-Verbose "Extracting image to '$OutputPath'..."
    Expand-Archive $ImagePath -DestinationPath $OutputPath -Force

    $image = Get-Item "$OutputPath\*.img" | Sort-Object -Property LastWriteTime | Select-Object -First 1
    $outputImage = $image.FullName
} else {
    $outputImage = Join-Path $OutputPath $image.name
    Write-Verbose "Copying image to '$outputImage'..."
    Copy-Item $ImagePath $outputImage
}



$osfmount = 'C:\Program Files\OSFMount\OSFMount.com'

Write-Verbose "Mounting image..."
& $osfmount -a -t file -m R: -o rw -f $outputImage
try {
    Start-Sleep -Seconds 2
    Write-Verbose "Copying 'user-data'..."
    Copy-Item $UserDataPath 'R:\user-data'
}
finally {
    Write-Verbose "Unmounting image..."
    & $osfmount -d -m R:
}

# Returns the path of created file
$outputImage