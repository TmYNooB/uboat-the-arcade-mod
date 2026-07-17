# Changelog

All notable changes to this mod are documented in this file.

## 1.7.22 - 2026-07-17 (DAMAGE FACTOR INSPECTION HELPER)

### Damage factor analysis helper added

- Added Source/inspect-damage-factors.ps1 to calculate incoming-damage reduction factors versus vanilla
- Script compares current values and rollback "valuesBefore" snapshot for Hull Damage Scale / Without Damage Control / Absorption
- Script also includes the active Easy difficulty multiplier in the same calculation path

## 1.7.21 - 2026-07-17 (NUMBER FORMAT AUDIT HARDENING)

### Numeric separator audit expanded

- Added Source/number-format-audit-deep.ps1 to compare decimal separator format against vanilla even in mixed text fields (not only pure numeric cells)
- Added Source/number-format-audit-2026-07-17.json as baseline audit output (pure numeric cells + parameter key/value checks)
- Added Source/number-format-audit-deep-2026-07-17.json as deep-token audit output (mixed-text decimal token checks)
- Verified result: 0 comma/dot mismatches across all mod override rows checked versus original Data Sheets

## 1.7.20 - 2026-07-17 (HULL DAMAGE TEST TUNING)

### Hull damage parameters tightened for test run

- General.xlsx / Settings /Damages / Hull Damage Absorption: 0.9 -> 0.999
- General.xlsx / Settings /Damages / Hull Damage Scale: 0.01 -> 0.0001
- General.xlsx / Settings /Damages / Hull Damage Scale (Without Damage Control): 0.1 -> 0.001

### Rollback safety snapshot added

- Added Source/rollback-hull-damage-values-2026-07-17.json with pre-change values for quick restore during testing

## 1.7.19 - 2026-07-16 (INCOMING DAMAGE TUNING)

### Easy damage reduced further

- General.xlsx / Settings /DamageDifficulty / Multiplier (Easy): 0.03 -> 0.01

### Hull absorption increased

- General.xlsx / Settings /Damages / Hull Damage Absorption: 0.5 -> 0.9

### Script synchronization

- update-mod.ps1 updated to keep `DamageDifficulty Easy = 0.01`
- update-mod.ps1 updated to keep `Hull Damage Absorption = 0.9`

---

## 1.7.18 - 2026-07-16 (TYPE VIIC PLAYER OVERRIDE REMOVED + DIESEL COMPRESSOR TRIAGE)

### Removed stale Type VII player override

- Entities.xlsx / Types: removed mod override row `Type VIIC (Player)`
- Effect: Type VII C player stats now fall back to vanilla base row instead of the old extreme mod row

### Diesel compressor investigation (Type II / VII / IX)

- Original player slots for Type IIA/IID/VIIB/VIIC/VIIC41 all use the same compressor slot IDs:
  - `Additional Compressor`
  - `Diesel Engine Compressor`
- In current original Data Sheets, no `Type IX` rows/sections are present in `Entities.xlsx` (`Types`/`Slots`)
- Mod compressor source of the overpowered behavior is in `Entities.xlsx / Equipment`:
  - `Junkers Diesel Compressor` P16 `OxygenCompression = 800` (original is `8`)

### Compressor oxygen values normalized

- Entities.xlsx / Equipment: Junkers Diesel Compressor OxygenCompression 800 -> 40
- Entities.xlsx / Equipment: Electric Compressor OxygenCompression remains 40 (confirmed)
- update-mod.ps1 synchronized: both compressor P16 targets set to OxygenCompression = 40

---

## 1.7.17 - 2026-07-16 (BATTERY/ENGINE CHARGING TUNING + CAMOUFLAGE DATA CHECK)

### Battery and engine charging values normalized

