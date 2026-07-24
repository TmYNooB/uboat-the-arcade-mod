param(
    [string]$RestBinPath = "Source/savegame-analysis/current-snapshot/latest-manual-savegame-rest.bin",
    [string]$OutputJsonPath = "Source/savegame-analysis/current-snapshot/save-rest-analysis.json",
    [int]$MinTokenLength = 4,
    [int]$MaxTokenLength = 180
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $RestBinPath)) {
    throw "Rest bin not found: $RestBinPath"
}

$bytes = [System.IO.File]::ReadAllBytes($RestBinPath)

$encodings = @(
    [System.Text.Encoding]::ASCII,
    [System.Text.Encoding]::UTF8,
    [System.Text.Encoding]::Unicode
)

$tokenSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)

foreach ($enc in $encodings) {
    $text = $enc.GetString($bytes)
    $matches = [regex]::Matches($text, "[ -~]{$MinTokenLength,$MaxTokenLength}")
    foreach ($m in $matches) {
        $token = $m.Value.Trim()
        if ($token.Length -ge $MinTokenLength -and $token.Length -le $MaxTokenLength) {
            [void]$tokenSet.Add($token)
        }
    }
}

$tokens = @($tokenSet)

$groups = [ordered]@{
    sandbox = @('Sandbox', 'sandbox', 'Campaign', 'Settings', 'Difficulty', 'Reputation', 'Travel', 'Bleeding', 'Incubation')
    tasks = @('Task', 'task', 'Assignment', 'Mission', 'Produce', 'Research', 'Build', 'Duration', 'Academy')
    entities = @('Entities/', 'Type ', 'Equipment', 'Slots', 'Units', 'Fuel', 'Torpedo', 'Compressor')
    system = @('stringPool', 'sceneObjects', 'scriptableObjects', 'playerShip', 'SaveData')
    audio_ui = @('VoiceVolume', 'MusicVolume', 'InterfaceVolume', 'FullscreenUI', 'FadeOut')
}

$hitsByGroup = [ordered]@{}
foreach ($groupName in $groups.Keys) {
    $needles = $groups[$groupName]
    $hits = $tokens | Where-Object {
        $t = $_
        foreach ($n in $needles) {
            if ($t -like "*$n*") { return $true }
        }
        return $false
    } | Sort-Object -Unique

    $hitsByGroup[$groupName] = [pscustomobject]@{
        count = $hits.Count
        sample = @($hits | Select-Object -First 120)
    }
}

# High-value sandbox-related markers to prove save-bound state.
$focusPatterns = @(
    'SailorsOnBoardLimit',
    'OfficersOnBoardLimit',
    'SurvivorsOnBoardLimit',
    'VacationPriceModifier',
    'DamageReduction',
    'AssignmentName',
    'RegionName',
    'Missions/',
    'Sandbox',
    'Settings',
    'Reputation'
)

$focusHits = foreach ($p in $focusPatterns) {
    $match = $tokens | Where-Object { $_ -like "*$p*" } | Sort-Object -Unique
    [pscustomobject]@{
        pattern = $p
        count = $match.Count
        sample = @($match | Select-Object -First 40)
    }
}

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('s')
    restBinPath = (Resolve-Path $RestBinPath).Path
    restBinBytes = $bytes.Length
    totalUniqueTokens = $tokens.Count
    groups = $hitsByGroup
    focusHits = $focusHits
}

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputJsonPath -Encoding UTF8
Write-Output "Wrote analysis: $OutputJsonPath"
