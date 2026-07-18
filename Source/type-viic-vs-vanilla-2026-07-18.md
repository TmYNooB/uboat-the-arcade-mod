# Type VIIC Full Compare vs Vanilla - 2026-07-18

## Scope
- Focus: Type VIIC and Type VIIC41 (NPC + Player variants)
- Files checked:
  - Data Sheets/Entities.xlsx
  - Data Sheets/Sandbox.xlsx

## Workbook Coverage
- Vanilla Entities sheets: Types, Slots, Units, Equipment
- Mod Entities sheets: Types, Equipment
- Result: Mod has no Slots/Units override; these parts are fully vanilla-driven.

## Entities / Types (Vanilla Baseline)

### Type VIIC
- Category: Submarine
- Speed (km/h): 32.8
- Standard: 769
- Full: 871
- Length (m): 67.1
- Beam (m): 6.2
- Draught (m): 4.74
- Mast height (m): 5.5
- Range (km): 15700
- Crew: 52
- Threat: 10
- Military: True
- Is Class: True
- Reward: 7500
- Iron Cross: 0
- Estimated Durability (AI): 2

### Type VIIC (Player)
- Same base hull stats as Type VIIC
- Crew: 20
- Parameters: includes CrushDepth = -250

### Type VIIC41
- Same base hull stats as Type VIIC
- Crew: 52

### Type VIIC41 (Player)
- Same base hull stats as Type VIIC41
- Crew: 20
- Parameters: includes CrushDepth = -300

## Entities / Types (Mod Override Status)
- Rows containing Type VIIC/Type VIIC41 in mod Types: 0
- Conclusion: no direct Type-row override for VIIC or VIIC41 in current mod.

## Entities / Slots (Vanilla, because no mod Slots sheet)
- /Type VIIC (Player): Conning Tower default = Turm 0
- /Type VIIC41 (Player): Conning Tower default = Turm IV

## Entities / Units (Vanilla, because no mod Units sheet)
- Type VIIC unit rows: 595
- Type VIIC41 unit rows: 158

## Sandbox / Tasks (VIIC References)
- Vanilla VIIC-related rows: 2
  - Build VIIC U-boats Part 2 -> Entity=Type VIIC;Initial=20;Production=0;Unlimited=1
  - Build VIIC U-boats Part 3 -> Entity=Type VIIC;Initial=140;Production=0
- Mod VIIC-related rows: 0

## Overall Conclusion
- Type VIIC currently is not directly modded as a type dataset row.
- For type identity, slots, and unit-class mapping, Type VIIC and Type VIIC41 follow vanilla data.
- Mod still affects both boats indirectly through shared equipment overrides in Equipment.


