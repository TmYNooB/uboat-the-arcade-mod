# Savegame Analysis Workspace

This folder collects all savegame-relevant artifacts in one place to analyze which gameplay data is save-bound.

## Current snapshot

`current-snapshot/` contains:
- copied manual save (`*.save`)
- `block1-gamestate.bin` (small header/game-state block)
- `block2-screenshot.jpg`
- `block3-rest.bin` (main payload, very large)
- `save-container-metadata.json`
- `save-rest-analysis.json`
- `phase1-block3-parse.json`
- `phase1-block3-summary.md`
- `phase2-embedded-containers.json`
- `extracted-containers/` (if embedded containers are found)
- `decoded-block1-summary.json` (from offline decoder fallback)

Canonical location is `current-snapshot/`.
Legacy files in `Source/` (for example `latest-manual-savegame*.json/bin/jpg`) are older compatibility artifacts and not the primary analysis target.

## Why this matters

The save container is **not only** block1 + screenshot.
There is a third payload block (`block3-rest.bin`) with many serialized Sandbox classes and mission/task/settings markers.
This is strong evidence that parts of Sandbox/GameState become save-bound and are not always re-read live from XLSX after save creation.

## Scripts

- `extract-save-complete.ps1`
  - Fully extracts the three save payload blocks and metadata.
- `analyze-save-rest-strings.ps1`
  - Scans `block3-rest.bin` tokens and reports Sandbox/Task/Settings hit groups.
- `refresh-savegame-analysis.ps1`
  - Runs extract + rest analysis + phase1 parse + phase2 container extraction + block1 decode summary in one command.
- `phase1-parse-block3.ps1`
  - Maps block3 segments and extracts SaveData-focused top-level markers (`sceneObjects`, `scriptableObjects`, `sandbox`, `playerShip`, `stringPool`) plus Sandbox/Task/Settings evidence.
- `phase2-extract-embedded-containers.ps1`
  - Scans block3 for raw ZIP/OLE signatures and probes nested zlib streams for OOXML markers, then extracts candidate container blobs when detected.

## Run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Source\savegame-analysis\refresh-savegame-analysis.ps1
```

Optional with explicit save path:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Source\savegame-analysis\refresh-savegame-analysis.ps1 -SavePath "C:\Users\User\AppData\LocalLow\Deep Water Studio\UBOAT\Saves\260614 UbootTyp2.save"
```

## Next step for full decode

To reach a complete decode of `block3-rest.bin`, a custom reader is needed that reproduces UBOAT's internal serialization format (`UBOAT.Game.Serialization.SaveData`) without requiring Unity runtime callbacks.
