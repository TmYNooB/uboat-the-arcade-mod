
# ==============================================================================
# UBOAT Arcade Mod - Update Script für Spielversion 2026.1
# Führt alle notwendigen Änderungen an den Mod-XLSX-Dateien durch
# ==============================================================================

$modPath  = "c:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod\Data Sheets"
$origPath = "D:\Steam\steamapps\common\UBOAT\UBOAT_Data\Data Sheets"

Import-Module ImportExcel -Force

# ------------------------------------------------------------------------------
# HILFS-FUNKTION: Zeile in Equipment-Sheet aus Original übernehmen + abändern
# ------------------------------------------------------------------------------
function Get-OrigRow {
    param ($lookup, $id)
    if (-not $lookup.ContainsKey($id)) { Write-Host "  ⚠️  Original-ID nicht gefunden: $id" -ForegroundColor Yellow; return $null }
    return $lookup[$id]
}

# ==============================================================================
# 1. CharacterClasses.xlsx / Shared — "French Speaker" entfernen
# ==============================================================================
Write-Host "`n=== CharacterClasses.xlsx: French Speaker entfernen ===" -ForegroundColor Cyan
$pkg = Open-ExcelPackage "$modPath\CharacterClasses.xlsx"
$ws  = $pkg.Workbook.Worksheets["Shared"]
$found = $false
for ($r = 1; $r -le $ws.Dimension.Rows; $r++) {
    if ($ws.Cells[$r, 1].Value -eq "French Speaker") {
        $ws.DeleteRow($r)
        $found = $true
        Write-Host "  ✅ 'French Speaker' Zeile $r gelöscht"
        break
    }
}
if (-not $found) { Write-Host "  ℹ️  'French Speaker' nicht gefunden (evtl. schon entfernt)" }
$pkg.Save(); $pkg.Dispose()

# ==============================================================================
# 2. Entities.xlsx / Equipment — Neue Arcade-Einträge hinzufügen
# ==============================================================================
Write-Host "`n=== Entities.xlsx: Neue Equipment-Einträge ===" -ForegroundColor Cyan

$origE = Import-Excel "$origPath\Entities.xlsx" -WorksheetName "Equipment" -NoHeader
$origLookup = @{}
foreach ($row in $origE) { if ($row.P1) { $origLookup[$row.P1] = $row } }

$modE = Import-Excel "$modPath\Entities.xlsx" -WorksheetName "Equipment" -NoHeader
$modLookup = @{}
foreach ($row in $modE) { if ($row.P1) { $modLookup[$row.P1] = $row } }
$modERowNumbers = @{}
for ($i = 0; $i -lt $modE.Count; $i++) {
    if ($modE[$i].P1) { $modERowNumbers[$modE[$i].P1] = $i + 1 }
}

$pkg = Open-ExcelPackage "$modPath\Entities.xlsx"
$ws  = $pkg.Workbook.Worksheets["Equipment"]
$cols = "P1","P2","P3","P4","P5","P6","P7","P8","P9","P10","P11","P12","P13","P14","P15","P16","P17","P18","P19"

function Add-EquipRow {
    param ($ws, $rowNum, $origRow, [hashtable]$overrides)
    for ($c = 1; $c -le 19; $c++) {
        $val = $origRow.($cols[$c - 1])
        $ws.Cells[$rowNum, $c].Value = $val
    }
    foreach ($kv in $overrides.GetEnumerator()) {
        $ws.Cells[$rowNum, [int]$kv.Key].Value = $kv.Value
    }
}

function Add-Or-Skip {
    param ($id, $origRow, [hashtable]$overrides)
    if ($modLookup.ContainsKey($id)) {
        $rowNum = $modERowNumbers[$id]
        Add-EquipRow $ws $rowNum $origRow $overrides
        Write-Host "  ✅ '$id' aktualisiert (Zeile $rowNum)"
        return
    }
    if ($null -eq $origRow) { return }
    $script:nextRow++
    Add-EquipRow $ws $script:nextRow $origRow $overrides
    Write-Host "  ✅ '$id' hinzugefügt (Zeile $script:nextRow)"
}

$script:nextRow = $ws.Dimension.Rows