- General.xlsx / Settings: Energy Recharge Rate 100,00 -> 1,00
- Entities.xlsx / Equipment: Diesel Engines EnergyUsage -0.55 -> -1.0
- Entities.xlsx / Equipment: Diesel Engines IIA EnergyUsage -0.55 -> -1.0
- Entities.xlsx / Equipment: Electric Engines FuelUsage -10.0 -> -1.0
- Entities.xlsx / Equipment: Electric Engines IIA FuelUsage -10.0 -> -1.0

### Script sync (avoid reverting on next generator run)

- update-mod.ps1 now applies the same values for Energy Recharge Rate and engine P16 strings
- update-mod.ps1 now sets both Diesel Engines and Diesel Engines IIA in the final Set-EquipP16 pass

### Camouflage bug triage (data-side)

- Original uses dedicated camouflage content in Entities.xlsx / Slots + Equipment and Sandbox.xlsx / Tasks (Research Camouflage ...)
- Mod does not override camouflage rows in Entities / Equipment or Sandbox / Tasks
- Mod Entities.xlsx only contains Types + Equipment sheets (no Slots override), so camouflage slot/task behavior falls back to vanilla data

---

## 1.7.16 - 2026-07-11 (CLEAN BASELINE RESTORE + CRITICAL SCRIPT BUG FIXES)

### Root Cause: Automated Recovery Scripts Violated Core Modding Convention

Two earlier automated "recovery" attempts (`rebuild-mod-xlsx.ps1`, `correct-recovery-all-rows.ps1`) copied **all ~416 vanilla Equipment rows** into the mod instead of only the changed ones. This directly violates this repo's core rule ("mod XLSX must contain ONLY changed rows, matched by ID") and repeatedly bloated `Entities.xlsx`/Equipment from 165 rows to 400+, overwriting some values with guessed/incorrect parameters in the process.

**Fix:** Rebuilt all 4 Data Sheets from the verified-clean 2026-07-03 Workshop baseline (external download, pre-dates the corruption), then re-applied only the exact, byte-verified deltas already documented in v1.7.14/v1.7.15 (88/105/37mm Large Calibre unification, 40/45mm Small Calibre damage fix, DamageDifficulty Easy=0.03). Result verified value-by-value against the baseline: 16 new munition rows + 10 minor in-place refinements in Entities.xlsx/Equipment, 1 value change in General.xlsx/Settings, zero differences everywhere else. No gameplay values changed versus the intended v1.7.15 state — this is a provenance/integrity fix.

