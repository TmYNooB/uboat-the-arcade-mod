param(
    [string]$RestBinPath = "Source/savegame-analysis/current-snapshot/block3-rest.bin",
    [string]$MetadataPath = "Source/savegame-analysis/current-snapshot/save-container-metadata.json",
    [string]$OutputJsonPath = "Source/savegame-analysis/current-snapshot/phase1-block3-parse.json",
    [string]$OutputMarkdownPath = "Source/savegame-analysis/current-snapshot/phase1-block3-summary.md"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $RestBinPath)) {
    throw "Rest bin not found: $RestBinPath"
}

$bytes = [System.IO.File]::ReadAllBytes($RestBinPath)

# Use metadata offsets if available; otherwise rescan locally.
$offsets = @()
if (Test-Path $MetadataPath) {
    try {
        $meta = Get-Content $MetadataPath -Raw | ConvertFrom-Json
        $offsets = @($meta.block3HeaderOffsets)
    }
    catch {
        $offsets = @()
    }
}

if (-not $offsets -or $offsets.Count -eq 0) {
    $sig = [byte[]](0xFE, 0xFF, 0xFF, 0xFF)
    $found = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -le $bytes.Length - 4; $i++) {
        if ($bytes[$i] -eq $sig[0] -and $bytes[$i + 1] -eq $sig[1] -and $bytes[$i + 2] -eq $sig[2] -and $bytes[$i + 3] -eq $sig[3]) {
            $found.Add($i)
        }
    }
    $offsets = @($found)
}

$offsets = @($offsets | ForEach-Object { [int]$_ } | Sort-Object)

function Get-PrintableTokenSet {
    param([byte[]]$Data, [int]$MinLen = 4, [int]$MaxLen = 220)

    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $encodings = @(
        [System.Text.Encoding]::ASCII,
        [System.Text.Encoding]::UTF8,
        [System.Text.Encoding]::Unicode
    )

    foreach ($enc in $encodings) {
        $text = $enc.GetString($Data)
        foreach ($m in [regex]::Matches($text, "[ -~]{$MinLen,$MaxLen}")) {
            $v = $m.Value.Trim()
            if ($v.Length -ge $MinLen -and $v.Length -le $MaxLen) {
                [void]$set.Add($v)
            }
        }
    }

    return @($set)
}

$segments = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $offsets.Count; $i++) {
    $start = $offsets[$i]
    $end = if ($i -lt $offsets.Count - 1) { $offsets[$i + 1] } else { $bytes.Length }
    $len = $end - $start

    $typeName = $null
    $typeParseError = $null

    try {
        $bodyOffset = [int]($start + 4)
        $bodyLength = [int]([Math]::Max(0, $len - 4))
        if ($bodyLength -gt 0) {
            $ms = [System.IO.MemoryStream]::new($bytes, $bodyOffset, $bodyLength, $false)
            try {
                $br = [System.IO.BinaryReader]::new($ms, [System.Text.Encoding]::UTF8, $false)
                try {
                    $typeName = $br.ReadString()
                }
                finally {
                    $br.Dispose()
                }
            }
            finally {
                $ms.Dispose()
            }
        }
    }
    catch {
        $typeParseError = $_.Exception.Message
    }

    $prefixStart = [Math]::Max(0, $start - 24)
    $prefixLen = [Math]::Min(24, $start - $prefixStart)
    $prefix = if ($prefixLen -gt 0) { $bytes[$prefixStart..($start - 1)] } else { @() }
    $prefixText = if ($prefix.Length -gt 0) {
        -join ($prefix | ForEach-Object { if ($_ -ge 32 -and $_ -le 126) { [char]$_ } else { '.' } })
    } else {
        ''
    }

    $segments.Add([pscustomobject]@{
        index = $i
        startOffset = $start
        endOffsetExclusive = $end
        lengthBytes = $len
        parsedTypeName = $typeName
        typeParseError = $typeParseError
        prefixAscii = $prefixText
    })
}

$saveDataSegment = $segments | Where-Object { $_.parsedTypeName -like '*UBOAT.Game.Serialization.SaveData*' } | Select-Object -First 1
if (-not $saveDataSegment) {
    $saveDataSegment = $segments | Select-Object -First 1
}

$segBytes = $bytes[$saveDataSegment.startOffset..($saveDataSegment.endOffsetExclusive - 1)]
$tokens = Get-PrintableTokenSet -Data $segBytes