# --- ARTILLERIE --- #
# Artillery - 10.5 cm (Type IX Hauptkanone – gleiche Arcade-Behandlung wie 8.8cm)
$orig = Get-OrigRow $origLookup "Artillery - 10.5 cm"
Add-Or-Skip "Artillery - 10.5 cm" $orig @{
    3  = "";   # Preis = 0
    16 = "Calibre = 105, Range = 14000, ReloadTime = 0.1, MagazineSize = 4, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0, RecoilDuration = 0.23, RecoilRecovery = 0.2, RecoilGrowthRate = 1.0, RecoilRecoveryRate = 0.996"
}

# 37 mm SK C30 (Type IX Heckkanone)
# Range=10000 (nicht 7000) - muss mit der finalen Set-EquipP16-Sektion weiter unten übereinstimmen.
$orig = Get-OrigRow $origLookup "37 mm SK C30"
Add-Or-Skip "37 mm SK C30" $orig @{
    3  = "";
    16 = "Calibre = 37, Range = 10000, ReloadTime = 0.1, MagazineSize = 4, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0.1, RecoilDuration = 0.25, RecoilRecovery = 0.2, RecoilGrowthRate = 0.45, RecoilRecoveryRate = 0.981, SkippedShells = 0"
}

# 37 mm SK C30 Forward (Type IX Bugkanone)
# Range=10000 (nicht 7000) - muss mit der finalen Set-EquipP16-Sektion weiter unten übereinstimmen.
$orig = Get-OrigRow $origLookup "37 mm SK C30 Forward"
Add-Or-Skip "37 mm SK C30 Forward" $orig @{
    3  = "";
    16 = "Calibre = 37, Range = 10000, ReloadTime = 0.1, MagazineSize = 4, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0.1, RecoilDuration = 0.25, RecoilRecovery = 0.2, RecoilGrowthRate = 0.45, RecoilRecoveryRate = 0.981, SkippedShells = 0"
}

# --- MUNITION 88mm ---
# HE 88mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre HE - 88 mm"
Add-Or-Skip "Ammo Large Calibre HE - 88 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 22, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 2.0, DamageEffectsIntensity = 1.0, InitialVelocity = 800, MinDetonationVelocity = 150, ArmorPiercing = 0.0, Mass = 9.23, SelfDestructDelay = 0, ProximityExplosion = 0, TracerDuration = 26, FireChance = 1.0"
}

# AP 88mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre AP - 88 mm"
Add-Or-Skip "Ammo Large Calibre AP - 88 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 17.6, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 2.0, DamageEffectsIntensity = 1.0, InitialVelocity = 1000, MinDetonationVelocity = 150, ArmorPiercing = 1.0, Mass = 10.34, SelfDestructDelay = 0, ProximityExplosion = 0, TracerDuration = 26, FireChance = 0.25"
}

# AA 88mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre AA - 88 mm"
Add-Or-Skip "Ammo Large Calibre AA - 88 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 22, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 2.0, DamageEffectsIntensity = 1.0, InitialVelocity = 800, MinDetonationVelocity = 150, ArmorPiercing = 0.0, Mass = 9.23, SelfDestructDelay = 3.0, ProximityExplosion = 30, TracerDuration = 0, FireChance = 1.0"
}

# SS 88mm (Leuchtspur – kein Schaden, Original beibehalten außer Preis=0)
$orig = Get-OrigRow $origLookup "Ammo Large Calibre SS - 88 mm"
Add-Or-Skip "Ammo Large Calibre SS - 88 mm" $orig @{ 3 = "" }

# --- MUNITION 105mm ---
# HE 105mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre HE - 105 mm"
Add-Or-Skip "Ammo Large Calibre HE - 105 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 25, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 2.5, DamageEffectsIntensity = 1.0, InitialVelocity = 800, MinDetonationVelocity = 150, ArmorPiercing = 0.0, Mass = 9.23, SelfDestructDelay = 0, ProximityExplosion = 0, TracerDuration = 26, FireChance = 1.0"
}

# AP 105mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre AP - 105 mm"
Add-Or-Skip "Ammo Large Calibre AP - 105 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 20, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 2.5, DamageEffectsIntensity = 1.0, InitialVelocity = 1000, MinDetonationVelocity = 150, ArmorPiercing = 1.0, Mass = 10.34, SelfDestructDelay = 0, ProximityExplosion = 0, TracerDuration = 26, FireChance = 0.25"
}

# AA 105mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre AA - 105 mm"
Add-Or-Skip "Ammo Large Calibre AA - 105 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 25, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 2.5, DamageEffectsIntensity = 1.0, InitialVelocity = 800, MinDetonationVelocity = 150, ArmorPiercing = 0.0, Mass = 9.23, SelfDestructDelay = 3.0, ProximityExplosion = 30, TracerDuration = 0, FireChance = 1.0"
}

