param(
    [string]$SavePath,
    [string]$SnapshotDir = "Source/savegame-analysis/current-snapshot"
)

$ErrorActionPreference = 'Stop'

$extractScript = Join-Path $PSScriptRoot 'extract-save-complete.ps1'
$analyzeScript = Join-Path $PSScriptRoot 'analyze-save-rest-strings.ps1'
$phase1Script = Join-Path $PSScriptRoot 'phase1-parse-block3.ps1'
$phase2Script = Join-Path $PSScriptRoot 'phase2-extract-embedded-containers.ps1'
$decodeScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'decode-savegame-offline.ps1'

if ($SavePath) {
    & $extractScript -SavePath $SavePath -OutDir $SnapshotDir
} else {
    & $extractScript -OutDir $SnapshotDir
}

$restPath = Join-Path $SnapshotDir 'block3-rest.bin'
$analysisJson = Join-Path $SnapshotDir 'save-rest-analysis.json'
& $analyzeScript -RestBinPath $restPath -OutputJsonPath $analysisJson

$metaPath = Join-Path $SnapshotDir 'save-container-metadata.json'
$phase1Json = Join-Path $SnapshotDir 'phase1-block3-parse.json'
$phase1Md = Join-Path $SnapshotDir 'phase1-block3-summary.md'
& $phase1Script -RestBinPath $restPath -MetadataPath $metaPath -OutputJsonPath $phase1Json -OutputMarkdownPath $phase1Md

$phase2Json = Join-Path $SnapshotDir 'phase2-embedded-containers.json'
$phase2OutDir = Join-Path $SnapshotDir 'extracted-containers'
& $phase2Script -RestBinPath $restPath -OutputDir $phase2OutDir -ReportJsonPath $phase2Json

$decodeInput = Join-Path $SnapshotDir 'block1-gamestate.bin'
$decodedOut = Join-Path $SnapshotDir 'decoded-block1-summary.json'
& $decodeScript -SavePath $decodeInput -OutputPath $decodedOut

Write-Output "Refresh complete: $SnapshotDir"
