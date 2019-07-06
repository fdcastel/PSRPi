[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

# Note: Github removed TLS 1.0 support. Enables TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol-bor 'Tls12'

# Get latest release information
$repository = 'hypriot/image-builder-rpi'
$latestRelease = Invoke-WebRequest "https://api.github.com/repos/$repository/releases/latest" -UseBasicParsing | ConvertFrom-Json
$assetsUrl = $latestRelease.assets_url
$assets = Invoke-WebRequest $assetsUrl -UseBasicParsing | ConvertFrom-Json

if (-not $OutputPath) {
    $OutputPath = Get-Item '.\'
}

$zipFile = $assets | Where-Object { $_.name -like '*.zip' }
$zipFilePath = Join-Path $OutputPath $zipFile.name

if ([System.IO.File]::Exists($zipFilePath)) {
    Write-Verbose "File '$zipFilePath' already exists. Nothing to do."
} else {
    Write-Verbose "Downloading file '$zipFilePath'..."

    $client = New-Object System.Net.WebClient
    $client.DownloadFile($zipFile.browser_download_url, $zipFilePath)

    Write-Verbose "Checking file integrity..."
    $hashFile = $assets | Where-Object { $_.name -like '*.sha256' }
    $allHashs = $client.DownloadString($hashFile.browser_download_url)
    $m = [regex]::Matches($allHashs, "(?<Hash>\w{64})\s+$($zipFile.name)")
    if (-not $m[0]) { throw "Cannot get SHA1 hash for $urlFile." }
    $expectedHash = $m[0].Groups['Hash'].Value

    $sha256Hash = Get-FileHash $zipFilePath -Algorithm SHA256
    if ($sha256Hash.Hash -ne $expectedHash) { throw "Integrity check for '$zipFilePath' failed." }
}

# Returns the path of downloaded file
$zipFilePath