# SS 105mm (Leuchtspur – kein Schaden, Original beibehalten außer Preis=0)
$orig = Get-OrigRow $origLookup "Ammo Large Calibre SS - 105 mm"
Add-Or-Skip "Ammo Large Calibre SS - 105 mm" $orig @{ 3 = "" }

# --- MUNITION 37mm ---
# HE 37mm (auf 88mm-Niveau angehoben)
$orig = Get-OrigRow $origLookup "Ammo Large Calibre HE - 37 mm"
Add-Or-Skip "Ammo Large Calibre HE - 37 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 12, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 1.0, DamageEffectsIntensity = 1.0, InitialVelocity = 1000, MinDetonationVelocity = 150, ArmorPiercing = 0.0, Mass = 9.23, SelfDestructDelay = 0, ProximityExplosion = 0, TracerDuration = 26, FireChance = 1.0"
}

# AP 37mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre AP - 37 mm"
Add-Or-Skip "Ammo Large Calibre AP - 37 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 9, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 1.0, DamageEffectsIntensity = 1.0, InitialVelocity = 1000, MinDetonationVelocity = 150, ArmorPiercing = 1.0, Mass = 10.34, SelfDestructDelay = 0, ProximityExplosion = 0, TracerDuration = 26, FireChance = 0.25"
}

# AA 37mm
$orig = Get-OrigRow $origLookup "Ammo Large Calibre AA - 37 mm"
Add-Or-Skip "Ammo Large Calibre AA - 37 mm" $orig @{
    3  = "";
    16 = "DamageRadius = 12, Damage = 2.674, CrewDamage = 2.674, DamageEffectsRadius = 1.0, DamageEffectsIntensity = 1.0, InitialVelocity = 1000, MinDetonationVelocity = 150, ArmorPiercing = 0.0, Mass = 9.23, SelfDestructDelay = 3.0, ProximityExplosion = 30, TracerDuration = 0, FireChance = 1.0"
}

# SS 37mm (Leuchtspur – Original beibehalten außer Preis)
$orig = Get-OrigRow $origLookup "Ammo Large Calibre SS - 37 mm"
Add-Or-Skip "Ammo Large Calibre SS - 37 mm" $orig @{ 3 = "" }

# --- MUNITION SMALL CALIBRE 37/40/45mm ---
# Für Type-II/IX-Flak auf Arcade-Niveau inkl. extremer Logistikwerte.
$smallHe = "DamageRadius = 6, Damage = 8.0, CrewDamage = 0.65, DamageEffectsRadius = 0.2, DamageEffectsIntensity = 1.0, InitialVelocity = 900, MinDetonationVelocity = 150, ArmorPiercing = 0.0, Mass = 0.12, SelfDestructDelay = 3.5, ProximityExplosion = 0, TracerDuration = 26, FireChance = 1.0"
$smallAp = "DamageRadius = 4.5, Damage = 11.2, CrewDamage = 0.6, DamageEffectsRadius = 0.1, DamageEffectsIntensity = 1.0, InitialVelocity = 900, MinDetonationVelocity = 150, ArmorPiercing = 0.5, Mass = 0.12, SelfDestructDelay = 0, ProximityExplosion = 0, TracerDuration = 26, FireChance = 0.25"

$orig = Get-OrigRow $origLookup "Ammo Small Calibre HE - 20 mm"
Add-Or-Skip "Ammo Small Calibre HE - 20 mm" $orig @{ 3 = ""; 14 = "0.01"; 15 = "4000"; 16 = $smallHe }

$orig = Get-OrigRow $origLookup "Ammo Small Calibre AP - 20 mm"
Add-Or-Skip "Ammo Small Calibre AP - 20 mm" $orig @{ 3 = ""; 14 = "0.01"; 15 = "4000"; 16 = $smallAp }

# ENTFERNT: Ammo Small Calibre HE/AP - 37 mm (kein Player-Weapon, nur SK C30 Artillery)

$orig = Get-OrigRow $origLookup "Ammo Small Calibre HE - 40 mm"
Add-Or-Skip "Ammo Small Calibre HE - 40 mm" $orig @{ 3 = ""; 14 = "0.01"; 15 = "4000"; 16 = $smallHe }

$orig = Get-OrigRow $origLookup "Ammo Small Calibre AP - 40 mm"
Add-Or-Skip "Ammo Small Calibre AP - 40 mm" $orig @{ 3 = ""; 14 = "0.01"; 15 = "4000"; 16 = $smallAp }

