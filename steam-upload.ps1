param(
    [string]$SteamUser,
    [string]$ChangeNote,
    [string]$ChangeNoteFile,
    [ValidateSet("0", "1", "2")]
    [string]$Visibility = "0",
    [string]$SteamCmdPath,
    [switch]$IncludeSource,
    [switch]$SkipPackaging
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Escape-VdfString {
    param([string]$Text)
    if ($null -eq $Text) { return "" }

    # Workshop VDF is safer with a single-line description.
    $singleLine = ($Text -replace "\r\n", " " -replace "\n", " " -replace "\r", " ").Trim()
    $singleLine = [regex]::Replace($singleLine, "\s+", " ")
    return $singleLine.Replace('\', '\\').Replace('"', '\"')
}

function Escape-VdfDescription {
    param([string]$Text)
    if ($null -eq $Text) { return "" }

    # VDF multi-line strings do not support escaped quotes — remove double quotes entirely.
    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n").Trim()
    return $normalized.Replace('"', "'")
}

function Get-ChangeNoteFromFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Change note file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if (-not $raw -or -not $raw.Trim()) {
        throw "Change note file is empty: $Path"
    }

    # For markdown changelogs, use the newest section below the first H2 heading.
    if ([System.IO.Path]::GetExtension($Path).ToLowerInvariant() -eq ".md") {
        $lines = $raw -split "`r?`n"
        $firstHeading = -1
        $nextHeading = $lines.Length

        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match '^##\s+') {
                if ($firstHeading -lt 0) {
                    $firstHeading = $i
                } else {
                    $nextHeading = $i
                    break
                }
            }
        }

        if ($firstHeading -ge 0) {
            $allowedHeadings = @(
                "GAMEPLAY TUNING",
                "AMMO / SCOPE",
                "BETROFFENE EINHEITEN",
                "SCOPE"
            )

            $templateLines = @()
            $currentAllowedHeading = $null

            for ($j = $firstHeading + 1; $j -lt $nextHeading; $j++) {
                $line = $lines[$j].Trim()
                if (-not $line) { continue }

                if ($line -match '^###\s+') {
                    $headingRaw = ($line -replace '^###\s+', '').Trim().ToUpper()
                    if ($headingRaw -in $allowedHeadings) {
                        $currentAllowedHeading = $headingRaw
                        if ($templateLines.Count -gt 0) {
                            $templateLines += ""
                        }
                        $templateLines += "== $headingRaw =="
                    } else {
                        $currentAllowedHeading = $null
                    }
                    continue
                }

                # Keep only compact bullet points under approved template headings.
                if ($currentAllowedHeading -and $line -match '^[-*]\s+') {
                    $templateLines += $line
                }
            }

            if ($templateLines.Count -gt 0) {
                return ($templateLines -join [System.Environment]::NewLine)
            }

            # Fallback for legacy changelog entries that do not yet use the template headings.
            $sectionLines = @()
            for ($j = $firstHeading + 1; $j -lt $nextHeading; $j++) {
                $line = $lines[$j].Trim()
                if (-not $line) { continue }

                if ($line -match '^###\s+') {
                    if ($sectionLines.Count -gt 0) {
                        $sectionLines += ""
                    }
                    $heading = ($line -replace '^###\s+', '').Trim().ToUpper()
                    $sectionLines += "== $heading =="
                    continue
                }

                if ($line -match '^#{1,2}\s+') { continue }
                if ($line -match '^[-*]\s+') {
                    $sectionLines += $line
                }
            }

            if ($sectionLines.Count -gt 0) {
                return ($sectionLines -join [System.Environment]::NewLine)
            }
        }
    }

    return ([regex]::Replace($raw, '\s+', ' ')).Trim()
}

