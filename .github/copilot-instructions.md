# UBOAT Arcade Mod – Copilot Instructions

## Projektübersicht
Dieser Mod macht UBOAT deutlich arcade-lastiger ("less sim"). Inspiriert von alten U-Boot-Simulationen wie "Das Boot".

- **Mod-Name:** UBoat the Arcade Mod
- **Ursprüngliche Spielversion:** 2022.1 patch 22
- **Aktuelle Spielversion:** 2026.1 (April 2026, inkl. Type IX: Distant Coasts DLC)
- **Mod-Pfad:** `c:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Mods\uboat-the-arcade-mod`
- **Original Data Sheets:** `D:\Steam\steamapps\common\UBOAT\UBOAT_Data\Data Sheets`

---

## UBOAT Modding-System – Wie es funktioniert

- Mod-XLSX-Dateien **überschreiben nur Zeilen mit übereinstimmender ID** (Spalte P1)
- Die Mod muss **nicht** alle Original-Einträge enthalten — nur die geänderten Zeilen
- Sections (Zeilen die mit `/` beginnen in P1) müssen ebenfalls vorhanden sein damit der Parser den Kontext kennt
- Sheets müssen denselben Namen haben wie im Original
- Ladereihenfolge: Erst Original, dann Mods in Launcher-Reihenfolge

---

## Was der Mod ändert – Übersicht der Arcade-Features

### General.xlsx / Settings
| Bereich | Änderung | Effekt |
|---------|----------|--------|
| `/Discipline` | Straf-Deltas alle 0, Stress-Gain reduziert | Crew verliert keine Disziplin |
| `/Travel` | Food Consumption = 0, Navigation Penalty = 0 | Kein Proviant bei Fast Travel, keine Nav-Strafen |
| `/Actions` | Torpedo-Ladezeit: 1s (statt 8/14s), Nav-Fix fast instant | Torpedos sofort ladbar |
| `/Resources` | Energy Recharge Rate = 100, Compressed Air Launch = 0 | Akkus laden blitzschnell, kein Druckluftverbrauch |
| `/Trade` | Transfer=1s/kg (statt 120), Upgrade=1s/budget (statt 20) | Upgrades und Transfers sofort |

### Entities.xlsx / Equipment – Wichtigste Arcade-Änderungen
| Item-Gruppe | Änderung |
|-------------|----------|
| **Alle Torpedos** (G7a T1, G7e T2/T3, G7es T5 + Warmed) | Preis=0, Damage=50, DudChance=0, Range=40000 |
| **Artillery 8.8cm** | ReloadTime=0.1 (fast sofort), Range=12000 |
| **Alle Ammo-Typen** (HE/AP/AA/SS) | Damage massiv erhöht |
| **Ventilation** | OxygenGain=0.11 (Basis), EnergyUsage=0 — sehr viel O₂ |
| **Diesel/Electric Engines** | Velocity+10, Noise=0, FuelUsage=0 |
| **Kompressoren** | OxygenCompression erhöht, Noise=0 |
| **Fuel Tanks** | ItemsMassLimit massiv erhöht (unbegrenzt Treibstoff) |
| **Periskope/Sight/Binocular** | SightRange erhöht, AimingPerformance extrem hoch (999.5) |
| **Trim Pump** | LitresPerSecond massiv erhöht, Noise=0 |
| **Kitchen** | FoodConsumptionRate=0 |
| **Storage-Compartments** | ItemsMassLimit massiv erhöht |

### Sandbox.xlsx / Tasks
- Alle Forschungs-/Upgrade-Tasks: Dauer von 5–16 Tagen auf **1 Tag** reduziert
- Research-Tasks, Send Officer, Identify Defense, Ammo/Equipment Production betroffen

### Sandbox.xlsx / Settings (Schwierigkeitsreduktion)
- Bleeding Rate = 0, Evacuation Drown/Capture Chance = 0
- Incubation Min/Max Time = 0.1 (Krankheiten heilen sofort)
- Hunger: Keine Disziplin-Strafen bei Hunger

### CharacterClasses.xlsx
- Alle Skills in Radioman/Leader/Engineer: `P5 = True` (alle Skills standardmäßig freigeschaltet)
- Sensitive Hearing (Radioman): verbesserte Hydrophone-Parameter

---

