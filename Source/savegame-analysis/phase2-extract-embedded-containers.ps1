param(
    [string]$RestBinPath = "Source/savegame-analysis/current-snapshot/block3-rest.bin",
    [string]$OutputDir = "Source/savegame-analysis/current-snapshot/extracted-containers",
    [string]$ReportJsonPath = "Source/savegame-analysis/current-snapshot/phase2-embedded-containers.json",
    [int]$MaxZlibCandidates = 600,
    [int]$MaxInflateBytes = 83886080
)

$ErrorActionPreference = 'Stop'

function Find-SignatureOffsets {
    param(
        [byte[]]$Data,
        [byte[]]$Sig
    )

    $hits = New-Object System.Collections.Generic.List[int]
    if ($Data.Length -lt $Sig.Length) {
        return @($hits)
    }

    for ($i = 0; $i -le $Data.Length - $Sig.Length; $i++) {
        $ok = $true
        for ($j = 0; $j -lt $Sig.Length; $j++) {
            if ($Data[$i + $j] -ne $Sig[$j]) {
                $ok = $false
                break
            }
        }
        if ($ok) {
            $hits.Add($i)
        }
    }

    return @($hits)
}

function Index-OfSignature {
    param(
        [byte[]]$Data,
        [byte[]]$Sig,
        [int]$StartAt = 0
    )

    if ($Data.Length -lt $Sig.Length) {
        return -1
    }

    $start = [Math]::Max(0, $StartAt)
    for ($i = $start; $i -le $Data.Length - $Sig.Length; $i++) {
        $ok = $true
        for ($j = 0; $j -lt $Sig.Length; $j++) {
            if ($Data[$i + $j] -ne $Sig[$j]) {
                $ok = $false
                break
            }
        }
        if ($ok) {
            return $i
        }
    }

    return -1
}

function Get-UInt16Le {
    param(
        [byte[]]$Data,
        [int]$Offset
    )

    if ($Offset -lt 0 -or $Offset + 1 -ge $Data.Length) {
        return $null
    }
    return [int]([BitConverter]::ToUInt16($Data, $Offset))
}

