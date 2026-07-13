<# 
.SYNOPSIS
    Sichere Cleanup-Routine für UBOAT Arcade Mod Caches
    
.DESCRIPTION
    Löscht nur die Caches und Temp-Dateien der Arcade Mod, ohne andere Mods/DLCs zu beeinträchtigen.
    - Temp & Cache Verzeichnisse werden komplett gelöscht (safe)
    - NUR Arcade Mod .dat Dateien werden aus Data Sheets gelöscht
    - Spielstände (Saves), andere Mods, und Konfiguration bleiben unberührt
    
.NOTES
    Autor: UBOAT Arcade Mod Development
    Datum: 2026-07-03
    
.EXAMPLE
    .\cleanup-mod-cache.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$uboatPath = "$env:USERPROFILE\AppData\LocalLow\Deep Water Studio\UBOAT"

Write-Host "UBOAT Arcade Mod - Sichere Cache Cleanup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Temp Verzeichnis löschen (safe - nur temporäre Dateien)
Write-Host "[1/4] Lösche /Temp Verzeichnis..." -ForegroundColor Yellow
$tempPath = "$uboatPath\Temp"
if (Test-Path -LiteralPath $tempPath) {
    Remove-Item -LiteralPath $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "      ✓ /Temp gelöscht" -ForegroundColor Green
} else {
    Write-Host "      ℹ /Temp nicht vorhanden" -ForegroundColor Gray
}

# 2. Cache Verzeichnis löschen (safe - wird vom Spiel regeneriert)
Write-Host "[2/4] Lösche /Cache Verzeichnis..." -ForegroundColor Yellow
$cachePath = "$uboatPath\Cache"
if (Test-Path -LiteralPath $cachePath) {
    Remove-Item -LiteralPath $cachePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "      ✓ /Cache gelöscht" -ForegroundColor Green
} else {
    Write-Host "      ℹ /Cache nicht vorhanden" -ForegroundColor Gray
}

# 3. SELEKTIV nur Arcade Mod .dat Dateien löschen
Write-Host "[3/4] Lösche Arcade Mod .dat Dateien..." -ForegroundColor Yellow
$datSheetPath = "$uboatPath\Data Sheets"
$arcadeDatFiles = @(
    "UBoat the Arcade Mod - CharacterClasses.dat",
    "UBoat the Arcade Mod - Entities.dat",
    "UBoat the Arcade Mod - General.dat",
    "UBoat the Arcade Mod - Sandbox.dat"
)

$deletedCount = 0
foreach ($file in $arcadeDatFiles) {
    $filePath = "$datSheetPath\$file"
    if (Test-Path -LiteralPath $filePath) {
        Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue
        Write-Host "      ✓ $file gelöscht" -ForegroundColor Green
        $deletedCount++
    }
}

if ($deletedCount -eq 0) {
    Write-Host "      ℹ Keine Arcade Mod .dat Dateien gefunden" -ForegroundColor Gray
}

# 4. Bestätigung von unveränderten kritischen Verzeichnissen
Write-Host "[4/4] Verifiziere kritische Verzeichnisse..." -ForegroundColor Yellow
$criticalPaths = @(
    @{ Path = "$uboatPath\Saves"; Name = "/Saves" },
    @{ Path = "$uboatPath\Mods"; Name = "/Mods" },
    @{ Path = "$uboatPath\Launcher"; Name = "/Launcher" }
)

foreach ($item in $criticalPaths) {
    if (Test-Path -LiteralPath $item.Path) {
        Write-Host "      ✓ $($item.Name) vorhanden (unberührt)" -ForegroundColor Green
    } else {
        Write-Host "      ⚠ $($item.Name) nicht vorhanden!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cleanup abgeschlossen!" -ForegroundColor Green
Write-Host ""
Write-Host "Gelöschte Inhalte:" -ForegroundColor Cyan
Write-Host "  ✓ /Temp Verzeichnis"
Write-Host "  ✓ /Cache Verzeichnis"
Write-Host "  ✓ Arcade Mod .dat Dateien aus /Data Sheets"
Write-Host ""
Write-Host "Unverändert (sicher):" -ForegroundColor Cyan
Write-Host "  ✓ Spielstände (/Saves)"
Write-Host "  ✓ Andere Mods (/Mods)"
Write-Host "  ✓ Launcher Konfiguration (/Launcher)"
Write-Host "  ✓ Modliste (modlist.txt)"
Write-Host "  ✓ Einstellungen (settings.ubt)"
Write-Host ""
Write-Host "Das Spiel wird die Arcade Mod .dat Dateien beim nächsten Start" -ForegroundColor Cyan
Write-Host "automatisch aus den Mod-Dateien neu generieren." -ForegroundColor Cyan
