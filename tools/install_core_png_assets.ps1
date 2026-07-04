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
    throw "Asset ZIP not found: $AssetZip`nDownload the ZIP from this chat first, then save it with this exact filename in Downloads."
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

    $assetFolders = @("structures", "troops", "defenses", "resources", "environment")
    foreach ($folder in $assetFolders) {
        $from = Join-Path $source $folder
        $to = Join-Path $destination $folder
        if (Test-Path $from) {
            New-Item -ItemType Directory -Path $to -Force | Out-Null
            Copy-Item -Path (Join-Path $from "*.png") -Destination $to -Force
        }
    }

    $installed = Get-ChildItem $destination -Recurse -Filter *.png | Where-Object {
        $_.FullName -match "\\(structures|troops|defenses|resources|environment)\\"
    }
    Write-Host "Installed $($installed.Count) core PNG asset(s) under: $destination" -ForegroundColor Cyan
    $installed | Select-Object FullName, Length

    if ($CommitToGitHub) {
        Push-Location $ProjectPath
        try {
            git add -- "assets/graphics/structures/*.png" "assets/graphics/troops/*.png" "assets/graphics/defenses/*.png" "assets/graphics/resources/*.png" "assets/graphics/environment/*.png"
            git diff --cached --quiet
            if ($LASTEXITCODE -eq 0) {
                Write-Host "No new PNG files needed committing." -ForegroundColor Yellow
            }
            else {
                git commit -m "art: add core MoonGoons PNG asset pack"
                git push origin main
            }
        }
        finally {
            Pop-Location
        }
    }
}
finally {
    Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}