if (-not (Test-Path $RestBinPath)) {
    throw "Rest bin not found: $RestBinPath"
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$bytes = [System.IO.File]::ReadAllBytes($RestBinPath)

$sigPk0304 = [byte[]](0x50, 0x4B, 0x03, 0x04)
$sigPk0102 = [byte[]](0x50, 0x4B, 0x01, 0x02)
$sigPk0506 = [byte[]](0x50, 0x4B, 0x05, 0x06)
$sigOle = [byte[]](0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1)

$pk0304 = Find-SignatureOffsets -Data $bytes -Sig $sigPk0304
$pk0102 = Find-SignatureOffsets -Data $bytes -Sig $sigPk0102
$pk0506 = Find-SignatureOffsets -Data $bytes -Sig $sigPk0506
$ole = Find-SignatureOffsets -Data $bytes -Sig $sigOle

$extracted = New-Object System.Collections.Generic.List[object]

# Attempt raw ZIP carving based on local-header -> EOCD.
$zipIdx = 0
foreach ($start in $pk0304 | Sort-Object) {
    $eocd = $pk0506 | Where-Object { $_ -ge $start } | Select-Object -First 1
    if ($null -eq $eocd) {
        continue
    }

    $commentLen = Get-UInt16Le -Data $bytes -Offset ($eocd + 20)
    if ($null -eq $commentLen) {
        continue
    }

    $zipEnd = [int]($eocd + 22 + $commentLen)
    if ($zipEnd -le $start -or $zipEnd -gt $bytes.Length) {
        continue
    }

    $zipBytes = $bytes[$start..($zipEnd - 1)]
    $ascii = [System.Text.Encoding]::ASCII.GetString($zipBytes)
    $looksLikeXlsx = ($ascii -match '\[Content_Types\]\.xml' -and $ascii -match 'xl/')

    $ext = if ($looksLikeXlsx) { 'xlsx' } else { 'zip' }
    $name = ('embedded-raw-{0:d3}.{1}' -f $zipIdx, $ext)
    $outPath = Join-Path $OutputDir $name
    [System.IO.File]::WriteAllBytes($outPath, $zipBytes)

    $extracted.Add([pscustomobject]@{
        source = 'raw-zip-carve'
        file = $outPath
        startOffset = $start
        endOffsetExclusive = $zipEnd
        bytes = $zipBytes.Length
        looksLikeXlsx = $looksLikeXlsx
    })

    $zipIdx++
}

# Probe potential nested zlib streams and inspect decompressed buffers for OOXML/OLE signatures.
$candidates = New-Object System.Collections.Generic.List[int]
for ($i = 0; $i -le $bytes.Length - 2; $i++) {
    if ($bytes[$i] -eq 0x78) {
        $b2 = $bytes[$i + 1]
        if ($b2 -eq 0x01 -or $b2 -eq 0x5E -or $b2 -eq 0x9C -or $b2 -eq 0xDA) {
            $candidates.Add($i)
        }
    }
}

$candidateOffsets = @($candidates)
if ($candidateOffsets.Count -gt $MaxZlibCandidates -and $MaxZlibCandidates -gt 0) {
    $picked = New-Object System.Collections.Generic.List[int]
    for ($k = 0; $k -lt $MaxZlibCandidates; $k++) {
        $idx = [int][Math]::Floor(($k * ($candidateOffsets.Count - 1.0)) / [Math]::Max(1.0, ($MaxZlibCandidates - 1.0)))
        $picked.Add($candidateOffsets[$idx])
    }
    $candidateOffsets = @($picked | Select-Object -Unique)
}

$zlibAvailable = $null -ne [type]::GetType('System.IO.Compression.ZLibStream, System.IO.Compression', $false)
$zlibTried = 0
$zlibInflated = 0
$zlibHits = 0

if ($zlibAvailable) {
    $zIdx = 0
    foreach ($off in $candidateOffsets) {
        $zlibTried++
        try {
            $msIn = [System.IO.MemoryStream]::new($bytes, [int]$off, [int]($bytes.Length - $off), $false)
            try {
                $zs = [System.IO.Compression.ZLibStream]::new($msIn, [System.IO.Compression.CompressionMode]::Decompress, $false)
                try {
                    $msOut = [System.IO.MemoryStream]::new()
                    try {
                        $buf = New-Object byte[] 8192
                        $total = 0
                        while ($true) {
                            $read = $zs.Read($buf, 0, $buf.Length)
                            if ($read -le 0) {
                                break
                            }
                            $msOut.Write($buf, 0, $read)
                            $total += $read
                            if ($total -ge $MaxInflateBytes) {
                                break
                            }
                        }

                        if ($total -gt 128) {
                            $zlibInflated++
                            $outBytes = $msOut.ToArray()
                            $pkPos = Index-OfSignature -Data $outBytes -Sig $sigPk0304
                            $olePos = Index-OfSignature -Data $outBytes -Sig $sigOle
                            $ascii = [System.Text.Encoding]::ASCII.GetString($outBytes)
                            $ooxmlMarkers = 0
                            if ($ascii -match '\[Content_Types\]\.xml') { $ooxmlMarkers++ }
                            if ($ascii -match 'xl/') { $ooxmlMarkers++ }
                            if ($ascii -match 'workbook\.xml') { $ooxmlMarkers++ }

                            if ($pkPos -ge 0 -or $olePos -ge 0 -or $ooxmlMarkers -gt 0) {
                                $zlibHits++
                                $looksLikeXlsx = ($pkPos -eq 0 -and $ooxmlMarkers -ge 2)
                                $ext = if ($looksLikeXlsx) { 'xlsx' } elseif ($pkPos -eq 0) { 'zip' } elseif ($olePos -eq 0) { 'xls' } else { 'bin' }
                                $name = ('embedded-zlib-{0:d3}-off{1}.{2}' -f $zIdx, $off, $ext)
                                $outPath = Join-Path $OutputDir $name
                                [System.IO.File]::WriteAllBytes($outPath, $outBytes)

                                $extracted.Add([pscustomobject]@{
                                    source = 'zlib-probe'
                                    file = $outPath
                                    startOffset = $off
                                    endOffsetExclusive = $null
                                    bytes = $outBytes.Length
                                    looksLikeXlsx = $looksLikeXlsx
                                    pkOffsetInInflated = $pkPos
                                    oleOffsetInInflated = $olePos
                                    ooxmlMarkerCount = $ooxmlMarkers
                                })
                            }
                        }
                    }
                    finally {
                        $msOut.Dispose()
                    }
                }
                finally {
                    $zs.Dispose()
                }
            }
            finally {
                $msIn.Dispose()
            }
        }
        catch {
            # Not a valid zlib stream at this offset, ignore.
        }
        $zIdx++
    }
}

$report = @{
    generatedAt = (Get-Date).ToString('s')
    restBinPath = (Resolve-Path $RestBinPath).Path
    restBinBytes = [int]$bytes.Length
    rawSignatureCounts = @{
        pk0304 = [int]$pk0304.Count
        pk0102 = [int]$pk0102.Count
        pk0506 = [int]$pk0506.Count
        ole = [int]$ole.Count
    }
    zlibProbe = @{
        available = [bool]$zlibAvailable
        totalCandidatesFound = [int]$candidates.Count
        candidatesTried = [int]$zlibTried
        inflatedBuffers = [int]$zlibInflated
        hits = [int]$zlibHits
        maxCandidates = [int]$MaxZlibCandidates
        maxInflateBytes = [int]$MaxInflateBytes
    }
    extractedCount = [int]$extracted.Count
    extracted = @($extracted.ToArray())
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ReportJsonPath -Encoding UTF8

Write-Output "Wrote phase2 report: $ReportJsonPath"
Write-Output ("Extracted containers: {0}" -f $extracted.Count)