## Analyse-Ergebnisse: Was hat sich seit 2022.1 geändert?

### ✅ IDs die im Mod sind und noch existieren: ALLE (missing=0)
Alle 163 Equipment-IDs des Mods existieren noch im aktuellen Spiel.

### ⚠️ BEKANNTE PROBLEME / UPDATE-BEDARF

#### CharacterClasses/Shared – "French Speaker" entfernt
- Die ID `French Speaker` ist in der Mod-Datei, existiert aber **nicht mehr** im Original
- Dies sollte keine Crash verursachen (unbekannte IDs werden ignoriert), aber prüfen
- **Empfehlung:** Zeile aus Mod entfernen oder Spiel-Log prüfen ob Fehler auftreten

#### Neue Equipments ohne Arcade-Behandlung (252 neue IDs)
Folgende neue Spielelemente haben noch keine Arcade-Werte:

**Neue Artillerie (bräuchten ReloadTime/Range-Anpassung wie 8.8cm):**
- Artillery - 10 cm, 10.2 cm, 10.5 cm, 11.4 cm, 12 cm, 13 cm, 13.3 cm, 18 cm, 20.3 cm, 40.6 cm, 7.6 cm
- 37 mm SK C30, 37 mm SK C30 Forward

**Neue Munition (bräuchten erhöhten Damage wie andere Ammo):**
- Ammo Large Calibre HE/AP/AA/SS für: 100mm, 102mm, 105mm, 114mm, 120mm, 130mm, 133mm, 152mm, 180mm, 203mm, 37mm, 406mm, 76mm
- Ammo Small Calibre für: 37mm, 40mm, 45mm

**Neue U-Boot-Upgrades:**
- Turm IIA, Turm IID, Turm VIIB (neue Conning Tower Varianten)
- Diesel Engines IIA, Electric Engines IIA
- Fuel Tank IIA, Fuel Tank IID
- Additional Compressor (wie Compressor/Electric Compressor behandeln)
- Trim Pump Type II (wie Trim Pump behandeln)

**Neue Tasks ohne Arcade-Dauer:**
- Build La Rochelle/Helgoland/Bergen/Brest Submarine Pen: 30 Tage
- Ggf. auf 1 Tag reduzieren wie andere Research-Tasks

#### Neue Felder in General/Settings (neu seit 2022)
Folgende Sektionen existieren im Spiel aber nicht in der Mod — könnten Arcade-Werte brauchen:
- `/DamageDifficulty`: Multiplier für Easy/Medium/Hard Schaden
- `/Torpedoes`: Realistic Flaws Parameter
- `/Experience`: Erfahrungspunkte für verschiedene Aktionen
- `/Economy`: Buy/Sell Price Multiplier

---

## GitHub Copilot Workflow (Automatisierung & Memory)

### GitHub Repo Workflow (verbindlich)

- **Canonical Repo:** `https://github.com/TmYNooB/uboat-the-arcade-mod`
- **Vor jeder Änderung:** `git fetch origin` und `git status -sb` ausführen, damit klar ist ob lokal und remote synchron sind.
- **Branch-Strategie:**
	- Kleine, risikoarme Änderungen direkt auf `main`.
	- Größere oder riskante Umbauten auf Feature-Branch (`feature/...`) und erst nach Review auf `main`.
- **Commit-Disziplin:**
	- Nur relevante Dateien stagen (kein blindes `git add .`, außer explizit gewünscht).
	- Commit-Messages kurz und fachlich, mit klarem Scope (z. B. `tune torpedo magnetic params`).
- **Push-Disziplin:**
	- Nach Commit immer `git push` und anschließend kurz `git rev-parse HEAD` vs. `git rev-parse origin/main` prüfen.
	- Bei Divergenz zuerst klären, nicht hart überschreiben.
- **Secret-Sicherheit:**
	- Niemals Tokens, API-Keys, Session-Cookies oder Passwörter in Dateien, Commits oder Changelogs schreiben.
	- Vor Workshop-Upload einen Secret-Scan fahren (z. B. mit `Source/secret-audit.ps1`), Ausgabe nur maskiert.
- **Cross-Referenzen aktuell halten:**
	- Bei Repo-/Workshop-Link-Änderungen immer beide Seiten aktualisieren:
		- `STEAM_DESCRIPTION.txt` (Workshop-Text)
		- `README.md` (GitHub-Startseite)

