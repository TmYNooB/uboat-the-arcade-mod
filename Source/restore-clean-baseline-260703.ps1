#Requires -Module ImportExcel

<#
.SYNOPSIS
Einmalige Wiederherstellung: Ersetzt alle 4 Mod-XLSX durch die verifiziert-saubere
Workshop-Baseline vom 2026-07-03 und appliziert NUR die seither dokumentierten,
verifizierten Arcade-Deltas wieder (v1.7.14/v1.7.15 aus CHANGELOG.md).

.HINTERGRUND
Frühere automatisierte "Recovery"-Versuche (Source/rebuild-mod-xlsx.ps1,
Source/correct-recovery-all-rows.ps1) haben ALLE Vanilla-Zeilen in die Mod kopiert
statt nur die geänderten. Das widerspricht der Kern-Konvention dieses Repos
(siehe .github/copilot-instructions.md: "Die Mod muss NICHT alle Original-Einträge
enthalten — nur die geänderten Zeilen") und hat die Equipment-Sheet von 165 auf
414-416 Zeilen aufgebläht, dabei teils Werte mit geratenen/falschen Parametern
überschrieben (z.B. Gyrocompass NavigationImprovement).

Dieses Script:
1. Liest die AKTUELL auf der Platte liegenden, live-verifizierten Deltas
   (16 neue Munitions-Zeilen + 4 in-place Refinements in Entities.xlsx/Equipment,
   1 Wert in General.xlsx/Settings) BEVOR irgendetwas überschrieben wird.
2. Kopiert die 4 XLSX aus der verifizierten 260703-Baseline in die Mod.
3. Appliziert die eingelesenen Deltas exakt wieder (keine geratenen Werte,
   1:1 aus der Live-Datei übernommen und mit CHANGELOG.md gegengeprüft).

Ergebnis: Entities.xlsx/Equipment = 165 (Baseline) + 16 (neue Munition) = 181 Zeilen,
identisch zum verifizierten Vorzustand, aber mit garantiert sauberer Herkunft.

.WICHTIG
NICHT erneut "alle Vanilla-Zeilen kopieren" - dieses Muster hat die Mod bereits
zweimal zerstört. Neue Änderungen IMMER als gezielte Zeilen-Updates (wie hier)
umsetzen, nie als Full-Copy-Rebuild.
#>

$ErrorActionPreference = "Stop"

$modRoot      = "c:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod\Data Sheets"
$baselineRoot = "C:\Users\User\Downloads\arcademod 260703\Data Sheets"

Write-Host "=== SCHRITT 1: Live-Deltas aus aktueller Mod-Datei einlesen (vor Überschreiben) ===" -ForegroundColor Cyan

$curEq   = @(Import-Excel "$modRoot\Entities.xlsx" -WorksheetName "Equipment" -NoHeader)
$baseEq  = @(Import-Excel "$baselineRoot\Entities.xlsx" -WorksheetName "Equipment" -NoHeader)
$baseIds = @($baseEq | ForEach-Object { [string]$_.P1 })

# Zeilen, die NUR aktuell existieren (v1.7.14/v1.7.15 Munitions-Additions)
$newRows = @($curEq | Where-Object { [string]$_.P1 -ne "" -and [string]$_.P1 -notin $baseIds })

# Zeilen, die in Baseline existieren, aber aktuell verfeinerte Werte haben
$refinedIds = @(
    "Ammo Small Calibre HE - 20 mm",
    "Ammo Small Calibre AP - 20 mm",
    "37 mm SK C30",
    "37 mm SK C30 Forward"
)
$refinedRows = @($curEq | Where-Object { [string]$_.P1 -in $refinedIds })

Write-Host "  Neue Zeilen erfasst: $($newRows.Count)"
$newRows | ForEach-Object { Write-Host "    + $([string]$_.P1)" }
Write-Host "  Verfeinerte Zeilen erfasst: $($refinedRows.Count)"
$refinedRows | ForEach-Object { Write-Host "    ~ $([string]$_.P1)" }

if ($newRows.Count -ne 16) { throw "Erwartet 16 neue Zeilen, gefunden: $($newRows.Count). Abbruch zur Sicherheit." }
if ($refinedRows.Count -ne 4) { throw "Erwartet 4 verfeinerte Zeilen, gefunden: $($refinedRows.Count). Abbruch zur Sicherheit." }

Write-Host "`n=== SCHRITT 2: Verifizierte 260703-Baseline in Mod kopieren ===" -ForegroundColor Cyan
foreach ($file in @("CharacterClasses.xlsx", "General.xlsx", "Sandbox.xlsx", "Entities.xlsx")) {
    Copy-Item "$baselineRoot\$file" "$modRoot\$file" -Force
    Write-Host "  Kopiert: $file"
}

Write-Host "`n=== SCHRITT 3: Entities.xlsx/Equipment - Deltas re-applizieren ===" -ForegroundColor Cyan

$pkg = Open-ExcelPackage "$modRoot\Entities.xlsx"
$ws  = $pkg.Workbook.Worksheets["Equipment"]
$maxCol = $ws.Dimension.Columns

function Write-FullRow {
    param($rowNum, $sourceRow)
    for ($c = 1; $c -le $maxCol; $c++) {
        $ws.Cells[$rowNum, $c].Value = $sourceRow.("P$c")
    }
}

# 3a: Verfeinerte Zeilen in-place überschreiben (ID-Match in der frischen Baseline suchen)
for ($r = 1; $r -le $ws.Dimension.Rows; $r++) {
    $id = [string]$ws.Cells[$r, 1].Value
    if ($id -in $refinedIds) {
        $source = $refinedRows | Where-Object { [string]$_.P1 -eq $id }
        Write-FullRow -rowNum $r -sourceRow $source
        Write-Host "  Verfeinert (Zeile $r): $id"
    }
}

# 3b: Neue Zeilen anhängen
$nextRow = $ws.Dimension.Rows
foreach ($row in $newRows) {
    $nextRow++
    Write-FullRow -rowNum $nextRow -sourceRow $row
    Write-Host "  Hinzugefügt (Zeile $nextRow): $([string]$row.P1)"
}

$pkg.Save()
$pkg.Dispose()

Write-Host "`n=== SCHRITT 4: General.xlsx - DamageDifficulty Easy auf 0.03 setzen ===" -ForegroundColor Cyan

$pkgG = Open-ExcelPackage "$modRoot\General.xlsx"
$wsG  = $pkgG.Workbook.Worksheets["Settings"]

$inDamageDifficulty = $false
$fixed = $false
for ($r = 1; $r -le $wsG.Dimension.Rows; $r++) {
    $p1 = [string]$wsG.Cells[$r, 1].Value
    if ($p1 -like "/*") {
        $inDamageDifficulty = ($p1 -eq "/DamageDifficulty")
        continue
    }
    if ($inDamageDifficulty -and $p1 -eq "Multiplier") {
        $wsG.Cells[$r, 2].Value = "0.03"
        Write-Host "  Zeile ${r}: Multiplier (Easy) = 0.03"
        $fixed = $true
        break
    }
}
if (-not $fixed) { throw "DamageDifficulty/Multiplier-Zeile nicht gefunden - Abbruch zur Sicherheit." }

$pkgG.Save()
$pkgG.Dispose()

Write-Host "`n✅ Restore abgeschlossen." -ForegroundColor Green
