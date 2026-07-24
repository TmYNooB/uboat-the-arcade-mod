# Savegame Analysis - Remaining Measures

## Goal
Determine whether Data Sheet content is persisted in save data as transformed runtime state (instead of embedded XLSX files), and document a reproducible reader strategy.

## Current status
- Phase 1: SaveData segment and Sandbox/Task/Settings markers verified.
- Phase 2: No embedded ZIP/OLE containers found in block3; exhaustive zlib probe found no inflated OOXML candidates.

## Remaining tasks
- [ ] Build Phase 3 parser for SaveData internals:
  - Parse type table / object table boundaries from block3.
  - Recover object graph references (IDs, parent/child, arrays/lists).
  - Emit a normalized JSON graph (`objects`, `types`, `fields`, `edges`).
- [ ] Extract key-value style gameplay settings from reconstructed graph:
  - Find known fields: `Sandbox Time Scale`, `DamageReduction`, `VacationPriceModifier`, `OnBoardLimit`.
  - Export to `runtime-settings-extract.json` with object path + value + source offset.
- [ ] Correlate runtime values with mod XLSX rows:
  - Add comparer script that reads mod files in `Data Sheets/*.xlsx` (ImportExcel) and checks if equivalent values are present in save graph.
  - Output matrix: `xlsx_key`, `xlsx_value`, `save_present`, `save_value`, `match_type`.
- [ ] Detect "save-bound" vs "live-overridable" categories:
  - Run diff on two saves (before/after changing one XLSX parameter and loading/saving once).
  - Classify fields into:
    - save-bound (persisted and unchanged by later XLSX edits)
    - re-evaluated on load
    - unknown
- [ ] Improve stream probing for non-zlib custom chunks:
  - Add LZ4 signature and frame probing.
  - Add chunk dictionary heuristics for Unity/Mono serialization wrappers.
- [ ] Document minimal external reader contract:
  - Inputs, assumptions, and failure modes.
  - Stable commands for reproduction.

## Operational notes
- Prefer running Phase 2 in `pwsh` because zlib probing uses `System.IO.Compression.ZLibStream`.
- Keep canonical analysis artifacts under `Source/savegame-analysis/current-snapshot`.
