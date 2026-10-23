$ErrorActionPreference = "Stop"
$ApiBase = if ($env:CRABYARD_API_URL) { $env:CRABYARD_API_URL.TrimEnd('/') } else { "https://crabyard-api-production.up.railway.app" }
$InstallDir = if ($env:CRABYARD_INSTALL_DIR) { $env:CRABYARD_INSTALL_DIR } else { Join-Path $HOME ".crabyard\bin" }
$version = if ($env:CRABYARD_VERSION) { $env:CRABYARD_VERSION } else { (Invoke-RestMethod -Uri "$ApiBase/cli/latest").version }
if (-not $version) { throw "Could not determine the CLI release version" }
$existing = Get-Command crabyard -ErrorAction SilentlyContinue
$current = if ($existing) { & $existing.Source --version 2>$null } else { "" }
$currentVersion = if ($current -match '(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)') { $Matches[1] } else { "" }
$exe = if ($existing) { $existing.Source } else { "" }
if (-not $exe -or $currentVersion -ne $version.TrimStart('v')) {
    $response = Invoke-WebRequest -Uri https://crabyard.dev/install.ps1 -UseBasicParsing
    $installer = if ($response.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($response.Content) } else { $response.Content }
    $previousVersion = $env:CRABYARD_VERSION
    try {
        $env:CRABYARD_VERSION = $version
        & ([ScriptBlock]::Create($installer))
    } finally {
        $env:CRABYARD_VERSION = $previousVersion
    }
    $exe = Join-Path $InstallDir "crabyard.exe"
}
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    $response = Invoke-WebRequest -Uri https://bun.sh/install.ps1 -UseBasicParsing
    $bunInstaller = if ($response.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($response.Content) } else { $response.Content }
    & ([ScriptBlock]::Create($bunInstaller))
    $env:PATH = "$(Join-Path $HOME '.bun\bin');$env:PATH"
}
Write-Host "`nStarting project wizard...`n"
& $exe new @args
