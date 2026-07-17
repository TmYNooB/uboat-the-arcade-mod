$ErrorActionPreference = 'Stop'
Import-Module ImportExcel

$modGeneral = 'c:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod\Data Sheets\General.xlsx'
$origGeneral = 'D:\Steam\steamapps\common\UBOAT\UBOAT_Data\Data Sheets\General.xlsx'
$rollbackJson = 'c:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod\Source\rollback-hull-damage-values-2026-07-17.json'

function ToNum([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) {
        return $null
    }

    $n = 0.0
    $normalized = $s.Trim().Replace(',', '.')
    if ([double]::TryParse($normalized, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$n)) {
        return $n
    }

    return $null
}

$modSet = Import-Excel $modGeneral -WorksheetName 'Settings' -NoHeader
$origSet = Import-Excel $origGeneral -WorksheetName 'Settings' -NoHeader

$modById = @{}
$origById = @{}
foreach ($r in $modSet) {
    $id = [string]$r.P1
    if ($id) { $modById[$id] = $r }
}
foreach ($r in $origSet) {
    $id = [string]$r.P1
    if ($id) { $origById[$id] = $r }
}

# /DamageDifficulty row "Multiplier": P2=Easy, P3=Medium, P4=Hard
$easyMod = ToNum ([string]$modById['Multiplier'].P2)
$easyOrig = ToNum ([string]$origById['Multiplier'].P2)

$absOrig = ToNum ([string]$origById['Hull Damage Absorption'].P2)
$scaleOrig = ToNum ([string]$origById['Hull Damage Scale'].P2)
$scaleNoDcOrig = ToNum ([string]$origById['Hull Damage Scale (Without Damage Control)'].P2)

$absNow = ToNum ([string]$modById['Hull Damage Absorption'].P2)
$scaleNow = ToNum ([string]$modById['Hull Damage Scale'].P2)
$scaleNoDcNow = ToNum ([string]$modById['Hull Damage Scale (Without Damage Control)'].P2)

$rb = Get-Content $rollbackJson -Raw | ConvertFrom-Json
$absRb = ToNum ([string]$rb.valuesBefore.'Hull Damage Absorption')
$scaleRb = ToNum ([string]$rb.valuesBefore.'Hull Damage Scale')
$scaleNoDcRb = ToNum ([string]$rb.valuesBefore.'Hull Damage Scale (Without Damage Control)')

function EffectiveDamage([double]$easy, [double]$scale, [double]$absorption) {
    return $easy * $scale * (1.0 - $absorption)
}

$baseWithDc = EffectiveDamage -easy $easyOrig -scale $scaleOrig -absorption $absOrig
$baseNoDc = EffectiveDamage -easy $easyOrig -scale $scaleNoDcOrig -absorption $absOrig

$nowWithDc = EffectiveDamage -easy $easyMod -scale $scaleNow -absorption $absNow
$nowNoDc = EffectiveDamage -easy $easyMod -scale $scaleNoDcNow -absorption $absNow

$rbWithDc = EffectiveDamage -easy $easyMod -scale $scaleRb -absorption $absRb
$rbNoDc = EffectiveDamage -easy $easyMod -scale $scaleNoDcRb -absorption $absRb

$result = [pscustomobject]@{
    easyMultiplier = [pscustomobject]@{
        mod = $easyMod
        vanilla = $easyOrig
    }
    vanilla = [pscustomobject]@{
        withDamageControl = $baseWithDc
        withoutDamageControl = $baseNoDc
    }
    rollbackBefore = [pscustomobject]@{
        withDamageControl = $rbWithDc
        withoutDamageControl = $rbNoDc
        reductionFactorVsVanilla_withDamageControl = if ($rbWithDc -ne 0) { $baseWithDc / $rbWithDc } else { $null }
        reductionFactorVsVanilla_withoutDamageControl = if ($rbNoDc -ne 0) { $baseNoDc / $rbNoDc } else { $null }
    }
    current = [pscustomobject]@{
        withDamageControl = $nowWithDc
        withoutDamageControl = $nowNoDc
        reductionFactorVsVanilla_withDamageControl = if ($nowWithDc -ne 0) { $baseWithDc / $nowWithDc } else { $null }
        reductionFactorVsVanilla_withoutDamageControl = if ($nowNoDc -ne 0) { $baseNoDc / $nowNoDc } else { $null }
    }
}

$result | ConvertTo-Json -Depth 6