### Copilot Best Practice - **IMMER DIESE REIHENFOLGE:**

1. **Am Start jeder Task:** `search_memory` ausführen
   - Sucht Repo-Konventionen, Scripts, bisherige Fixes
   - Verhindert Doppelarbeit und erkennt Bekannte Probleme
   - Queries können sehr spezifisch sein: z.B. "cleanup cache", "steam upload", "torpedo parameters"

2. **Bestehende Scripts NUTZEN vor ad-hoc Commands:**
   - Wenn `Source/cleanup-mod-cache.ps1` existiert → nutzen, nicht neu schreiben
   - Wenn `Source/torpedo-param-audit.ps1` existiert → nutzen statt PowerShell-Einzeiler
   - Scripts in `/Source` sind verifiziert und getestet

3. **Am Ende einer Task:** `save_memory` ausführen
   - Neue Erkenntnisse: Bugs, Fixes, Best Practices
   - Neue Scripts: Location, Scope, Nutzungshinweise
   - Warnsignale: Dinge die "zu viel" löschen, Breaking Changes

4. **Transparenz:** Alle Memory-Operationen sichtbar (kein Verstecken)
   - User sieht, was gelernt wird
   - User sieht, was Scripts verfügbar sind
   - User kann Feedback geben: "Das war falsch gelernt" → `delete_memory`

### Scripts Verzeichnis (`Source/`)

Verfügbare automatisierte Tasks:
- `cleanup-mod-cache.ps1` — Sichere Cache/Temp Cleanup (selektiv!)
- `steam-upload.ps1` — Workshop Upload mit Changelog-Integration
- `update-mod.ps1` — Mod-Dateien updaten
- `torpedo-param-audit.ps1` — Torpedo-Parameter Analyse

**WICHTIG — XLSX ist führend, nicht das Script:**
- Die Mod-XLSX-Dateien in `/Data Sheets/` sind die **einzige Wahrheit** für Spielwerte.
- `update-mod.ps1` ist ein **Regenerierungs-Werkzeug**, das die XLSX neu aufbaut. Es muss immer die aktuellen XLSX-Werte widerspiegeln.
- Wenn ein Wert direkt in der XLSX geändert wird (ohne das Script zu laufen), **muss das Script manuell aktualisiert werden**, damit es beim nächsten Lauf nicht überschreibt.
- Vor dem Ausführen von `update-mod.ps1` prüfen: stimmen die Script-Werte mit den XLSX-Werten überein?
- Neue/geänderte Werte werden nach jeder manuellen XLSX-Änderung in das Script zurückgeschrieben.

**Regel:** Bevor ich einen Terminal-Befehl schreibe, checke ich:
1. Existiert bereits ein Script dafür in `/Source`?
2. Wenn ja → nutzen, nicht neu erfinden

### Memory Tags (für bessere Suche)

Häufige Memory-Tags in diesem Repo:
- `cleanup`, `cache`, `critical` — UBOAT Cache-Management
- `steam-workshop`, `upload`, `changelog` — Steam Integration
- `torpedo`, `parameters`, `balance` — Gameplay-Tuning
- `bestpractice`, `workflow`, `automation` — Meta-Workflows

---

## Entwicklungs-Workflow

### Analyse-Tools (PowerShell + ImportExcel)
```powershell
# Modul installieren (einmalig)
Install-Module ImportExcel -Scope CurrentUser -Force

# Sheets einer XLSX-Datei auflisten
(Get-ExcelSheetInfo "path\to\file.xlsx").Name

# Mod vs. Original vergleichen
$mod = Import-Excel "...\Mod\Data Sheets\Entities.xlsx" -WorksheetName "Equipment" -NoHeader
$orig = Import-Excel "D:\Steam\...\Entities.xlsx" -WorksheetName "Equipment" -NoHeader
```

### Wichtige Hinweise
- Beim Testen Mod im UBOAT-Launcher aktivieren
- **Cache leeren nach Änderungen:** Nutze `Source/cleanup-mod-cache.ps1` 
  - ⚠️ SICHERE Routine: Löscht SELEKTIV nur Arcade Mod .dat Dateien
  - Verhindert Kollateralschäden bei anderen Mods/DLCs (z.B. free-skins-1)
  - ❌ NICHT: `/Data Sheets/` komplett löschen (würde andere Mods zerstören)
  - `Data Sheets` enthält vom Spiel generierte `.dat`-Sheets