**Scope:** Data Sheets/*.xlsx (full rebuild from verified baseline)

### Critical Bug Fixes in update-mod.ps1

**1. Ammo "free price" loop would have added 57 unwanted vanilla ammo rows.** The loop iterated over *all* vanilla `Ammo *` IDs (86 total, including NPC/exotic calibers like 76mm/100mm/102mm/114mm/120mm/130mm/133mm/152mm/180mm/203mm/406mm) and added any missing ones straight from vanilla. This is the exact "copy everything" anti-pattern described above, just scoped to ammo. Fixed to only touch ammo IDs already present in the mod (29 rows) — never adds new rows.

**2. DamageDifficulty section: duplicate-insert bug + crash.** A single boolean flag was reused for two different meanings ("currently inside the section" vs. "section exists at all"), and got reset to `false` right after fixing the `Multiplier` row. This made the post-loop check always think the section was missing, so every run tried to insert a **second** `/DamageDifficulty` section — corrupting `General.xlsx` (confirmed: one bad run left 2 section headers and +3 stray rows) and crashing on `$insertRow + 1` because the row reference wasn't a plain integer. Fixed with two separate, correctly-scoped flags and explicit `[int]` typing; verified with two consecutive runs producing zero row growth and exactly one section.

**3. Stale duplicate value:** `37 mm SK C30` / `37 mm SK C30 Forward` Range was set to `7000` in one section and `10000` in another (later) section of the same script — the second write silently won. Unified to `10000` in both places.

**Scope:** update-mod.ps1

### Repo Cleanup

- Deleted `Source/correct-recovery-all-rows.ps1` and `Source/rebuild-mod-xlsx.ps1` — both implemented the dangerous "copy all vanilla rows" pattern. **Do not recreate this pattern.**
- Deleted `_backups/` (stale/corrupt backup copies from the recovery attempts above; the verified 2026-07-03 Workshop download remains the external reference baseline).

---

## 1.7.15 - 2026-07-10 (BALANCED DECK GUN MUNITION + FIRE RATE BUFF)

### Unified Munition Damage Buff: 88mm/105mm/37mm auf Damage=2.674

Die drei Deckgun-Kalliber erhalten unified damage buffing: **alle Large Calibre Munitionstypen (HE/AP/AA/SS) = Damage 2.674**. Zugleich erhalten alle Deckguns massive ReloadTime reduction für Arcade fire rate.

**Balance-Entscheidung:**
- 88mm war Fire-Rate-only (70× schneller, Damage vanilla), jetzt auch Damage 2.674
- 105mm war 5.0/6.0/48.0, jetzt unified zu 2.674
- 37mm war 3.0/4.0/36.0, jetzt unified zu 2.674
- Alle Waffen: ReloadTime 0.1, MagazineSize = 4

**Added/Updated:**
- Ammo Large Calibre HE/AP/AA/SS - 88 mm: neu hinzugefügt mit Damage=2.674
- Ammo Large Calibre HE/AP/AA/SS - 105 mm: aktualisiert auf Damage=2.674 (war 5.0/6.0/48.0)
- Ammo Large Calibre HE/AP/AA/SS - 37 mm: aktualisiert auf Damage=2.674 (war 3.0/4.0/36.0)

**Weapons (all updated with arcade buffs):**
- Artillery - 8.8 cm: ReloadTime 7→0.1, MagazineSize 1→4
- Artillery - 10.5 cm: ReloadTime 7→0.1, MagazineSize 1→4
- 37 mm SK C30: ReloadTime 2.0→0.1, MagazineSize 1→4
- 37 mm SK C30 Forward: ReloadTime 2.0→0.1, MagazineSize 1→4

**Scope:** Entities.xlsx / Equipment (12 munitionstypen, 4 waffen)

### Cleanup: 37mm Small Calibre Munition entfernt

37mm Small Calibre (HE/AP) hat keine entsprechende Player-Waffe (SK C30 ist Artillery-only). Diese Einträge wurden entfernt.

**Removed:**
- Ammo Small Calibre HE - 37 mm
- Ammo Small Calibre AP - 37 mm

**Beibehaltene Small Calibre:**
- 20mm (Flak guns), 40mm (PomPom), 45mm (AAGun) — haben Player-Waffen

**Scope:** Entities.xlsx / Equipment

### Script-Synchronisation (update-mod.ps1)

- Alle Munitionstypen korrekt mit P16 Damage=2.674
- 37mm Small Calibre removed
- Unified Damage-Ansatz für bessere Wartung

---

## 1.7.14 - 2026-07-10 (INCOMING DAMAGE REBALANCE + AMMO FIX)

### DamageDifficulty Easy weiter reduziert

Analysis showed enemy small-calibre fire (20mm, 37mm) was still hitting ~3× harder than vanilla Easy despite hull damage reductions, because the ammo damage buffs (470×) exceeded the hull damage reduction (100×).

**Changed:**
- DamageDifficulty Multiplier (Easy): 0.1 -> 0.03

**Scope:** General.xlsx / Settings /DamageDifficulty

### Small Calibre 37/40/45mm Ammo: P16 korrigiert

The 37mm/40mm/45mm small calibre ammo entries existed in the mod with empty P16 (reverting to vanilla near-zero damage, making player AA guns ineffective). Now aligned to 20mm values.

**Added/Fixed (P16 now set, matching 20mm values):**
- Ammo Small Calibre HE - 37/40/45 mm: Damage = 8.0 (was empty/vanilla ~0.033)
- Ammo Small Calibre AP - 37/40/45 mm: Damage = 11.2 (was empty/vanilla ~0.043)

**Scope:** Entities.xlsx / Equipment

### Large Calibre 105mm + 37mm Ammo: wiederhergestellt

Research confirmed 10.5 cm SK C/32 and 3.7 cm SK C/30 are exclusively German U-boat weapons (Type IX standard armament per Wikipedia). These ammo types are 100% player-only — no Allied ship uses these calibers.

**Re-added to mod (were incorrectly removed):**
- Ammo Large Calibre HE/AP/AA/SS - 105 mm: Arcade-Damage + Mass=0.01 + StackLimit=4000
- Ammo Large Calibre HE/AP/AA/SS - 37 mm: Arcade-Damage + Mass=0.01 + StackLimit=4000

**Damage values (vs vanilla):**
- 105mm HE: 0.9 -> 5.0 | 105mm AP: 1.1 -> 6.0 | 105mm AA: 0.9 -> 48.0
- 37mm HE: 0.6 -> 3.0 | 37mm AP: 0.8 -> 4.0 | 37mm AA: 0.6 -> 36.0

**Scope:** Entities.xlsx / Equipment

### Script-Synchronisation (update-mod.ps1)

update-mod.ps1 war nicht synchron zur XLSX (XLSX ist führend). Korrigiert:
- $smallHe: Damage 32.0 -> 8.0 (+ DamageRadius, CrewDamage, etc. an 20mm-XLSX angeglichen)
- $smallAp: Damage 40.0 -> 11.2 (+ weitere Parameter angeglichen)
- DamageDifficulty-Logik: Condition korrigiert (prüfte auf Vanilla-Wert 0.35, nie auf Mod-Wert)
- Zielwert Easy: 0.1 -> 0.03 in Script und Insert-Block

**Scope:** Source/update-mod.ps1

---

## 1.7.13 - 2026-07-02 (EASY DAMAGE TUNING)

### Incoming Damage Reduced on Easy

Compared against vanilla values, the current hull damage tuning is already much softer overall, so this pass adds the missing /DamageDifficulty override and lowers the Easy difficulty multiplier further.

**Changed:**
- Added /DamageDifficulty override to the mod (was missing before)
- DamageDifficulty Multiplier (Easy): 0.35 -> 0.1

**Reference values:**
- DamageDifficulty Multiplier (Medium): 0.6
- DamageDifficulty Multiplier (Hard): 1.0
- Hull Damage Absorption: 0.2 -> 0.5
- Hull Damage Scale: 0.43 -> 0.01
- Hull Damage Scale (Without Damage Control): 0.86 -> 0.1

**Scope:**
- General.xlsx / Settings /DamageDifficulty

## 1.7.11 - 2026-06-28 (DEVELOPER CONSOLE ENABLED)

### System Toggle Update

- Enable Developer Console: False -> True
- Added section in mod override: /System -> Value
- Scope: General.xlsx / Settings

## 1.7.10 - 2026-06-19 (TORPEDO MAGNETIC FUZE SAFETY TUNING)

### Magnetic Self-Detonation Mitigation

Addressed self-detonation issue affecting all torpedo variants. Root cause analysis identified that **only magnetic-fuze torpedoes show self-detonation behavior**, suggesting the game engine does not properly handle strict zero (0.0) values for magnetic detonation parameters.

**Root Cause Hypothesis:**
The Arcade Mod previously set all three magnetic detonation parameters to 0.0 to completely disable magnetic fuzing. However, evidence indicates the UBOAT engine may interpret hard zero as an unset/invalid value, causing unpredictable magnetic trigger behavior and self-detonations, particularly near the U-Boat after launch.

**Applied Fix:**
Set all magnetic fuze trigger/fail probabilities to a minimal non-zero baseline (0.0001) on every torpedo variant. This maintains effectively negligible magnetic behavior while providing the engine a valid configuration value.

**Updated on all 26 torpedo variants:**
- MagneticExplosionAfterArm: 0.0 -> 0.0001
- MagneticExplosionFail: 0.0 -> 0.0001
- MagneticExplosionOnArm: 0.0 -> 0.0001

**Result:** Magnetic-fuze torpedoes should now behave stably without unexpected self-detonations.

## 1.7.9 - 2026-06-17 (TORPEDO MAINTENANCE COOLDOWN FIX + HULL DAMAGE TUNING)

### Fixed Torpedo Maintenance Cooldown

Corrected the MaintenanceCooldown parameter that had ballooned to an unrealistic 99.9 million seconds (~1157 days).

**Corrected all 26 torpedo variants:**
- MaintenanceCooldown: 99992100 sec → 15552000 sec (180 days)
- MinPistolActivationAngle: standardized at 10 (impact fuze arms only after a minimum hit angle)

**Known issue:** Even at 10° MinPistolActivationAngle, occasional torpedo self-detonations directly after launch can still occur near the U-Boat. Root cause is currently unknown and under investigation.

This parameter controls the maintenance interval for torpedo systems (electronics, fuel charge) between engagements, not reload time. 180 days represents a reasonable arcade-adjusted maintenance cycle.

**Affected torpedo types:** All G7a, G7e, G7es variants (normal and Warmed versions)

### Reduced Incoming Hull Damage (Player Survivability)

Tuned hull damage parameters so the U-Boot can actually survive more than a sneezing escort vessel (Easy difficulty multiplier is 0.35, but the 20mm AA munition buff was still punching through).

**Background:** The massive AA munition damage buffs in this mod (e.g. 20mm HE: 0.017 → 8) are necessary to make the player's AA guns effective against aircraft. However, enemy ships also carry and fire these same buffed AA weapons against the U-Boot — so hull survivability needed a compensating adjustment.

**Changed:**
- Hull Damage Absorption: 0.2 → 0.5
- Hull Damage Scale: 0.43 → 0.01
- Hull Damage Scale (Without Damage Control): 0.86 → 0.1

### Generator Script Update

Updated `update-mod.ps1` to include:
- Torpedo maintenance cooldown settings
- Hull damage tuning parameters

---

## 1.7.8 - 2026-06-17 (TANK SIZE FIX + SAVEGAME MIGRATION NOTES)

### Fixed Overgrown Type II Tank Capacities

Corrected the Type II tank values that had regressed to extreme capacities.

**Updated tank limits (ItemsMassLimit):**
- Fuel Tank IIA: 11000000 -> 27500
- Fuel Tank IID: 49800000 -> 78000

**Kept as intended (2x original):**
- Fuel Tank: 100000
- Saddle Fuel Tank: 99600

### Generator Script Alignment

Aligned `update-mod.ps1` so all tank-writing blocks now use the same 2x-original targets and no longer reintroduce extreme values.

### Savegame Migration Notes

- UBOAT `.save` files are binary, not plain text.
- No runtime script/hook exists in this mod to rewrite existing save inventory/tank state.
- Existing saves can retain overfilled fuel amounts until consumed/refilled.
- Recommended migration path:
  - Start a fresh test save for immediate clean tank behavior.
  - For existing saves, drain/spend fuel below new caps and then refuel to normalize.

## 1.7.7 - 2026-06-16 (TYPE VII AA RELOAD HOTFIX)

### MG C30 ReloadTime Buffed to Arcade Speed

Adjusted the Type VII AA gun so it is no longer left on vanilla reload speed.

**Updated:**
- MG C30: ReloadTime 4.1 -> 0.1

This aligns MG C30 with the existing arcade reload behavior used by other submarine AA/deck guns.

## 1.7.6 - 2026-06-16 (TYPE II AA ARCADE HAMMER)

### Increased 20mm Oerlikon to Arcade-Hammer Preset

Requested maximum stronger Type II AA against ships.

**Updated:**
- Ammo Small Calibre HE - 20 mm -> Damage = 8.0
- Ammo Small Calibre AP - 20 mm -> Damage = 11.2

**Verified combat stats (unchanged from original):**
- HE 20 mm: ArmorPiercing = 0.0, FireChance = 1.0
- AP 20 mm: ArmorPiercing = 0.5, FireChance = 0.25

## 1.7.5 - 2026-06-16 (TYPE II AA STRONG)

### Increased 20mm Oerlikon to Strong Preset

Requested stronger Type II AA against ships.

**Updated:**
- Ammo Small Calibre HE - 20 mm -> Damage = 4.0
- Ammo Small Calibre AP - 20 mm -> Damage = 5.6

This keeps the NPC-only ammo cleanup intact while making Type II AA much more punchy.

## 1.7.4 - 2026-06-16 (TYPE II AA HOTFIX)

### Restored Effective 20mm Type II AA Damage

After cleanup in 1.7.3, Type II AA (Oerlikon) damage was too low against ships.

**Re-added and rebalanced:**
- Ammo Small Calibre HE - 20 mm -> Damage = 1.0
- Ammo Small Calibre AP - 20 mm -> Damage = 1.4

These are the only calibre-specific ammo entries reintroduced. NPC-only calibre ballast remains removed.

## 1.7.3 - 2026-06-16 (CLEANUP)

### Removed All NPC-Only Ammunition (65 rows)

Deleted all ammunition entries without P2 classification (NPC-fleet-only) for a clean mod:

**REMOVED:**
- Ammo Large Calibre AA/AP/HE/SS - 37/76/88/100/102/105/114/120/130/133/152/180/203/406 mm
- Ammo Small Calibre AP/HE/Blank - 7.7/12.7/20/37/40/45/26 mm
- Ammo Large Calibre Blank entries

**FINAL MOD CONTAINS ONLY:**
- ✅ 12 Generic Player Ammunition (Cargo, all calibres)
- ✅ 32 Torpedos (G7a, G7e, G7es variants with 7x damage buff)
- ✅ Other Player Equipment (Engines, Tanks, Guns, etc.)

**Ballast removed:** 65 rows of pure NPC-fleet-only ammunition.

## 1.7.2 - 2026-06-15 (FINAL CLEANUP)

### Removed All NPC-Only Calibre-Specific Ammo

Discovered that specific calibre ammo (e.g., `Ammo Small Calibre HE - 37 mm`) are NPC-only fleet weapons, NOT Player equipment.

**REMOVED:**
- Ammo Small Calibre HE/AP - 37 mm (NPC destroyer/escort guns)
- Ammo Small Calibre HE/AP - 40 mm (NPC fleet guns)
- Ammo Small Calibre HE/AP - 45 mm (NPC fleet guns)
- Ammo Large Calibre AA - 37 mm (NPC AA)
- Ammo Large Calibre AA - 105 mm (NPC AA)

**RETAINED (Player Equipment Only):**
- Ammo Small Calibre HE/AP - 20 mm (Oerlikon gun, Arcade: 0.017→32, 0.024→40)
- Ammo Large Calibre HE/AP/SS - 37/88/105 mm (Deck Guns, Arcade values 3-6x)
- All Torpedos (7.0→50 Damage)

**Result:** Only Player-usable weapons remain buffed. NPC ships should no longer have extreme firepower.

## 1.7.1 - 2026-06-15 (HOTFIX)

### Critical: Restored Player AA Ammunition

**RESTORED:** Ammo Small Calibre HE/AP - 20 mm (Type II AA gun ammunition)
- These were incorrectly removed in v1.7 despite being PLAYER equipment
- 20mm Small Calibre munition is essential for U-boat AA defense (Oerlikon gun)
- Original values from game are now in Mod: Damage 0.017/0.024 buffed to 32/40 (Arcade)
- Sincere apologies for v1.7 breaking player AA capability!

## 1.7 - 2026-06-15 (BROKEN - DO NOT USE)

### NPC-Only 20mm Ammo Cleanup (FINAL) — RETRACTED

Removed remaining NPC-only small-calibre ammunition with massive damage multipliers:
- Ammo Small Calibre HE - 20 mm (1882x Damage multiplier!)
- Ammo Small Calibre AP - 20 mm (1667x Damage multiplier!)

These were the last surviving AA munitions from ship fleet. Player-usable 20mm Oerlikon gun remains available.

**Status:** All dangerous NPC-only ammunition now removed. Only verified Player equipment (Torpedos, Deck Guns, Engines, etc.) remain with Arcade buffs. NPC ships should no longer one-shot U-boats.

## 1.6 - 2026-06-15

### Additional NPC-Only Ammo Rollback

Removed additional clearly NPC-only ammo overrides that were causing excessive damage:
- Ammo Large Calibre AA - 37 mm (ship AA gun, large calibre)
- Ammo Large Calibre AA - 105 mm (ship AA gun, large calibre)
- Ammo Small Calibre HE - 37 mm (NPC destroyer/escort gun only)
- Ammo Small Calibre AP - 37 mm (NPC destroyer/escort gun only)

These entries now fall back to original game values. Player-usable 20mm (Oerlikon) ammo remains at arcade values.

## 1.5 - 2026-06-15

### Enemy-Only Ammo Rollback

Removed clearly NPC-only small-calibre ammo overrides from Entities/Equipment so these entries fall back to original game values:
- Ammo Small Calibre HE - 7.7 mm
- Ammo Small Calibre AP - 7.7 mm
- Ammo Small Calibre HE - 12.7 mm
- Ammo Small Calibre AP - 12.7 mm
- Ammo Small Calibre HE - 40 mm
- Ammo Small Calibre AP - 40 mm
- Ammo Small Calibre HE - 45 mm
- Ammo Small Calibre AP - 45 mm

### 37 mm Check

37 mm small-calibre ammo was not rolled back in this change because 37 mm guns are tagged for Type IX deck gun upgrades in current data definitions and are therefore not clearly NPC-only.

## 1.4 - 2026-06-15

### Fuel Tank Capacity Fix

Adjusted U-boat fuel tank capacities to 2x original game values to avoid near-infinite storage introduced by previous arcade tuning:
- Fuel Tank: 50000 -> 100000
- Saddle Fuel Tank: 49800 -> 99600
- Fuel Tank IIA: 11000000 -> 27500
- Fuel Tank IID: 49800000 -> 78000

This keeps tanks generous for arcade gameplay while restoring sane capacity limits for campaign balance.

**Known Issue:** Type IX U-boat tank capacities may not be fully addressed if Type IX has separate fuel tank IDs (requires Distant Coasts DLC). Only standard Fuel Tank / Saddle Fuel Tank IDs were adjusted in this update.

## 1.3 - 2026-06-15

### Deck Gun Rebalancing

Buffed 8.8 cm deck gun ammunition to increase effectiveness in arcade combat:
- HE rounds: Damage 0.7 → 4.0 (with FireChance 1.0 for guaranteed fire effects)
- AP rounds: Damage 0.85 → 5.0 (increased armor penetration threat)

Buffed small-calibre ship combat weapon ammo (7.7mm, 12.7mm) to match 20mm AA levels:
- 7.7 mm HE: Damage 0.06 → 32.0
- 7.7 mm AP: Damage 0.09 → 40.0
- 12.7 mm HE: Damage 0.1 → 32.0
- 12.7 mm AP: Damage 0.13 → 40.0

### Known Issue: AA Weapon Balance

Small-calibre AA guns (7.7mm, 12.7mm, 20mm and above) now significantly outperform deck guns in direct ship combat due to cumulative effects of buffed damage values, proximity detonation mechanics, and fire effects. Being evaluated for future rebalancing. For now, expect all small-calibre AA weapons to be highly effective against surface targets.

## 1.2 - 2026-06-14

### What's new
- Updated to support UBOAT 2026.1 including the Type IX Distant Coasts DLC
- New artillery covered: 10.5 cm, 37 mm SK C30 — instant reload, arcade damage
- New ammo covered: 105 mm and 37 mm — massively boosted damage
- New engines: Diesel/Electric Engines IIA — zero fuel, zero noise, extra speed
- New equipment: Fuel Tank IIA/IID, Trim Pump Type II, Attack/Observation Periscope IIA
- Submarine pen build tasks reduced to 1 day (La Rochelle, Helgoland, Bergen, Brest)
- Flak AA ammo anti-ship damage doubled across 105 mm and 37 mm calibres
- Removed obsolete 'French Speaker' entry (no longer in game)
- Added automated Steam Workshop upload pipeline

## 1.1 - 2026-06-12

### Gameplay/Balancing overview (mod vs original data sheets)
- Scope of overrides (row-level): Entities/Equipment 195 rows, General/Settings 34 rows, Sandbox/Tasks 49 rows, Sandbox/Settings 14 rows, CharacterClasses (Radioman/Leader/Engineer) 18 rows.
- Deck gun handling and throughput increased: 10.5 cm artillery reload reduced from 7.0s to 0.1s, magazine size increased from 1 to 4, recoil terms effectively neutralized.
- Ammunition logistics heavily relaxed: 88 mm ammo mass reduced from 1.0 to 0.01 and stack size increased from 40 to 4000.
- Small-calibre ammo logistics similarly relaxed: e.g. 40 mm HE mass reduced from 0.12 to 0.01 and stack size increased from 40 to 4000.
- Ammunition storage capacity expanded: Flak Ammunition Storage ItemsMassLimit increased from 750 to 9,999,999.
- Gun ammunition damage model boosted across new calibres: examples include 105 mm HE damage 0.9 -> 5.0, 105 mm AP 1.1 -> 6.0, 105 mm AA 0.9 -> 24.0, 37 mm HE 0.6 -> 3.0, 37 mm AA 0.6 -> 18.0.
- Propulsion and signature tuning shifted to arcade profile: Diesel Engines changed from /Velocity +1, Noise 0.7, FuelUsage 1.0 to /Velocity +10, Noise 0.0, FuelUsage 0.0; Electric Engines changed from /Velocity +1, Noise 0.52 to /Velocity +10, Noise 0.0 with FuelUsage -10.0.
- Ballast/trim control massively accelerated: Trim Pump and Trim Pump Type II increased from 0.06 L/s to 9990.06 L/s; noise and energy usage reduced to 0.0.
- Global resource and operation timings shortened in General/Settings: torpedo loading phases reduced to 1s, battery recharge rate raised from 1.0 to 100.0, compressed air torpedo launch usage reduced from 18.0 to 0.0, transfer factor reduced from 120 to 0.25 s/kg, upgrade factor reduced from 20 to 0.25 s/budget unit.
- Campaign task pacing compressed: research/upgrade/intel tasks and selected construction tasks were reduced to 1 day (examples: multiple torpedo and sensor research tasks 5-12d -> 1d; officer training 16d -> 1d; submarine pen builds 30d -> 1d).
- Crew survivability and penalty systems reduced: treatment rate increased from 0.01 to 0.60, evacuation drown/capture chance reduced to 0.0, incubation time reduced to 0.10 min, hunger discipline-loss scale reduced from 1.0 to 0.1.

- Updated supported game versions to 2026.1 only.
- Removed obsolete 2022.1 patch 22 compatibility entry.
- Reconnected the existing Steam Workshop item ID 2806112328.
- Updated Steam description text to a stable ASCII-safe format.
- Added automated Steam upload scripts:
  - steam-upload.ps1
  - publish-workshop.ps1
- Added workflow support for automatic changenotes from this changelog.
- Added workflow support for automatic Manifest version bump on publish.
