# UBOAT Arcade Mod - Working TODO

Status legend: [ ] open, [x] done

## Priority Tasks

- [x] FLAK43U buffen
  - 43U in Entities.xlsx / Equipment / P16 angepasst: ReloadTime 4.5 -> 0.1, Range 3000 -> 5000
  - update-mod.ps1 synchronisiert: Set-EquipP16 fuer 43U hinzugefuegt
  - Changelog + Manifest-Version aktualisiert (1.7.22)

- [x] Damage ueberpruefen (Parameter-Semantik vs. aktuelle Mod-Kalkulation)
  - Referenz: https://steamcommunity.com/app/494840/discussions/0/1747895838223189009/
  - Aussage laut Referenz pruefen:
    - Hull Damage Absorption: Anteil, der am NPC-Rumpf absorbiert/negiert wird, bevor Restschaden dahinterliegende Objekte trifft
    - Hull Damage Scale: Direkter Schadensfaktor fuer NPC-Rumpf (hoeher = mehr Flutung/Schaden)
    - Hull Damage Scale (Without Damage Control): Wie oben, aber nach Verlassen des Schiffs durch die Crew
    - Hull Flooding Scale: Faktor fuer Flutungsgeschwindigkeit in NPC-Kompartments
    - Player Ship Damage Scale: Relativer Schadensfaktor Player-Schiff vs. NPC-Schiffe (wegen unterschiedlicher Schadensmodelle)
  - Befund bestaetigt: kleinerer Wert bei Player Ship Damage Scale reduziert eingehenden Schaden am Player-Schiff
  - Schadenslogik fuer aktuelle Mod-Kalkulation verifiziert

- [x] Torpedos explodieren im/nahe U-Boot untersuchen
  - MinPistolActivationAngle bereits auf 10 Grad korrigiert (besserer Zündungswinkel)
  - MaintenanceCooldown: 99992100 sec → 15552000 sec (180 Tage) — Wartungsintervall-Regression behoben
  - DamageRadius: beabsichtigt auf 40 Meter (6x Original für Arcade-Effektivität)
  - Kandidaten für Restprobleme: Engine-Torpedozerstörung oder andere seltene Auslöser

- [x] Torpedo-Geschwindigkeitsauswahl verifizieren
  - T1 Pi1 und T2 Pi1 gegen Vanilla verglichen (P16): Speed-Stufen vorhanden, aber Ranges im Mod auf 40000 vereinheitlicht
  - Speed-Werte sind sehr wahrscheinlich in kn (nicht km/h); 81 km/h entsprechen ca. 43.7 kn (naehe Speed2)
  - Plausibler Befund: Spiel nutzt aktuell faktisch Standard/Speed2; aktuell als Low-Priority/First-World-Problem eingeordnet

- [x] Crew-Groesse pro Spielerboot verifizieren und modbar machen
  - Aktueller Befund: Type-Werte fallen derzeit auf Vanilla zurueck (kein direkter Type-Override im Mod)
  - Vanilla geprueft: Type VIIC Crew=52, Type VIIC (Player) Crew=20
  - Hinweis: pro Boot theoretisch modbar ueber Type-Override in Entities.xlsx / Types (jeweilige *(Player)-Zeile und Crew-Wert)

- [x] Typ VIIC (nicht VIIC/41) auf Modding-Stand pruefen (inkl. weiterer Bootstypen)
  - Type VIIC/VIIC41 aktuell nicht direkt in Mod-Types ueberschrieben (0 Treffer), daher fuer Type-Daten Vanilla-Fallback
  - Vanilla Types geprueft: Type VIIC Crew=52, Type VIIC (Player) Crew=20
  - Vanilla Slots geprueft: Type VIIC (Player) Conning Tower=Turm 0, Type VIIC41 (Player)=Turm IV
  - Vollvergleich dokumentiert in Source/type-viic-vs-vanilla-2026-07-18.md

- [x] Marineakademie-Forschung im Original finden und fehlende Forschungen im Mod identifizieren
  - Verifiziert: `Send Officer To Naval Academy` ist im Mod vorhanden und auf Duration=1 (Vanilla=16)
  - Sonstige Research-Tasks im Mod: keine verbleibenden Duration > 1 gefunden
  - Auffaellig lang bleiben nur `Milk Cow I` bis `Milk Cow X` mit Duration=12 (wie Vanilla, keine Research-Tasks)

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

- [x] General Damage Widerstand tunen
  - General/Settings /Damages Werte fuer Player-Schadensaufnahme wurden angepasst/getuned
  - /DamageDifficulty wurde im Verlauf ebenfalls angepasst

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