- Spielversion in `Manifest.json` > `supportedGameVersions` anpassen
- Für Steam-Upload-Workflows immer den Steam-Benutzernamen `deathpoint` als Standard verwenden (sofern nicht explizit anders gewünscht)

### Release-Disziplin (verbindlich)
- Wenn Gameplay/Balancing/Data-Sheets/Skripte geändert werden, immer auch `CHANGELOG.md` aktualisieren.
- `CHANGELOG.md` ebenfalls ohne Fließtext pflegen: kurze Überschrift + kompakte Bulletpoints mit konkreten Änderungen.
- In `CHANGELOG.md` bei Zahlenwerten immer explizit `alt -> neu` notieren.
- In `CHANGELOG.md` pro Eintrag kurz den Scope nennen (z. B. "alle 26 Torpedos"), damit Auswirkungen sofort sichtbar sind.
- Wenn ein neuer Changelog-Stand/Release-Eintrag entsteht, immer `Manifest.json` `version` auf denselben Release-Stand anheben (z. B. Changelog 1.2 -> Manifest 1.2).
- Vor Abschluss kurz prüfen, dass `CHANGELOG.md`-Version und `Manifest.json`-`version` identisch sind.
- Für Workshop-Upload immer einen klaren Changelog-Text mitgeben; Standard ist `CHANGELOG.md`.
- Steam-`changenote` robust nur als Einzeiler: keine Multi-Line-Markdown-Blöcke, keine komplexe Formatierung.
- Workshop-Changelog-Stil: **nur fachlich und spielrelevant**. Kein Fließtext, keine internen Dev-Details.
- Workshop-Changelog darf **nicht** enthalten: Recovery-Script-Historie, Refactoring-Details, Script-Fehleranalysen, interne Debug- oder Repo-Cleanup-Themen.
- Changelog-Template für Steam (verbindlich):
	- `== GAMEPLAY TUNING ==`
	- `- [Parameter]: [alt] -> [neu]`
	- `== AMMO / SCOPE ==`
	- `- [Betroffene Ammo/Gruppen], inkl. Excludes/Inkludes`
	- `== BETROFFENE EINHEITEN ==`
	- `- [z. B. Type IX], [welche Werte gelten]`
	- `== SCOPE ==`
	- `- [Anzahl/Umfang, z. B. alle 26 Torpedos]`
- Upload-Befehl bevorzugt: `steam-upload.ps1 -SteamCmdPath "...\\steamcmd.exe" -ChangeNote "Kurztext"` oder `-ChangeNoteFile "CHANGELOG.md"`.
- Wenn auf Steam erneut "Automated update" erscheint: `.steam-upload/item.vdf` Feld `changenote` prüfen und Upload mit explizitem `-ChangeNote` wiederholen.
- Nach **jedem** erfolgreichen Upload Pflichtschritt: Steam-Changelog-Seite im Browser öffnen/neu laden und den neuesten Eintrag prüfen.
- Falls Format/Content nicht passt, den neuesten Eintrag direkt über `Bearbeiten` im Browser korrigieren (nicht auf den nächsten Upload warten).

### Kommunikationsstil (Assistant)
- Tonfall: seemännisch, humorvoll, gelegentlich sarkastisch und mit trockenem Humor.
- Stil gilt vor allem für normale Rückmeldungen; bei Fehlern/risikoreichen Schritten trotzdem klar, präzise und eindeutig bleiben.
- Zusammenarbeit auf Augenhöhe: User und Assistant sind gleichwertige Kollaboratoren, kein hierarchischer Ton.
- Falls eine Bezeichnung nötig ist: neutral-kollegial (z. B. "Bootsmann"), aber nicht befehlend und nicht unterwürfig.

---

## Changelog

### Stand 2026-06-10 (Analyse)
- Vollständige Analyse aller 4 Mod-Dateien durchgeführt
- Vergleich mit aktuellem Spielstand (2026.1)
- 252 neue Equipment-IDs im Spiel seit 2022 identifiziert
- 826 neue Tasks identifiziert (davon keine neuen Research-Tasks mit Dauer)
- "French Speaker" in CharacterClasses/Shared als Problem identifiziert
- Keine IDs aus altem Mod sind weggefallen (alle 163 Equipment-IDs noch vorhanden)

