param(
    [string]$Message = "Publish built site"
)

$ErrorActionPreference = "Stop"

$SourceRoot = Split-Path -Parent $PSCommandPath
$WorkspaceRoot = Split-Path -Parent $SourceRoot
$PublicRoot = Join-Path $WorkspaceRoot "shulin-public"
$DistRoot = Join-Path $SourceRoot "dist"
$PublicRepo = "https://github.com/guolicc/shulin-page.git"

Set-Location $SourceRoot
npm run build

if (-not (Test-Path -LiteralPath $PublicRoot)) {
    git clone $PublicRepo $PublicRoot
}

$ResolvedWorkspace = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
$ResolvedPublic = (Resolve-Path -LiteralPath $PublicRoot).Path

if ((Split-Path -Leaf $ResolvedPublic) -ne "shulin-public") {
    throw "Refusing to publish: unexpected public directory '$ResolvedPublic'."
}

if (-not $ResolvedPublic.StartsWith($ResolvedWorkspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to publish: public directory is outside workspace."
}

if (-not (Test-Path -LiteralPath (Join-Path $ResolvedPublic ".git"))) {
    throw "Refusing to publish: '$ResolvedPublic' is not a git repository."
}

Get-ChildItem -LiteralPath $ResolvedPublic -Force |
    Where-Object { $_.Name -ne ".git" } |
    Remove-Item -Recurse -Force

Copy-Item -Path (Join-Path $DistRoot "*") -Destination $ResolvedPublic -Recurse -Force
New-Item -ItemType File -Path (Join-Path $ResolvedPublic ".nojekyll") -Force | Out-Null

Set-Location $ResolvedPublic
git config user.name "guolicc"
git config user.email "guolicc@users.noreply.github.com"
git add -A

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "No public build changes to publish."
    exit 0
}

git commit -m $Message
git push origin main