$orig = Get-OrigRow $origLookup "Ammo Small Calibre HE - 45 mm"
Add-Or-Skip "Ammo Small Calibre HE - 45 mm" $orig @{ 3 = ""; 14 = "0.01"; 15 = "4000"; 16 = $smallHe }

$orig = Get-OrigRow $origLookup "Ammo Small Calibre AP - 45 mm"
Add-Or-Skip "Ammo Small Calibre AP - 45 mm" $orig @{ 3 = ""; 14 = "0.01"; 15 = "4000"; 16 = $smallAp }

# --- MOTOREN --- #
# Diesel Engines IIA (Noise=0, FuelUsage=0, Velocity+10 wie andere Diesel)
$orig = Get-OrigRow $origLookup "Diesel Engines IIA"
Add-Or-Skip "Diesel Engines IIA" $orig @{
    3  = "";
    16 = "/Velocity +10, Noise = 0.0, FuelUsage = 0.0, EnergyUsage = -0.55, SmokeVisibility = 0.0, MaxGearChangeDelay = 7"
}

# Electric Engines IIA (Noise=0, Velocity+10 wie andere Electric)
$orig = Get-OrigRow $origLookup "Electric Engines IIA"
Add-Or-Skip "Electric Engines IIA" $orig @{
    3  = "";
    16 = "/Velocity +10, Noise = 0.0, FuelUsage = -10.0, EnergyUsage = 0.0, MaxGearChangeDelay = 7"
}

# --- TREIBSTOFFTANKS --- #
# Fuel Tank IIA (gleich wie Fuel Tank)
$orig = Get-OrigRow $origLookup "Fuel Tank IIA"
Add-Or-Skip "Fuel Tank IIA" $orig @{
    3  = "";
    16 = "ItemsMassLimit = 27500"
}

# Fuel Tank IID (etwas größer wie Saddle Fuel Tank)
$orig = Get-OrigRow $origLookup "Fuel Tank IID"
Add-Or-Skip "Fuel Tank IID" $orig @{
    3  = "";
    16 = "ItemsMassLimit = 78000"
}

# --- TRIMPUMPE --- #
# Trim Pump Type II (gleiche extreme Durchflussrate wie Trim Pump)
$orig = Get-OrigRow $origLookup "Trim Pump Type II"
Add-Or-Skip "Trim Pump Type II" $orig @{
    3  = "";
    16 = "LitresPerSecond = 9990.06, Noise = 0.0, EnergyUsage = 0.0"
}

# --- PERISKOPE --- #
# Attack Periscope IIA (AimingPerformance maxed, Visibility=0 wie Attack Periscope)
$orig = Get-OrigRow $origLookup "Attack Periscope IIA"
Add-Or-Skip "Attack Periscope IIA" $orig @{
    3  = "";
    16 = "Length = 4.26, SightRange = 5000, GroupSightRange = 14, SignatureRadius = 8, Visibility = 0.0, Stabilization = 0.88, AimingPerformance = 999.5"
}

# Observation Periscope IIA (AimingPerformance wie Observation Periscope)
$orig = Get-OrigRow $origLookup "Observation Periscope IIA"
Add-Or-Skip "Observation Periscope IIA" $orig @{
    3  = "";
    16 = "Length = 3.26, SightRange = 5000, GroupSightRange = 10, SignatureRadius = 8, Visibility = 0.0, Stabilization = 0.88, AimingPerformance = 99.5"
}

$pkg.Save(); $pkg.Dispose()
Write-Host "`n  Equipment-Änderungen gespeichert ✅"

# ==============================================================================
# 3. Sandbox.xlsx / Tasks — Submarine Pen Build Tasks auf 1 Tag reduzieren
# ==============================================================================
Write-Host "`n=== Sandbox.xlsx: Submarine Pen Build Tasks ===" -ForegroundColor Cyan

$origT = Import-Excel "$origPath\Sandbox.xlsx" -WorksheetName "Tasks" -NoHeader
$origTLookup = @{}
foreach ($row in $origT) { if ($row.P1) { $origTLookup[$row.P1] = $row } }

$modT = Import-Excel "$modPath\Sandbox.xlsx" -WorksheetName "Tasks" -NoHeader
$modTLookup = @{}
foreach ($row in $modT) { if ($row.P1) { $modTLookup[$row.P1] = $row } }
$modTRowNumbers = @{}
for ($i = 0; $i -lt $modT.Count; $i++) {
    if ($modT[$i].P1) { $modTRowNumbers[$modT[$i].P1] = $i + 1 }
}

