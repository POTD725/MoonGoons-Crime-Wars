param(
    [string]$ProjectPath = "C:\A1\MoonGoons-Crime-Wars-Clean",
    [string]$AssetZip = "$env:USERPROFILE\Downloads\MoonGoons_Core_PNG_Assets.zip",
    [switch]$CommitToGitHub
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProjectPath)) {
    throw "Project folder not found: $ProjectPath"
}
if (-not (Test-Path $AssetZip)) {
    throw "Asset ZIP not found: $AssetZip"
}

$temp = Join-Path $env:TEMP ("MoonGoonsCoreArt_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $temp -Force | Out-Null

try {
    Expand-Archive -LiteralPath $AssetZip -DestinationPath $temp -Force
    $source = Join-Path $temp "MoonGoons_Core_PNG_Assets\assets\graphics"
    if (-not (Test-Path $source)) {
        throw "The ZIP does not contain the expected assets\graphics folder."
    }

    $destination = Join-Path $ProjectPath "assets\graphics"
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Copy-Item -Path (Join-Path $source "*") -Destination $destination -Recurse -Force

    Write-Host "Core PNG assets installed under: $destination" -ForegroundColor Cyan
    Get-ChildItem $destination -Recurse -Filter *.png | Select-Object FullName, Length

    if ($CommitToGitHub) {
        Push-Location $ProjectPath
        try {
            git add assets/graphics
            git commit -m "art: add core MoonGoons PNG asset pack"
            git push origin main
        }
        finally {
            Pop-Location
        }
    }
}
finally {
    Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}