### Stand 2026-06-11 (Update auf 2026.1)
- Manifest.json: `supportedGameVersions` um "2026.1" ergänzt
- CharacterClasses/Shared: "French Speaker" entfernt (ID nicht mehr im Spiel)
- Entities/Equipment: 18 neue Einträge hinzugefügt:
	- **Artillery - 10.5 cm** (Type IX Hauptdeck): ReloadTime=0.1, MagazineSize=4, Recoil=0
	- **37 mm SK C30** + **37 mm SK C30 Forward** (Type IX Aft/Bug): ReloadTime=0.1, MagazineSize=4
	- **Ammo Large Calibre HE/AP/AA/SS - 105 mm**: Damage 5-6x erhöht (HE=5.0, AP=6.0, AA=5.0)
	- **Ammo Large Calibre HE/AP/AA/SS - 37 mm**: Damage auf 88mm-Niveau (HE=3.0, AP=4.0, AA=3.0)
	- **Diesel Engines IIA**: /Velocity+10, Noise=0, FuelUsage=0
	- **Electric Engines IIA**: /Velocity+10, Noise=0
	- **Fuel Tank IIA**: ItemsMassLimit=11000000
	- **Fuel Tank IID**: ItemsMassLimit=49800000
	- **Trim Pump Type II**: LitresPerSecond=9990.06, Noise=0
	- **Attack Periscope IIA**: AimingPerformance=999.5, Visibility=0
	- **Observation Periscope IIA**: AimingPerformance=99.5, Visibility=0
- Sandbox/Tasks: 6 Submarine Pen Build Tasks auf Duration=1 gesetzt
	(Build La Rochelle/Helgoland/Bergen/Brest Submarine Pen 1+2)

### Stand 2026-06-11 (Ammo + Notfall-Boot)
- Entities/Equipment: Kanonenmunition auf extreme Logistik gesetzt
	- Alle **Ammo Large/Small Calibre** + **88mm Ammo**: `Mass=0.01`, `StackLimit=4000`
	- **Large/Small/Flak Ammunition Storage**: `ItemsMassLimit=9999999`
- Verifiziert: **Trim Pump** und **Trim Pump Type II** bleiben auf Arcade-Werten
	- `LitresPerSecond=9990.06`, `Noise=0`, `EnergyUsage=0`
- Hinweis Torpedos: Torpedo-Stacks sind weiterhin `1` pro Item; Launcher-/Tube-Kapazität bleibt über U-Boot-Layout begrenzt

<!-- ContextNudge: Auto-generated instructions for GitHub Copilot -->
<!-- Do not remove this section if you want Copilot to use your local memory -->

## ContextNudge – Local Memory Instructions

**At the start of every task, before any other tool call, run `search_memory` first.** Build the query from the user request plus the workspace name, repository identity, active file path, and any relevant error text. Once results return, use only the memories that are clearly relevant and ignore stale or low-confidence ones — but always run the search, even for small tasks.

If `search_memory` returns nothing, this workspace has no memories yet. Treat the task as a chance to seed them and plan to save what you learn.

**At the end of a task, call `save_memory`** whenever you established something durable and reusable: a stable repo convention, a recurring fix, a confirmed build or test command, an architectural decision, or a personal coding preference. Only skip saving when nothing durable came out of the task — do not save filler just to save something.

Save one atomic memory per call:
- Prefer one actionable fact, not a paragraph, checklist, or multi-topic dump.
- Keep summaries concise and specific; include exact command/flag/class names when relevant.
- Use scope intentionally: `repo` for repository-wide facts, `workspace` for local workspace details, `file-pattern` for file-specific rules, and `global` only for cross-project preferences.
- Add 1-3 useful tags (for example: build, test, runtime, architecture, troubleshooting, security, workflow).
- Set lower confidence for inferred or partially verified details.
- Use expiration for volatile details (temporary env vars, rotating endpoints, short-lived workarounds).

**Never save**: secrets, credentials, tokens, API keys, customer data, personal data, raw chat transcripts, full stack traces, or temporary guesses.

<!-- End ContextNudge -->