$pkg = Open-ExcelPackage "$modPath\Sandbox.xlsx"
$wsT = $pkg.Workbook.Worksheets["Tasks"]

# Task-Spalten: P1=ID, P2=UnlockDate, P3=Duration, P4=AIPriority, P5=Lat, P6=Lon, P7=Requirements, P8=ResearchSlot, P9=Type, P10=Slots, P11=RepPoints, P12=AppearDate, P13=LockDate...
$taskCols = "P1","P2","P3","P4","P5","P6","P7","P8","P9","P10","P11","P12","P13","P14","P15","P16","P17","P18","P19","P20"
$taskColCount = $origT[0].PSObject.Properties.Count

function Add-TaskRow {
    param ($ws, $rowNum, $origRow, [hashtable]$overrides)
    $propNames = $origRow.PSObject.Properties.Name
    for ($c = 1; $c -le $propNames.Count; $c++) {
        $ws.Cells[$rowNum, $c].Value = $origRow.($propNames[$c - 1])
    }
    foreach ($kv in $overrides.GetEnumerator()) {
        $ws.Cells[$rowNum, [int]$kv.Key].Value = $kv.Value
    }
}

function Add-Or-Skip-Task {
    param ($id, $origRow, [hashtable]$overrides)
    if ($modTLookup.ContainsKey($id)) {
        $rowNum = $modTRowNumbers[$id]
        Add-TaskRow $wsT $rowNum $origRow $overrides
        Write-Host "  ✅ Task '$id' aktualisiert (Zeile $rowNum, Duration=1)"
        return
    }
    if ($null -eq $origRow) { return }
    $script:nextTaskRow++
    Add-TaskRow $wsT $script:nextTaskRow $origRow $overrides
    Write-Host "  ✅ Task '$id' hinzugefügt (Zeile $script:nextTaskRow, Duration=1)"
}

$script:nextTaskRow = $wsT.Dimension.Rows

$buildTasks = @(
    "Build La Rochelle Submarine Pen 1",
    "Build La Rochelle Submarine Pen 2",
    "Build Helgoland Submarine Pen",
    "Build Bergen Submarine Pen",
    "Build Brest Submarine Pen 1",
    "Build Brest Submarine Pen 2"
)
foreach ($taskId in $buildTasks) {
    $orig = if ($origTLookup.ContainsKey($taskId)) { $origTLookup[$taskId] } else { $null }
    if ($null -eq $orig) { Write-Host "  ⚠️  Task '$taskId' nicht in Original gefunden" -ForegroundColor Yellow; continue }
    Add-Or-Skip-Task $taskId $orig @{ 3 = "1" }   # P3 = Duration = 1 Tag
}

$pkg.Save(); $pkg.Dispose()
Write-Host "`n  Tasks-Änderungen gespeichert ✅"

# ==============================================================================
# 4. Sandbox.xlsx / Tasks — Fuel-Produktion für Häfen massiv erhöhen
# ==============================================================================
Write-Host "`n=== Sandbox.xlsx: Fuel-Produktion erhöhen ===" -ForegroundColor Cyan

$pkg = Open-ExcelPackage "$modPath\Sandbox.xlsx"
$wsT = $pkg.Workbook.Worksheets["Tasks"]
$fuelTaskFound = $false

for ($r = 1; $r -le $wsT.Dimension.Rows; $r++) {
    if ($wsT.Cells[$r, 1].Value -eq "Produce Fuel 1") {
        # P14 steuert Initialbestand und laufende Produktion von Fuel.
        # Hohe Werte verhindern Versorgungsengpässe beim Auftanken großer Tanks.
        $wsT.Cells[$r, 14].Value = "Equipment=Fuel;Initial=50000000;Production=5000000"
        $fuelTaskFound = $true
        Write-Host "  ✅ 'Produce Fuel 1' angepasst (Initial=50.000.000, Production=5.000.000)"
        break
    }
}

if (-not $fuelTaskFound) {
    Write-Host "  ⚠️  Task 'Produce Fuel 1' nicht gefunden — bitte manuell prüfen" -ForegroundColor Yellow
}

$pkg.Save(); $pkg.Dispose()
Write-Host "`n  Fuel-Änderung gespeichert ✅"

