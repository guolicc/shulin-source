param(
    [string]$Alias = "shulin-page.vercel.app"
)

$ErrorActionPreference = "Stop"

$SourceRoot = Split-Path -Parent $PSCommandPath
$DistRoot = Join-Path $SourceRoot "dist"

Set-Location $SourceRoot
npm run build -- --base=/

Set-Location $DistRoot
$Output = npx --yes vercel@latest deploy . --prod --yes --public
$Output | Write-Host

$ProductionMatch = $Output | Select-String -Pattern "Production:\s+(https://\S+)" | Select-Object -Last 1
$DeploymentUrl = $null
if ($ProductionMatch -and $ProductionMatch.Matches.Count -gt 0) {
    $DeploymentUrl = $ProductionMatch.Matches[0].Groups[1].Value
}

if (-not $DeploymentUrl) {
    $JsonMatch = $Output | Select-String -Pattern '"url":\s+"(https://[^"]+)"' | Select-Object -First 1
    if ($JsonMatch -and $JsonMatch.Matches.Count -gt 0) {
        $DeploymentUrl = $JsonMatch.Matches[0].Groups[1].Value
    }
}

if (-not $DeploymentUrl) {
    throw "Could not find Vercel deployment URL in CLI output."
}

npx --yes vercel@latest alias set $DeploymentUrl $Alias