$topLevelCandidates = @(
    'sceneObjects',
    'scriptableObjects',
    'sandbox',
    'playerShip',
    'sceneOrigin',
    'stringPool',
    'storedStrings',
    'stringPairToIdDictionary',
    'stringToIdDictionary'
)

$topLevelPresence = foreach ($k in $topLevelCandidates) {
    $hits = @($tokens | Where-Object { $_ -eq $k -or $_ -like "*$k*" })
    [pscustomobject]@{
        key = $k
        present = ($hits.Count -gt 0)
        count = $hits.Count
        sample = @($hits | Select-Object -First 6)
    }
}

$sandboxClasses = @($tokens | Where-Object { $_ -match 'UBOAT\.Game\.Sandbox\.[A-Za-z0-9_\+\.]+' } | Sort-Object -Unique)
$taskMarkers = @($tokens | Where-Object {
    $_ -like '*Task*' -or $_ -like '*Mission*' -or $_ -like '*Assignment*' -or $_ -like '*Research*' -or $_ -like '*Build *'
} | Sort-Object -Unique)
$settingsMarkers = @($tokens | Where-Object {
    $_ -like '*Settings*' -or $_ -like '*Difficulty*' -or $_ -like '*DamageReduction*' -or $_ -like '*VacationPriceModifier*' -or $_ -like '*OnBoardLimit*'
} | Sort-Object -Unique)

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    restBinPath = (Resolve-Path $RestBinPath).Path
    restBinBytes = $bytes.Length
    segmentCount = $segments.Count
    segments = $segments
    selectedSaveDataSegment = [pscustomobject]@{
        index = $saveDataSegment.index
        startOffset = $saveDataSegment.startOffset
        endOffsetExclusive = $saveDataSegment.endOffsetExclusive
        lengthBytes = $saveDataSegment.lengthBytes
        parsedTypeName = $saveDataSegment.parsedTypeName
    }
    saveDataTokenCount = $tokens.Count
    topLevelPresence = $topLevelPresence
    sandboxClassCount = $sandboxClasses.Count
    sandboxClassSample = @($sandboxClasses | Select-Object -First 120)
    taskMarkerCount = $taskMarkers.Count
    taskMarkerSample = @($taskMarkers | Select-Object -First 180)
    settingsMarkerCount = $settingsMarkers.Count
    settingsMarkerSample = @($settingsMarkers | Select-Object -First 180)
}

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputJsonPath -Encoding UTF8

$md = @()
$md += '# Phase 1 - Block3 Parse Summary'
$md += ''
$md += "- Generated: $($result.generatedAt)"
$md += "- Rest bytes: $($result.restBinBytes)"
$md += "- Segment count (FE FF FF FF headers): $($result.segmentCount)"
$md += "- Selected SaveData segment: index=$($result.selectedSaveDataSegment.index), offset=$($result.selectedSaveDataSegment.startOffset), len=$($result.selectedSaveDataSegment.lengthBytes)"
$md += "- Parsed type: $($result.selectedSaveDataSegment.parsedTypeName)"
$md += "- Token count in selected segment: $($result.saveDataTokenCount)"
$md += "- Sandbox class markers: $($result.sandboxClassCount)"
$md += "- Task markers: $($result.taskMarkerCount)"
$md += "- Settings markers: $($result.settingsMarkerCount)"
$md += ''
$md += '## Top-level presence'
foreach ($row in $result.topLevelPresence) {
    $md += "- $($row.key): present=$($row.present), count=$($row.count)"
}
$md += ''
$md += '## Sandbox class sample'
foreach ($x in ($result.sandboxClassSample | Select-Object -First 40)) {
    $md += "- $x"
}
$md += ''
$md += '## Task marker sample'
foreach ($x in ($result.taskMarkerSample | Select-Object -First 40)) {
    $md += "- $x"
}
$md += ''
$md += '## Settings marker sample'
foreach ($x in ($result.settingsMarkerSample | Select-Object -First 40)) {
    $md += "- $x"
}

$md -join "`r`n" | Set-Content -Path $OutputMarkdownPath -Encoding UTF8

Write-Output "Wrote phase1 JSON: $OutputJsonPath"
Write-Output "Wrote phase1 summary: $OutputMarkdownPath"