# ==============================================================================
# 5. General.xlsx / Settings — Transfer & Upgrade weiter beschleunigen
# ==============================================================================
Write-Host "`n=== General.xlsx: Trade/Upgrade beschleunigen ===" -ForegroundColor Cyan

$pkg = Open-ExcelPackage "$modPath\General.xlsx"
$wsG = $pkg.Workbook.Worksheets["Settings"]

# WICHTIG: zwei GETRENNTE Flags nötig - eine frühere Version hat ein einziges Flag
# für "Sektion existiert überhaupt" UND "gerade innerhalb der Sektion" missbraucht.
# Da Letzteres nach dem Finden der Multiplier-Zeile bewusst auf $false zurückgesetzt
# wird (um nicht andere "Multiplier"-Zeilen in anderen Sektionen zu treffen), dachte
# der Code danach IMMER "Sektion fehlt" und versuchte bei jedem Lauf erneut, eine
# doppelte /DamageDifficulty-Sektion einzufügen (Ursache des $insertRow-Array-Fehlers).
$damageDifficultySectionExists = $false
$inDamageDifficultySection = $false
$multiplierRowFixed = $false
$resourcesRow = $null

for ($r = 1; $r -le $wsG.Dimension.Rows; $r++) {
    $id = [string]$wsG.Cells[$r, 1].Value
    if ($id -eq "/DamageDifficulty") {
        $damageDifficultySectionExists = $true
        $inDamageDifficultySection = $true
    }
    elseif ($id -like "/*") {
        $inDamageDifficultySection = $false
    }
    if ($null -eq $resourcesRow -and $id -eq "/Resources") {
        $resourcesRow = $r
    }
    if ($id -eq "Transfer Duration Factor (s/kg)") {
        $wsG.Cells[$r, 2].Value = "0.25"
    }
    if ($id -eq "Upgrade Duration Factor (s/budget unit)") {
        $wsG.Cells[$r, 2].Value = "0.25"
    }
    if ($id -eq "Hull Damage Absorption") {
        $wsG.Cells[$r, 2].Value = "0.5"
    }
    if ($id -eq "Hull Damage Scale") {
        $wsG.Cells[$r, 2].Value = "0.01"
    }
    if ($id -eq "Hull Damage Scale (Without Damage Control)") {
        $wsG.Cells[$r, 2].Value = "0.1"
    }
    if ($inDamageDifficultySection -and -not $multiplierRowFixed -and $id -eq "Multiplier") {
        $wsG.Cells[$r, 2].Value = "0.03"
        $multiplierRowFixed = $true  # Nur erste Multiplier-Zeile nach /DamageDifficulty anpassen
    }
}

if (-not $damageDifficultySectionExists) {
    if ($null -eq $resourcesRow) { throw "Weder /DamageDifficulty noch /Resources in General.xlsx gefunden - Abbruch." }
    [int]$insertRow = $resourcesRow
    $wsG.InsertRow($insertRow, 3)
    $wsG.Cells[$insertRow, 1].Value = "/DamageDifficulty"
    $wsG.Cells[$insertRow, 2].Value = "Easy"
    $wsG.Cells[$insertRow, 3].Value = "Medium"
    $wsG.Cells[$insertRow, 4].Value = "Hard"
    [int]$multiplierRow = $insertRow + 1
    $wsG.Cells[$multiplierRow, 1].Value = "Multiplier"
    $wsG.Cells[$multiplierRow, 2].Value = "0.03"
    $wsG.Cells[$multiplierRow, 3].Value = "0.6"
    $wsG.Cells[$multiplierRow, 4].Value = "1"
    Write-Host "  ✅ /DamageDifficulty-Sektion neu ergänzt (existierte noch nicht) und Easy auf 0.03 gesetzt"
}
else {
    Write-Host "  ℹ️  /DamageDifficulty-Sektion existiert bereits, Easy-Wert direkt aktualisiert"
}

$pkg.Save(); $pkg.Dispose()
Write-Host "  ✅ Trade/Upgrade-Faktoren auf 0.25 gesetzt"
Write-Host "  ✅ Hull Damage Absorption auf 0.5, Hull Damage Scale auf 0.01/0.1 gesetzt"
Write-Host "  ✅ Easy DamageDifficulty auf 0.03 gesetzt"

