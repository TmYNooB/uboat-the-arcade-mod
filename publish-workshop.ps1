param(
    [string]$SteamUser,
    [string]$ChangeNote,
    [string]$ChangelogPath = "CHANGELOG.md",
    [ValidateSet("0", "1", "2")]
    [string]$Visibility = "0",
    [string]$SteamCmdPath,
    [switch]$IncludeSource,
    [switch]$SkipUpdate,
    [switch]$SkipPackaging,
    [switch]$SkipVersionBump,
    [switch]$SkipChangelog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$updateScript = Join-Path $root "update-mod.ps1"
$uploadScript = Join-Path $root "steam-upload.ps1"
$manifestPath = Join-Path $root "Manifest.json"

function Resolve-OptionalPath {
    param(
        [string]$BasePath,
        [string]$InputPath
    )

    if ([System.IO.Path]::IsPathRooted($InputPath)) {
        return $InputPath
    }
    return (Join-Path $BasePath $InputPath)
}

function Increment-Version {
    param([string]$Version)

    if (-not $Version) {
        return "1.0"
    }

    $parts = $Version.Split('.')
    if ($parts.Count -eq 0) {
        return "1.0"
    }

    $lastIndex = $parts.Count - 1
    $lastNumber = 0
    if (-not [int]::TryParse($parts[$lastIndex], [ref]$lastNumber)) {
        throw "Manifest version '$Version' is not numeric enough to bump automatically."
    }

    $parts[$lastIndex] = [string]($lastNumber + 1)
    return ($parts -join '.')
}

if (-not (Test-Path -LiteralPath $uploadScript)) {
    throw "Missing script: $uploadScript"
}

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing manifest: $manifestPath"
}

$resolvedChangelog = Resolve-OptionalPath -BasePath $root -InputPath $ChangelogPath
if (-not $SkipChangelog -and -not (Test-Path -LiteralPath $resolvedChangelog)) {
    throw "Changelog not found: $resolvedChangelog"
}

if (-not $SkipUpdate) {
    if (-not (Test-Path -LiteralPath $updateScript)) {
        throw "Missing script: $updateScript"
    }

    Write-Host "[STEP] Running update-mod.ps1" -ForegroundColor Cyan
    & $updateScript
    if ($LASTEXITCODE -ne 0) {
        throw "update-mod.ps1 failed with exit code $LASTEXITCODE"
    }
}

if (-not $SkipVersionBump) {
    Write-Host "[STEP] Bumping version in Manifest.json" -ForegroundColor Cyan
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $oldVersion = [string]$manifest.version
    $manifest.version = Increment-Version -Version $oldVersion
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Write-Host "[INFO] Version bumped: $oldVersion -> $($manifest.version)" -ForegroundColor Yellow
}

Write-Host "[STEP] Running steam-upload.ps1" -ForegroundColor Cyan
$uploadParams = @{
    SteamUser     = $SteamUser
    ChangeNote    = $ChangeNote
    Visibility    = $Visibility
    SteamCmdPath  = $SteamCmdPath
    IncludeSource = [bool]$IncludeSource
    SkipPackaging = [bool]$SkipPackaging
}

if (-not $SkipChangelog) {
    $uploadParams.ChangeNoteFile = $resolvedChangelog
}

& $uploadScript @uploadParams

if ($LASTEXITCODE -ne 0) {
    throw "steam-upload.ps1 failed with exit code $LASTEXITCODE"
}

Write-Host "[DONE] Workshop publish workflow completed." -ForegroundColor Green