function Resolve-SteamCmdPath {
    param([string]$PathFromParam)

    if ($PathFromParam) {
        if (Test-Path -LiteralPath $PathFromParam) {
            return (Resolve-Path -LiteralPath $PathFromParam).Path
        }
        throw "SteamCMD path not found: $PathFromParam"
    }

    $candidates = @(
        "$env:ProgramFiles(x86)\Steam\steamcmd.exe",
        "$env:ProgramFiles(x86)\SteamCMD\steamcmd.exe",
        "$env:ProgramFiles\SteamCMD\steamcmd.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    throw "SteamCMD not found. Install SteamCMD and pass -SteamCmdPath explicitly."
}

function Copy-ModPayload {
    param(
        [string]$Root,
        [string]$Target,
        [bool]$IncludeSrc
    )

    if (Test-Path -LiteralPath $Target) {
        Remove-Item -LiteralPath $Target -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Target | Out-Null

    $items = @(
        "Manifest.json",
        "Preview.jpg",
        "Bundles",
        "Data Sheets"
    )

    if ($IncludeSrc) {
        $items += "Source"
    }

    foreach ($item in $items) {
        $src = Join-Path $Root $item
        if (-not (Test-Path -LiteralPath $src)) {
            continue
        }
        $dst = Join-Path $Target $item
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    }
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $repoRoot "Manifest.json"
$descriptionPath = Join-Path $repoRoot "STEAM_DESCRIPTION.txt"
$tempRoot = Join-Path $repoRoot ".steam-upload"
$contentPath = Join-Path $tempRoot "content"
$vdfPath = Join-Path $tempRoot "item.vdf"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Manifest.json not found at $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

if (-not $manifest.steamFileId -or [string]$manifest.steamFileId -eq "0") {
    throw "Manifest steamFileId is missing or 0. Set the existing Workshop ID before uploading."
}

if (-not $manifest.name) {
    throw "Manifest name is empty."
}

$descriptionRaw = $null
if (Test-Path -LiteralPath $descriptionPath) {
    $descriptionRaw = Get-Content -LiteralPath $descriptionPath -Raw
    Write-Info "Using description from STEAM_DESCRIPTION.txt"
} else {
    $descriptionRaw = [string]$manifest.description
    Write-Info "Using description from Manifest.json"
}

if (-not $descriptionRaw -or -not $descriptionRaw.Trim()) {
    throw "Description is empty in both STEAM_DESCRIPTION.txt and Manifest.json"
}

$steamCmd = Resolve-SteamCmdPath -PathFromParam $SteamCmdPath
Write-Info "SteamCMD: $steamCmd"

if (-not $SkipPackaging) {
    Write-Info "Preparing workshop content package"
    Copy-ModPayload -Root $repoRoot -Target $contentPath -IncludeSrc:$IncludeSource
    Write-Ok "Content prepared at $contentPath"
} elseif (-not (Test-Path -LiteralPath $contentPath)) {
    throw "-SkipPackaging was used but content folder does not exist: $contentPath"
}

if (-not $SteamUser) {
    $SteamUser = Read-Host "Steam username"
}

if (-not $SteamUser) {
    throw "Steam username is required"
}

if (-not (Test-Path -LiteralPath $tempRoot)) {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
}

$appid = "494840" # UBOAT
$title = Escape-VdfString -Text ([string]$manifest.name)
$description = Escape-VdfDescription -Text $descriptionRaw

$changeRaw = $ChangeNote
if (-not $changeRaw -and -not $ChangeNoteFile) {
    $defaultChangeNoteFile = Join-Path $repoRoot "CHANGELOG.md"
    if (Test-Path -LiteralPath $defaultChangeNoteFile) {
        $ChangeNoteFile = $defaultChangeNoteFile
    }
}
if (-not $changeRaw -and $ChangeNoteFile) {
    $changeRaw = Get-ChangeNoteFromFile -Path $ChangeNoteFile
    Write-Info "Using change note from $ChangeNoteFile"
}
if (-not $changeRaw) {
    $changeRaw = "Version $($manifest.version) update"
    Write-Info "Using fallback version-based change note"
}
# Steam workshop changenote supports multi-line strings in VDF format.
# Use Escape-VdfDescription to preserve newlines and proper formatting.
$change = Escape-VdfDescription -Text $changeRaw
$contentEscaped = (Resolve-Path -LiteralPath $contentPath).Path.Replace('\\', '\\\\')
$previewCandidate = Join-Path $repoRoot "Preview.jpg"
$previewEscaped = ""
if (Test-Path -LiteralPath $previewCandidate) {
    $previewEscaped = (Resolve-Path -LiteralPath $previewCandidate).Path.Replace('\\', '\\\\')
}

$vdf = @"
"workshopitem"
{
    "appid"            "$appid"
    "publishedfileid"  "$($manifest.steamFileId)"
    "contentfolder"    "$contentEscaped"
    "previewfile"      "$previewEscaped"
    "visibility"       "$Visibility"
    "title"            "$title"
    "description"      "$description"
    "changenote"       "$change"
}
"@

Set-Content -LiteralPath $vdfPath -Value $vdf -Encoding UTF8
Write-Ok "VDF generated: $vdfPath"

Write-Info "Starting Steam upload. SteamCMD may ask for password/Steam Guard code in terminal."
$uploadOutput = & $steamCmd +login $SteamUser +workshop_build_item "$vdfPath" +quit 2>&1
$uploadOutput | ForEach-Object { Write-Host $_ }

if ($LASTEXITCODE -ne 0) {
    throw "SteamCMD failed with exit code $LASTEXITCODE"
}

Write-Ok "Workshop upload completed."
Write-Host "Workshop URL: https://steamcommunity.com/sharedfiles/filedetails/?id=$($manifest.steamFileId)" -ForegroundColor Yellow