# ==============================================================================
# 6. Entities.xlsx / Equipment — Finales Rebalancing
#    - kleinere Tanks (nahe Original)
#    - stärkere AA-Guns (Reload/Range)
#    - sämtliche Ammo kostenfrei
# ==============================================================================
Write-Host "`n=== Entities.xlsx: Tanks/AA/Ammo-Rebalancing ===" -ForegroundColor Cyan

$origE = Import-Excel "$origPath\Entities.xlsx" -WorksheetName "Equipment" -NoHeader
$origLookup = @{}
foreach ($row in $origE) { if ($row.P1) { $origLookup[$row.P1] = $row } }

$pkg = Open-ExcelPackage "$modPath\Entities.xlsx"
$wsE = $pkg.Workbook.Worksheets["Equipment"]
$equipCols = "P1","P2","P3","P4","P5","P6","P7","P8","P9","P10","P11","P12","P13","P14","P15","P16","P17","P18","P19"

$rowById = @{}
for ($r = 1; $r -le $wsE.Dimension.Rows; $r++) {
    $id = [string]$wsE.Cells[$r, 1].Value
    if (-not [string]::IsNullOrWhiteSpace($id)) { $rowById[$id] = $r }
}

function Set-EquipP16 {
    param([string]$id, [string]$value)
    if ($rowById.ContainsKey($id)) {
        $wsE.Cells[$rowById[$id], 16].Value = $value
    }
}

# Tanks auf 2x Originalniveau setzen (arcade, aber ohne utopische Extremwerte)
Set-EquipP16 "Fuel Tank" "ItemsMassLimit = 100000"
Set-EquipP16 "Saddle Fuel Tank" "ItemsMassLimit = 99600"
Set-EquipP16 "Fuel Tank IIA" "ItemsMassLimit = 27500"
Set-EquipP16 "Fuel Tank IID" "ItemsMassLimit = 78000"

# E-Motoren/Kompressor auf stabile Arcade-Werte setzen
# Hinweis: Negativer FuelUsage-Exploit scheint in neueren Versionen nicht mehr verlässlich zu greifen.
Set-EquipP16 "Electric Engines" "/Velocity +10, Noise = 0.0, FuelUsage = -10.0, EnergyUsage = 0.0, MaxGearChangeDelay = 7"
Set-EquipP16 "Electric Engines IIA" "/Velocity +10, Noise = 0.0, FuelUsage = -10.0, EnergyUsage = 0.0, MaxGearChangeDelay = 7"
Set-EquipP16 "Electric Compressor" "EnergyUsage = 0.0, OxygenCompression = 40, Noise = 0.0, OxygenUsage = 0.0"

# AA-Guns stärker machen (Reload/Range hoch)
Set-EquipP16 "Oerlikon" "Calibre = 20, Range = 6000, ReloadTime = 0.1, MagazineSize = 60, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0.1, RecoilDuration = 0.14, RecoilRecovery = 0.2, RecoilGrowthRate = 0.7, RecoilRecoveryRate = 0.985, SkippedShells = 6"
Set-EquipP16 "AAGun - 4.5 cm" "Calibre = 45, Range = 9000, ReloadTime = 0.1, MagazineSize = 60, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0.1, RecoilDuration = 0.14, RecoilRecovery = 0.2, RecoilGrowthRate = 0.7, RecoilRecoveryRate = 0.985, SkippedShells = 6"
Set-EquipP16 "QF 3.7-inch AA gun" "Calibre = 88, Range = 12000, ReloadTime = 0.1, MagazineSize = 4, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0.2, RecoilDuration = 0.1, RecoilRecovery = 0.2, RecoilGrowthRate = 0.7, RecoilRecoveryRate = 0.985"
Set-EquipP16 "37 mm SK C30" "Calibre = 37, Range = 10000, ReloadTime = 0.1, MagazineSize = 4, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0.1, RecoilDuration = 0.25, RecoilRecovery = 0.2, RecoilGrowthRate = 0.45, RecoilRecoveryRate = 0.981, SkippedShells = 0"
Set-EquipP16 "37 mm SK C30 Forward" "Calibre = 37, Range = 10000, ReloadTime = 0.1, MagazineSize = 4, HorizontalRecoil = 0.0, MinVerticalRecoil = 0.0, MaxVerticalRecoil = 0.0, SeriesTimeOffset = 0.1, RecoilDuration = 0.25, RecoilRecovery = 0.2, RecoilGrowthRate = 0.45, RecoilRecoveryRate = 0.981, SkippedShells = 0"

