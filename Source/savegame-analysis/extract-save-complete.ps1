param(
    [string]$SavePath,
    [string]$OutDir = "Source/savegame-analysis/current-snapshot"
)

$ErrorActionPreference = 'Stop'

function Get-LatestManualSavePath {
    $saveDir = Join-Path $env:USERPROFILE 'AppData\\LocalLow\\Deep Water Studio\\UBOAT\\Saves'
    $manual = Get-ChildItem -Path $saveDir -File -Filter *.save |
        Where-Object { $_.Name -notmatch '^Autosave_' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $manual) {
        throw "No manual save found in: $saveDir"
    }

    return $manual.FullName
}

if (-not $SavePath) {
    $SavePath = Get-LatestManualSavePath
}

if (-not (Test-Path $SavePath)) {
    throw "Save not found: $SavePath"
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$saveInfo = Get-Item $SavePath
$saveCopy = Join-Path $OutDir $saveInfo.Name
Copy-Item $SavePath $saveCopy -Force

$fs = [System.IO.File]::Open($SavePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
try {
    $deflate = New-Object System.IO.Compression.DeflateStream($fs, [System.IO.Compression.CompressionMode]::Decompress)
    try {
        $reader = New-Object System.IO.BinaryReader($deflate)
        try {
            $block1Len = $reader.ReadInt32()
            $block1 = $reader.ReadBytes($block1Len)

            $block2Len = $reader.ReadInt32()
            $block2 = $reader.ReadBytes($block2Len)

            $restStream = New-Object System.IO.MemoryStream
            $buf = New-Object byte[] 1048576
            while (($n = $deflate.Read($buf, 0, $buf.Length)) -gt 0) {
                $restStream.Write($buf, 0, $n)
            }
            $rest = $restStream.ToArray()
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $deflate.Dispose()
    }
}
finally {
    $fs.Dispose()
}

$block1Path = Join-Path $OutDir 'block1-gamestate.bin'
$block2Path = Join-Path $OutDir 'block2-screenshot.jpg'
$restPath = Join-Path $OutDir 'block3-rest.bin'

[System.IO.File]::WriteAllBytes($block1Path, $block1)
[System.IO.File]::WriteAllBytes($block2Path, $block2)
[System.IO.File]::WriteAllBytes($restPath, $rest)

# Locate repeated serialized record headers in block 3.
$sig = [byte[]](0xFE, 0xFF, 0xFF, 0xFF)
$headerOffsets = New-Object System.Collections.Generic.List[int]
for ($i = 0; $i -le $rest.Length - 4; $i++) {
    if ($rest[$i] -eq $sig[0] -and $rest[$i + 1] -eq $sig[1] -and $rest[$i + 2] -eq $sig[2] -and $rest[$i + 3] -eq $sig[3]) {
        $headerOffsets.Add($i)
    }
}

$meta = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    sourceSavePath = $saveInfo.FullName
    sourceSaveSizeBytes = $saveInfo.Length
    block1GameStateBytes = $block1Len
    block2ScreenshotBytes = $block2Len
    block3RestBytes = $rest.Length
    block2LooksLikeJpeg = ($block2.Length -ge 3 -and $block2[0] -eq 0xFF -and $block2[1] -eq 0xD8 -and $block2[2] -eq 0xFF)
    block3HeaderSignature = 'FE FF FF FF'
    block3HeaderOffsets = @($headerOffsets)
}

$metaPath = Join-Path $OutDir 'save-container-metadata.json'
$meta | ConvertTo-Json -Depth 6 | Set-Content -Path $metaPath -Encoding UTF8

Write-Output "Wrote: $block1Path"
Write-Output "Wrote: $block2Path"
Write-Output "Wrote: $restPath"
Write-Output "Wrote: $metaPath"
