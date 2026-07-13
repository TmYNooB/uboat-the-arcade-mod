# UBOAT Arcade Mod - Working TODO

Status legend: [ ] open, [x] done

## Priority Tasks

- [x] Torpedos explodieren im/nahe U-Boot untersuchen
  - MinPistolActivationAngle bereits auf 10 Grad korrigiert (besserer Zündungswinkel)
  - MaintenanceCooldown: 99992100 sec → 15552000 sec (180 Tage) — Wartungsintervall-Regression behoben
  - DamageRadius: beabsichtigt auf 40 Meter (6x Original für Arcade-Effektivität)
  - Kandidaten für Restprobleme: Engine-Torpedozerstörung oder andere seltene Auslöser

- [ ] Torpedo-Geschwindigkeitsauswahl verifizieren
  - Meldung aufnehmen: Geschwindigkeit kann nicht mehr ausgewaehlt werden
  - Pruefen, ob Torpedo-P16 in `Entities.xlsx` unterschiedliche Speed-Stufen noch enthaelt
  - Original vs. Mod im Detail vergleichen (pro Torpedo-ID alle P-Felder mit Abweichung auflisten)
  - Falls notwendig, Speed/Range-Werte so anpassen, dass die Auswahl im UI wieder eindeutig verfuegbar ist

- [x] Tankwerte im Mod korrigieren
  - Fuel Tank IIA von 11000000 auf 27500 gesetzt
  - Fuel Tank IID von 49800000 auf 78000 gesetzt
  - Fuel Tank/Saddle Fuel Tank auf 2x Original bestaetigt (100000/99600)

- [x] IIA/IID Saddle Tanks (Tank-Analyse) abgeschlossen
  - Alle Player-Fuel-Tanks auf x2 Vanilla verifiziert
  - Type XIV Fuel Storage identifiziert als NPC Supply-Boot, nicht playerrelevant — beibehalten
  - Keine weiteren Player-Fuel-Tank-IDs gefunden

- [x] Torpedo MaintenanceCooldown korrigieren (180 Tage)
  - Alle 26 Torpedo-Varianten: 99992100 sec → 15552000 sec 
  - Generator-Script mit Torpedo-Sektion aktualisiert
  - Parameter ist Wartungsintervall für Torpedo-Elektronik (nicht Nachladezeit)

- [ ] General Damage Widerstand tunen
  - General/Settings /Damages Werte fuer Player-Schadensaufnahme anpassen
  - Optional /DamageDifficulty fuer Easy/Medium/Hard explizit setzen

- [x] Savegame-Migration fuer Tankwerte geklaert (technisch + Vorgehen)
  - Savegames sind binaere `.save`-Dateien, kein einfacher Textpatch im Repo-Workflow
  - Keine Mod-Hooks/Skripte vorhanden, die alte Save-Inhalte automatisch migrieren
  - Vorgehen dokumentiert: neuer Testsave fuer sofort saubere Caps; laufender Save normalisiert nach Verbrauch/Refill

- [x] Cache loeschen und ingame verifizieren
  - Sichere Cleanup-Routine erstellt (Source/cleanup-mod-cache.ps1)
  - SELEKTIV nur Arcade Mod .dat Dateien loeschen (nicht alle!)
  - Andere Mods/DLCs (free-skins-1 etc.) bleiben unberührt

- [x] Kostenloses Skin-Addon pruefen
  - SkinPaket über Launcher → News wieder aktiviert, funktioniert jetzt

- [x] Changelog, Version und Workshop veroeffentlichen
  - v1.7.13 veröffentlicht (3. Jul 10:38)
  - Changelog-Newline Bug in Upload-Script behoben
  - Steam Workshop Update erfolgreich
  - CHANGELOG.md aktualisieren
  - Manifest.json Version synchron halten
  - Steam Workshop Upload ausfuehren

## Notes

- XLSX-Schnellcheck 2026-06-17 (Data Sheets/Entities.xlsx, Sheet Equipment, alle Torpedos):
  - In P16 sind `Speed1/Speed2/Speed3` vorhanden und ungleich (55.901 / 41.9259 / 27.9506)
  - Gleichzeitig sind `Range1/Range2/Range3` auf 40000 vereinheitlicht
  - Moegliche Folge: UI/Spielverhalten zeigt keine sinnvolle Geschwindigkeitsauswahl mehr, obwohl mehrere Speed-Werte gesetzt sind

- Letzter bekannter Befund: utopische Tankwerte sind aktuell wieder aktiv:
  - Fuel Tank IIA: 11000000 (orig 13750)
  - Fuel Tank IID: 49800000 (orig 39000)

- Tankfix 2026-06-17 umgesetzt und verifiziert:
  - Fuel Tank = 100000
  - Saddle Fuel Tank = 99600
  - Fuel Tank IIA = 27500
  - Fuel Tank IID = 78000

- Savegame-Migration 2026-06-17:
  - `.save` ist binaer, daher keine direkte sichere Feld-Migration per Repo-Skript
  - Bestehende Saves koennen ueberfuellte Mengen behalten, bis Treibstoff verbraucht wird
  - Praxis: neuen Testsave fuer harte Verifikation nutzen; laufende Saves durch Verbrauch + Auftanken unter neue Caps bringen