# Torpedos: MaintenanceCooldown auf 180 Tage = 15.552.000 Sekunden setzen
# (Wartungsintervall für Torpedo-Elektronik/Anlagen)
$torpMaintenanceCooldown = 180 * 24 * 3600  # 15.552.000 sec
$torpoIds = @(
    "G7a Torpedo T1 - Pi1", "G7a Torpedo T1 - Pi1.1", "G7a Torpedo T1 - Pi3",
    "G7a Torpedo T1 - Pi3 - FAT", "G7a Torpedo T1 - Pi3 - LUT",
    "G7e Torpedo T2 - Pi1", "G7e Torpedo T2 - Pi1.1", "G7e Torpedo T3 - Pi2",
    "G7e Torpedo T3 - Pi2 - FAT", "G7e Torpedo T3 - Pi2 - LUT", "G7e Torpedo T3 - Pi2 - Prototype",
    "G7es Zaunkönig Torpedo T5 - Pi4", "G7es Zaunkönig Torpedo T5 - Pi4 - Prototype",
    "G7a Torpedo T1 - Pi1 (Warmed)", "G7a Torpedo T1 - Pi1.1 (Warmed)", "G7a Torpedo T1 - Pi3 (Warmed)",
    "G7a Torpedo T1 - Pi3 - FAT (Warmed)", "G7a Torpedo T1 - Pi3 - LUT (Warmed)",
    "G7e Torpedo T2 - Pi1 (Warmed)", "G7e Torpedo T2 - Pi1.1 (Warmed)", "G7e Torpedo T3 - Pi2 (Warmed)",
    "G7e Torpedo T3 - Pi2 - FAT (Warmed)", "G7e Torpedo T3 - Pi2 - LUT (Warmed)", "G7e Torpedo T3 - Pi2 - Prototype (Warmed)",
    "G7es Zaunkönig Torpedo T5 - Pi4 (Warmed)", "G7es Zaunkönig Torpedo T5 - Pi4 - Prototype (Warmed)"
)
foreach ($torpId in $torpoIds) {
    if ($rowById.ContainsKey($torpId)) {
        $currentP16 = [string]$wsE.Cells[$rowById[$torpId], 16].Value
        # Ersetze MaintenanceCooldown-Wert mit dem neuen (falls er existiert)
        if ($currentP16 -match 'MaintenanceCooldown\s*=\s*[0-9.]+') {
            $newP16 = $currentP16 -replace 'MaintenanceCooldown\s*=\s*[0-9.]+', "MaintenanceCooldown = $torpMaintenanceCooldown"
            $wsE.Cells[$rowById[$torpId], 16].Value = $newP16
        }
    }
}
Write-Host "  ✅ Torpedo MaintenanceCooldown auf 180 Tage ($torpMaintenanceCooldown sec) gesetzt"

# Alle BEREITS IM MOD vorhandenen Ammo-Zeilen auf kostenfrei setzen (Price="").
#
# WICHTIG - NIEMALS über $origLookup (= alle ~86 Vanilla-Ammo-Typen) loopen und
# fehlende IDs neu hinzufügen! Das würde jede Menge NPC-/Exoten-Kaliber (76mm,
# 100mm, 102mm, 114mm, 120mm, 130mm, 133mm, 152mm, 180mm, 203mm, 406mm, ...) in
# die Mod kopieren und die Equipment-Sheet wieder von ~181 auf 230+ Zeilen
# aufblähen. Genau dieses Muster ('Vanilla-Loop fügt fehlende IDs hinzu') hat
# die Mod bereits mehrfach ruiniert (siehe CHANGELOG/Memory zu 260703-Restore).
# Nur $rowById (= aktuell in der Mod vorhandene Zeilen) ist hier erlaubt.
$ammoUpdated = 0
foreach ($id in @($rowById.Keys | Where-Object { $_ -like "Ammo *" })) {
    $wsE.Cells[$rowById[$id], 3].Value = ""
    $ammoUpdated++
}

$pkg.Save(); $pkg.Dispose()
Write-Host "  ✅ Ammo kostenfrei gesetzt (aktualisiert=$ammoUpdated, keine neuen Zeilen hinzugefügt)"

# ==============================================================================
# FERTIG
# ==============================================================================
Write-Host "`n✅ Alle Mod-Updates abgeschlossen!" -ForegroundColor Green
Write-Host "   Bitte Cache leeren und Spiel starten um zu testen."
Write-Host "   Cache: %UserProfile%\AppData\LocalLow\Deep Water Studio\UBOAT\ → Temp, Data Sheets, Cache löschen"
