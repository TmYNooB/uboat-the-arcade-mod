param(
    [string]$SavePath,
    [string]$OutputPath = "Source\latest-manual-savegame-decoded.json",
    [string]$GameInstallPath = "D:\Steam\steamapps\common\UBOAT"
)

$ErrorActionPreference = 'Stop'

$monoExe = Join-Path $GameInstallPath 'UBOAT_Data\MonoBleedingEdge\bin\mono.exe'
$monoMcsExe = Join-Path $GameInstallPath 'UBOAT_Data\MonoBleedingEdge\lib\mono\4.5\mcs.exe'
$toolCs = Join-Path $PSScriptRoot 'SaveDecodeTool.cs'
$toolExe = Join-Path $PSScriptRoot 'SaveDecodeTool.exe'

if (-not (Test-Path $monoExe)) {
    throw "mono.exe not found: $monoExe"
}
if (-not (Test-Path $monoMcsExe)) {
    throw "mcs.exe not found: $monoMcsExe"
}
if (-not (Test-Path $toolCs)) {
    throw "Tool source not found: $toolCs"
}

& $monoExe $monoMcsExe "-out:$toolExe" $toolCs "-r:System.Web.Extensions"
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE"
}

$resolvedOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path (Split-Path -Parent $PSScriptRoot) $OutputPath
}

if (-not $SavePath) {
    $defaultBin = Join-Path $PSScriptRoot 'latest-manual-savegame-gamestate.bin'
    if (Test-Path $defaultBin) {
        $SavePath = $defaultBin
    }
}

if ($SavePath) {
    & $monoExe $toolExe $SavePath $resolvedOutput $GameInstallPath
} else {
    & $monoExe $toolExe "" $resolvedOutput $GameInstallPath
}

if ($LASTEXITCODE -ne 0) {
    throw "Decode tool failed with exit code $LASTEXITCODE"
}

Write-Output "Decoded save JSON: $resolvedOutput"
