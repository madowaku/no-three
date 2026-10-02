# NO THREE v0.1 verification

2026-10-02 / Windows / Godot 4.7.stable.official.5b4e0cb0f

## Automated results

- All 001–016: `solutions=1`, using the unmodified specified initial dots.
- All 017–020: `moves=1`, matching the four specified source/destination pairs.
- Independent Python geometry, placement, canonical-line, and stage tests: PASS.
- Godot integer geometry, arbitrary angles, duplicate-line removal, rejected placements, bounds, and snapshot history: PASS.
- Actual scene/controller path through every stage: PASS (199 assertions); trace, reset, rejected moves, clear, post-clear undo, replay, local save, unlock, and completion marks verified.
- Rendered mouse interactions: title → stage select → stage 001 → reject → clear → NEXT → stage 002 → Undo → Reset → stage select, at both 720×1280 and 360×800: PASS.
- Simulated `InputEventScreenTouch` events at 360×800: PLACE and MOVE ONE select/move/clear PASS. Physical touch hardware has not been tested.
- Layout reports for title, stage select, clear, unlocked stage select, and 3×3/4×4/5×5/6×6 boards at both sizes: zero overlap, zero zero-sized controls, zero offscreen controls. PNGs inspected visually.
- Project scene/resource loading and startup with debugger attached: no project errors or warnings.

`tools/run_checks.ps1` reproduces the core verification. `-Visual` adds rendering, touch simulation, screenshots, and the skill's UI-report scenarios. Output is kept in ignored `evidence/`.

## Missing MOVE ONE input data

The supplied sprint specified moves but omitted the initial configurations. The development solver generated legal full boards, replaced each required destination with its required source, and accepted only boards with exactly that one legal correction. The resulting initial boards live in `data/stages.json`; expected moves were saved in fixtures before gameplay implementation. No solver or answer data is referenced by runtime game scripts.

## Human Playtest Gate — pending

A new player still needs to play 001–012 without extra explanation. Observe discovery of the rule, reasons for rejection, row patterns, non-45° lines around 009, TRACE use, Undo/Reset frequency, abandonment, and desire to play another stage. Record whether the board looks different to them around 009. Automated testing does not establish this perceptual result.

## Scope

Delivered as a Godot project. Desktop/Web export, Daily, LAB, achievements, leaderboards, score, hints, and boards larger than 6×6 are outside this sprint implementation. Generated test evidence is not part of distribution assets.
