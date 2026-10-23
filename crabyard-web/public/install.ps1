$ErrorActionPreference = "Stop"
$ApiBase = if ($env:CRABYARD_API_URL) { $env:CRABYARD_API_URL.TrimEnd('/') } else { "https://crabyard-api-production.up.railway.app" }
$InstallDir = if ($env:CRABYARD_INSTALL_DIR) { $env:CRABYARD_INSTALL_DIR } else { Join-Path $HOME ".crabyard\bin" }
$target = "x86_64-pc-windows-msvc"
$version = if ($env:CRABYARD_VERSION) { $env:CRABYARD_VERSION } else { (Invoke-RestMethod -Uri "$ApiBase/cli/latest").version }
if (-not $version) { throw "Could not determine the CLI release version" }
$url = "$ApiBase/cli/download/${target}?version=$([Uri]::EscapeDataString($version))"
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempDir = [IO.Path]::GetFullPath((Join-Path $tempRoot ([IO.Path]::GetRandomFileName())))
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    Write-Host "Installing crabyard $version ($target)..."
    $archive = Join-Path $tempDir "crabyard.zip"
    Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
    $checksumResponse = Invoke-WebRequest -Uri "${url}&checksum=1" -UseBasicParsing
    $expected = ($checksumResponse.Content.Trim() -split '\s+')[0]
    if ($expected -notmatch '^[a-fA-F0-9]{64}$') { throw "Invalid release checksum" }
    $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actual -ne $expected) { throw "Release checksum mismatch" }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $entry = $zip.GetEntry("crabyard.exe")
        if (-not $entry) { throw "Archive does not contain the CLI binary" }
        $binary = Join-Path $tempDir "crabyard.exe"
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $binary)
    } finally {
        $zip.Dispose()
    }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    $destination = Join-Path $InstallDir "crabyard.exe"
    Move-Item -LiteralPath $binary -Destination $destination -Force
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($InstallDir -notin ($userPath -split ';')) {
        [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$userPath", "User")
    }
    if ($InstallDir -notin ($env:PATH -split ';')) { $env:PATH = "$InstallDir;$env:PATH" }
    Write-Host "Installed to $destination. Run 'crabyard --help' to get started."
} finally {
    $resolvedTemp = [IO.Path]::GetFullPath($tempDir)
    if (-not $resolvedTemp.StartsWith($tempRoot.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a path outside the temporary directory"
    }
    Remove-Item -LiteralPath $resolvedTemp -Recurse -Force -ErrorAction SilentlyContinue
}
