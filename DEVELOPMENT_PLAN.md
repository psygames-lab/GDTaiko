# GDTaiko Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `GDTaiko`, an independent Godot Taiko rhythm game inspired by OpenTaiko's feature set and `.tja` ecosystem, implemented as a native Godot project rather than a direct C# source translation.

**Architecture:** Treat OpenTaiko as a behavioral/spec reference, not as code to mechanically convert. Use a clean Godot runtime for gameplay, a focused `.tja` parser/converter layer, and optional Python tools for batch conversion and chart validation. Start with a playable vertical slice before adding advanced OpenTaiko systems.

**Tech Stack:** Godot 4.6.2 target, GDScript, Godot scenes/resources, optional Python 3 tooling, `.tja` chart files, JSON chart cache, WAV/OGG/MP3 audio assets.

**Engine Target:** Current development targets `Godot 4.6.2.stable.official`. If compatibility with an older Godot 4.x release becomes a requirement, add that version to the test matrix and verify the project opens and focused tests pass there before lowering project metadata.

---

## 1. Project Positioning

`GDTaiko` is not a PsyGodot example and should not live inside `E:\03_tools\psygodot\examples`.

Recommended location:

```text
E:\10_创作\GDTaiko
```

Project split:

```text
E:\03_tools\psygodot
  PsyGodot research/runtime project and lightweight rhythm_drum demo.

E:\03_tools\Drum2Taiko
  Offline drum-event and auto-charting toolchain.

E:\10_创作\GDTaiko
  Independent Godot Taiko game/runtime inspired by OpenTaiko behavior.
```

OpenTaiko should be used as:

- A reference for `.tja` behavior.
- A reference for Taiko gameplay systems.
- A reference for edge cases and long-term feature coverage.

OpenTaiko should not be used as:

- A file-by-file C# to GDScript conversion target.
- A source of copied skins, songs, or non-code assets unless each asset's license is verified.
- A requirement to clone every advanced feature before the game is playable.

## 2. Development Strategy

The project should be built in phases.

### Phase 0: Project Bootstrap

Outcome: The repository is initialized, the Godot project opens, the test command pattern is proven, and asset tracking exists before any gameplay or asset work starts.

Required:

- Initialize git if `.git` is missing.
- Add `.gitignore` before Godot import/cache files are generated.
- Create `project.godot` with metadata aligned to the selected Godot target.
- Create `README.md` with run and test commands.
- Create `docs/ASSET_AUDIT.md` before adding placeholder art, SFX, fonts, or sample audio.
- Choose the initial test style: lightweight headless script tests that exit non-zero on failure.
- Verify Godot version through Godot MCP or `godot --version`.
- Verify the empty project opens through Godot MCP or `godot --path`.

Not included:

- Gameplay implementation.
- OpenTaiko asset import.
- Song library scanning.

### Phase 1: Playable Core

Outcome: Open a Godot project, load one song/chart, play Don/Ka notes, judge hits, show score/combo, and finish the song.

Supported:

- One gameplay scene.
- One sample song folder.
- `.tja` parser subset.
- BPM, OFFSET, COURSE, LEVEL, WAVE, basic `#START` / `#END`.
- Don/Ka notes.
- Basic timing windows.
- Score, combo, miss state.
- Chart offset setting.

Not supported yet:

- Roll notes.
- Balloon notes.
- GOGO time.
- Branch charts.
- Dan mode.
- Skin system.
- Song select carousel.
- OpenTaiko database compatibility.

### Phase 2: Taiko Rule Coverage

Outcome: The gameplay engine supports common Taiko chart semantics.

Add:

- Roll notes.
- Balloon notes.
- GOGO time.
- BPM changes.
- SCROLL changes.
- MEASURE changes.
- Score gauge.
- Clear/fail result.
- Per-song audio/chart offset.

### Phase 3: Song Library

Outcome: The game can scan a songs folder and provide a usable song select screen.

Add:

- `songs/` folder scanner.
- Song metadata extraction.
- Difficulty list.
- Audio preview.
- Folder/category UI.
- Sort and search.
- Persistent local scores.

### Phase 4: OpenTaiko Compatibility Pass

Outcome: More `.tja` files work without manual conversion.

Add:

- Common OpenTaiko/TJAPlayer command compatibility.
- Branching.
- Advanced note variants if needed.
- Better parser diagnostics.
- `.tja` fixture suite.
- Compatibility evidence records that tie each supported behavior to an OpenTaiko reference commit/tag and original fixture.

### Phase 5: Presentation and Skinning

Outcome: The game has a clean visual identity and controlled theming.

Add:

- Configurable note textures.
- Lane/target skins.
- Hit effects.
- Dancer/background hooks.
- Theme resource format.
- Optional Lua-like scripted background layer only if a clear need remains.

## 2A. Multi-Agent Development Mode

GDTaiko should be developed with a multi-agent workflow. The default execution style is task-by-task, with lightweight implementation agents doing focused code work and a stronger review/planning agent handling architecture, compatibility, and quality gates.

### Model Routing

Use this routing when the platform supports explicit model selection:

| Work Type | Preferred Model | Responsibilities |
| --- | --- | --- |
| Architecture, system design, phase planning | `5.5 high` | Decide boundaries, review OpenTaiko behavior, resolve compatibility tradeoffs, prevent over-engineering. |
| Critical code review | `5.5 high` | Review parser correctness, timing math, score/gauge rules, asset-license decisions, release gates. |
| Complex feature implementation | `5.5 high` first pass or pair-review | Branching, replay determinism, timing map, skin/theme architecture, song library indexing. |
| Routine implementation | `5.3-codex-spark` | Add focused GDScript files, fixtures, tests, UI glue, small refactors, docs updates. |
| Test fixture expansion | `5.3-codex-spark` | Add `.tja` fixtures, expected JSON sidecars, regression cases from known bugs. |
| Mechanical cleanup | `5.3-codex-spark` | Rename, format, update docs, simple asset manifest edits. |

If a requested model is unavailable, use the nearest available model but keep the same role separation: strong model for design/review, fast coding model for routine implementation.

### Required Agent Roles

Every non-trivial phase should use these roles:

- **Lead Architect (`5.5 high`)**: owns scope, data model, compatibility interpretation, and task sequencing.
- **Implementation Agent (`5.3-codex-spark`)**: implements one small task at a time from the plan, with tests.
- **Review Agent (`5.5 high`)**: reviews the implementation against requirements, tests, edge cases, and OpenTaiko compatibility.
- **Asset Auditor (`5.5 high`)**: reviews skin/font/SFX license evidence before assets enter repo or release.

Small tasks can be implemented by one `5.3-codex-spark` agent, but anything touching parser semantics, timing, scoring, branching, storage, assets, or release requires `5.5 high` review before merge.

### Per-Task Workflow

For each task:

1. **Architect checkpoint (`5.5 high`)**
   - Confirm the task scope.
   - Identify files and behavior under test.
   - Call out OpenTaiko compatibility implications.
   - For compatibility-sensitive work, name the OpenTaiko commit/tag and fixture evidence required.

2. **Implementation pass (`5.3-codex-spark`)**
   - Write failing tests first.
   - Implement minimal code.
   - Run focused tests.
   - Report changed files and command output.

3. **Review pass (`5.5 high`)**
   - Read the diff.
   - Check correctness, edge cases, and missing tests.
   - Require fixes before the task is accepted.

4. **Integration checkpoint**
   - Run the task's verification commands.
   - Commit only the task's scoped files.
   - Update the task checkbox.

### Review Gates That Require `5.5 high`

Use `5.5 high` before accepting changes in these areas:

- `.tja` parser semantics and compatibility fixtures.
- Timing map, BPM/SCROLL/MEASURE behavior, and audio sync.
- Judgment windows, scoring, soul gauge, branch rules, roll/balloon behavior.
- Song folder scanning and persistent score/replay formats.
- Theme/skin architecture and asset pipeline.
- Asset license audit and release inclusion decisions.
- Export/release configuration.
- Any change that touches more than three subsystems.

### Handoff Template

Use this template when dispatching an implementation agent:

```markdown
Task: <task number and name>
Model: 5.3-codex-spark
Scope: <one bounded change>
Files: <exact files>
Tests first: <exact test command and expected failure>
Implementation constraints:
- Keep changes surgical.
- Do not alter unrelated files.
- Preserve Godot-native architecture.
- Do not import third-party assets.
Verification:
- <commands to run>
Return:
- Changed files
- Test output
- Notes/blockers
```

Use this template when dispatching a review agent:

```markdown
Review: <task number and name>
Model: 5.5 high
Inputs:
- Plan section
- Diff
- Test output
Review focus:
- Correctness
- Missing tests
- OpenTaiko compatibility
- Godot architecture fit
- Asset/license risk if relevant
Return:
- Blocking issues
- Non-blocking issues
- Required fixes
- Accept/reject decision
```

## 3. Initial File Structure

Create this structure during Phase 0 and Phase 1:

```text
E:\10_创作\GDTaiko
  AGENTS.md
  .gitignore
  README.md
  DEVELOPMENT_PLAN.md
  project.godot
  docs/
    ASSET_AUDIT.md
    COMPATIBILITY_EVIDENCE.md
  scenes/
    Main.tscn
    Gameplay.tscn
  scripts/
    app/
      main.gd
    chart/
      taiko_chart.gd
      tja_parser.gd
      tja_tokenizer.gd
    gameplay/
      gameplay_controller.gd
      song_clock.gd
      note_model.gd
      note_lane.gd
      judge.gd
      scoring.gd
    ui/
      hud.gd
  assets/
    notes/
      note_don.png
      note_ka.png
    sfx/
      don.wav
      ka.wav
    sample/
      sample.tja
      sample.ogg
  tests/
    chart/
      test_tja_parser.gd
    gameplay/
      test_judge.gd
      test_scoring.gd
```

Responsibilities:

- `scripts/chart/tja_tokenizer.gd`: Normalize text, strip comments, split commands and note lines.
- `scripts/chart/tja_parser.gd`: Convert `.tja` text into `TaikoChart`.
- `scripts/chart/taiko_chart.gd`: Data model for metadata, timing events, and notes.
- `scripts/gameplay/song_clock.gd`: Single source of truth for song time and offsets.
- `scripts/gameplay/judge.gd`: Timing judgment rules.
- `scripts/gameplay/scoring.gd`: Score/combo state.
- `scripts/gameplay/note_lane.gd`: Note spawning, motion, and cleanup.
- `scripts/gameplay/gameplay_controller.gd`: Orchestrates chart, audio, input, scoring, and HUD.
- `scripts/ui/hud.gd`: Score/combo/judgment labels.

## 4. Phase 1 Data Model

Use typed dictionaries or small RefCounted classes. Keep it simple until performance or editor tooling requires custom Resources.

`TaikoChart` fields:

```gdscript
extends RefCounted
class_name TaikoChart

var title: String = ""
var subtitle: String = ""
var wave: String = ""
var bpm: float = 120.0
var offset_sec: float = 0.0
var course: String = "Oni"
var level: int = 1
var notes: Array[Dictionary] = []
var timing_events: Array[Dictionary] = []
```

Note dictionary shape:

```gdscript
{
  "id": "note_0001",
  "time_sec": 1.234,
  "lane": "don",
  "kind": "don",
  "measure_index": 0,
  "subdivision_index": 0,
  "state": "pending"
}
```

Timing event dictionary shape:

```gdscript
{
  "time_sec": 0.0,
  "type": "bpm",
  "value": 150.0
}
```

Phase 1 can parse BPM but does not need runtime BPM changes. Add the event model now so Phase 2 has a clear insertion point.

## 5. TJA Phase 1 Subset

Support these metadata fields:

```text
TITLE:
SUBTITLE:
BPM:
OFFSET:
WAVE:
COURSE:
LEVEL:
```

Support these commands:

```text
#START
#END
#BPMCHANGE
#MEASURE
```

Phase 1 parser behavior:

- Ignore empty lines.
- Ignore lines before `#START` except metadata.
- Stop at `#END`.
- Parse note characters inside note lines.
- Treat commas as measure boundaries.
- Ignore unsupported note characters with a warning entry.
- Convert note character `1` to `don`.
- Convert note character `2` to `ka`.
- Treat `0` as rest.
- For Phase 1, ignore `3`, `4`, `5`, `6`, `7`, `8`, `9`, `A`, `B` as unsupported note characters.

Timing rule:

- A 4/4 measure duration is `4 beats * 60 / bpm`.
- If a measure has `N` note slots before comma, each slot duration is `measure_duration / N`.
- Note time is `chart_time + offset_sec`.
- TJA `OFFSET` convention must be verified against fixtures during implementation. Phase 1 should expose a project-level `chart_offset_sec` so calibration is possible even if convention differences are found.

## 6. Implementation Tasks

### Task 0: Bootstrap Repository, Engine Target, And Test Harness

**Files:**

- Create: `E:\10_创作\GDTaiko\.gitignore`
- Create: `E:\10_创作\GDTaiko\project.godot`
- Create: `E:\10_创作\GDTaiko\scenes\Main.tscn`
- Create: `E:\10_创作\GDTaiko\README.md`
- Create: `E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md`
- Create: `E:\10_创作\GDTaiko\docs\COMPATIBILITY_EVIDENCE.md`
- Create: `E:\10_创作\GDTaiko\tests\test_smoke.gd`
- Modify: `E:\10_创作\GDTaiko\DEVELOPMENT_PLAN.md`

- [x] **Step 1: Initialize git if needed**

Run:

```powershell
git status
```

If this is not a git repository, run:

```powershell
git init
```

Expected: `git status` works.

- [x] **Step 2: Confirm Godot target**

Use Godot MCP `get_godot_version` or run:

```powershell
godot --version
```

Expected: Godot reports `4.6.2.stable.official` or a deliberately documented replacement target.

- [x] **Step 3: Add `.gitignore`**

Create `.gitignore`:

```gitignore
.godot/
.import/
.worktrees/
export.cfg
export_presets.cfg
builds/
*.tmp
*.log
```

Do not ignore `project.godot`, source files, docs, fixtures, or original/audited assets.

- [x] **Step 4: Create initial asset audit**

Create `docs/ASSET_AUDIT.md` before adding any asset files. The initial file may contain only original planned placeholders and a note that no third-party assets have been imported.

- [x] **Step 5: Prove the headless test pattern**

Create `tests/test_smoke.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	print("GDTaiko smoke test")
	quit(0)
```

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/test_smoke.gd
```

Expected: Exit 0.

- [x] **Step 6: Commit**

```powershell
git add .gitignore project.godot scenes README.md AGENTS.md DEVELOPMENT_PLAN.md docs tests scripts assets
git commit -m "chore: bootstrap GDTaiko project"
```

### Task 1: Create Godot Project Skeleton

**Files:**

- Create: `E:\10_创作\GDTaiko\project.godot`
- Create: `E:\10_创作\GDTaiko\README.md`
- Create: `E:\10_创作\GDTaiko\AGENTS.md`
- Create directories listed in Section 3.

- [x] **Step 1: Create directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  E:\10_创作\GDTaiko\scenes, `
  E:\10_创作\GDTaiko\scripts\app, `
  E:\10_创作\GDTaiko\scripts\chart, `
  E:\10_创作\GDTaiko\scripts\gameplay, `
  E:\10_创作\GDTaiko\scripts\ui, `
  E:\10_创作\GDTaiko\assets\notes, `
  E:\10_创作\GDTaiko\assets\sfx, `
  E:\10_创作\GDTaiko\assets\sample, `
  E:\10_创作\GDTaiko\tests\chart, `
  E:\10_创作\GDTaiko\tests\gameplay
```

Expected: Directories exist.

- [x] **Step 2: Write `project.godot`**

Create:

```ini
; Engine configuration file.
; Prefer editing from Godot after initial bootstrap.

config_version=5

[application]

config/name="GDTaiko"
run/main_scene="res://scenes/Main.tscn"
config/features=PackedStringArray("4.6")

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[input]

taiko_don={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":70,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
taiko_ka={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":74,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
taiko_start={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
```

- [x] **Step 3: Write `README.md`**

Create:

```markdown
# GDTaiko

GDTaiko is an independent Godot Taiko rhythm game project. It uses OpenTaiko as a behavioral reference for Taiko gameplay and `.tja` chart support, but it is implemented as a native Godot project.

## Phase 1 Goal

- Load one `.tja` chart.
- Play one audio file.
- Render Don/Ka notes.
- Judge input timing.
- Display score and combo.

## Controls

- `F`: Don
- `J`: Ka
- `Space`: Start

## Related Projects

- `E:\03_tools\Drum2Taiko`: offline drum-event and auto-charting toolchain.
- `E:\03_tools\psygodot`: research/runtime examples.
```

- [x] **Step 4: Write `AGENTS.md`**

Create:

```markdown
# AGENTS.md

## Project

GDTaiko is an independent Godot Taiko rhythm game. OpenTaiko is a reference for behavior and `.tja` compatibility, not a source tree to mechanically translate.

## Rules

- Keep the Godot runtime native to Godot/GDScript.
- Use Python only for optional offline tools.
- Do not copy third-party songs, skins, or assets unless their licenses are verified.
- Build playable vertical slices before broad feature expansion.
- Add tests for parser, timing, judging, and scoring changes.

## Multi-Agent Development

Use a multi-agent workflow by default.

Preferred model routing when available:

- `5.5 high`: architecture, OpenTaiko compatibility decisions, parser/timing/scoring review, branch/replay design, asset-license audit, release review.
- `5.3-codex-spark`: routine GDScript implementation, focused tests, fixtures, UI glue, simple docs, mechanical cleanup.

Required review gates:

- Any `.tja` parser semantics change needs `5.5 high` review.
- Any timing, judgment, scoring, gauge, branch, replay, or song-library storage change needs `5.5 high` review.
- Any asset import or release inclusion decision needs `5.5 high` asset-audit review.
- Routine implementation tasks can be done by `5.3-codex-spark`, but acceptance requires focused tests and review notes.

## Verification

Run Godot scene tests or parser tests after changes. If a test runner is not yet available, add deterministic test scenes/scripts and document the manual command used.
```

- [x] **Step 5: Commit**

```powershell
git add .gitignore project.godot scenes README.md AGENTS.md DEVELOPMENT_PLAN.md docs tests scripts assets
git commit -m "chore: bootstrap GDTaiko project"
```

Expected: Commit records the bootstrap and skeleton. If this is not a git repository yet, run `git init` before the commit.

### Testing Convention

Until a dedicated Godot test framework is adopted, tests are plain headless GDScript scripts run with:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/<area>/<test_file>.gd
```

On this machine, use the installed console binary until `godot` is added to PATH:

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'E:\10_创作\GDTaiko' -s res://tests/<area>/<test_file>.gd
```

Each test script must:

- Exit `0` only when all assertions pass.
- Exit non-zero on failure.
- Avoid editor-only dependencies.
- Use original fixtures under `tests/fixtures/`.

If the project later adopts GUT or gdUnit, update this section and all task verification commands in the same change.

Existing task snippets that use bare `assert()` should be wrapped in this exit-code behavior when implemented; a passing log is not enough unless the process exits `0` and failures exit non-zero.

### Task 2: Define Chart Data Model

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\chart\taiko_chart.gd`
- Create: `E:\10_创作\GDTaiko\tests\chart\test_taiko_chart.gd`

- [x] **Step 1: Write the failing data model test**

Create `tests/chart/test_taiko_chart.gd`:

```gdscript
extends SceneTree

const TaikoChart := preload("res://scripts/chart/taiko_chart.gd")

func _init() -> void:
	var chart := TaikoChart.new()
	chart.title = "Sample"
	chart.bpm = 150.0
	chart.offset_sec = -0.05
	chart.add_note(1.25, "don", "don", 0, 4)

	assert(chart.title == "Sample")
	assert(is_equal_approx(chart.bpm, 150.0))
	assert(is_equal_approx(chart.offset_sec, -0.05))
	assert(chart.notes.size() == 1)
	assert(chart.notes[0]["lane"] == "don")
	assert(chart.notes[0]["state"] == "pending")
	quit(0)
```

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_taiko_chart.gd
```

Expected: FAIL because `scripts/chart/taiko_chart.gd` does not exist.

- [x] **Step 3: Implement `TaikoChart`**

Create `scripts/chart/taiko_chart.gd`:

```gdscript
extends RefCounted
class_name TaikoChart

var title: String = ""
var subtitle: String = ""
var wave: String = ""
var bpm: float = 120.0
var offset_sec: float = 0.0
var course: String = "Oni"
var level: int = 1
var notes: Array[Dictionary] = []
var timing_events: Array[Dictionary] = []
var warnings: Array[String] = []

func add_note(time_sec: float, lane: String, kind: String, measure_index: int, subdivision_index: int) -> void:
	notes.append({
		"id": "note_%04d" % (notes.size() + 1),
		"time_sec": time_sec,
		"lane": lane,
		"kind": kind,
		"measure_index": measure_index,
		"subdivision_index": subdivision_index,
		"state": "pending",
	})

func add_timing_event(time_sec: float, event_type: String, value: Variant) -> void:
	timing_events.append({
		"time_sec": time_sec,
		"type": event_type,
		"value": value,
	})

func sort_notes() -> void:
	notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("time_sec", 0.0)) < float(b.get("time_sec", 0.0))
	)
```

- [x] **Step 4: Run test to verify it passes**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_taiko_chart.gd
```

Expected: PASS with exit code 0.

- [x] **Step 5: Commit**

```powershell
git add scripts/chart/taiko_chart.gd tests/chart/test_taiko_chart.gd
git commit -m "feat: add taiko chart data model"
```

### Task 3: Add TJA Tokenizer

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\chart\tja_tokenizer.gd`
- Create: `E:\10_创作\GDTaiko\tests\chart\test_tja_tokenizer.gd`

- [x] **Step 1: Write tokenizer test**

Create `tests/chart/test_tja_tokenizer.gd`:

```gdscript
extends SceneTree

const TjaTokenizer := preload("res://scripts/chart/tja_tokenizer.gd")

func _init() -> void:
	var text := """
TITLE:Test Song
BPM:150
// comment
#START
0012,
#BPMCHANGE 180
1000,
#END
"""
	var lines := TjaTokenizer.tokenize(text)
	assert(lines.size() == 7)
	assert(lines[0]["kind"] == "metadata")
	assert(lines[0]["key"] == "TITLE")
	assert(lines[0]["value"] == "Test Song")
	assert(lines[2]["kind"] == "command")
	assert(lines[2]["command"] == "START")
	assert(lines[3]["kind"] == "notes")
	assert(lines[3]["text"] == "0012,")
	assert(lines[4]["command"] == "BPMCHANGE")
	assert(lines[4]["argument"] == "180")
	quit(0)
```

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_tokenizer.gd
```

Expected: FAIL because tokenizer does not exist.

- [x] **Step 3: Implement tokenizer**

Create `scripts/chart/tja_tokenizer.gd`:

```gdscript
extends RefCounted
class_name TjaTokenizer

static func tokenize(text: String) -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	for raw_line in text.split("\n"):
		var line := String(raw_line).strip_edges()
		if line == "":
			continue
		if line.begins_with("//"):
			continue
		var comment_index := line.find("//")
		if comment_index >= 0:
			line = line.substr(0, comment_index).strip_edges()
		if line == "":
			continue
		if line.begins_with("#"):
			var body := line.substr(1).strip_edges()
			var whitespace_index := _first_whitespace_index(body)
			if whitespace_index < 0:
				tokens.append({"kind": "command", "command": body.to_upper(), "argument": ""})
			else:
				tokens.append({
					"kind": "command",
					"command": body.substr(0, whitespace_index).to_upper(),
					"argument": body.substr(whitespace_index + 1).strip_edges(),
				})
			continue
		var colon_index := line.find(":")
		if colon_index > 0 and not _looks_like_note_line(line):
			tokens.append({
				"kind": "metadata",
				"key": line.substr(0, colon_index).strip_edges().to_upper(),
				"value": line.substr(colon_index + 1).strip_edges(),
			})
			continue
		tokens.append({"kind": "notes", "text": line})
	return tokens

static func _looks_like_note_line(line: String) -> bool:
	for character in line:
		if not String(character) in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", ","]:
			return false
	return line.contains(",")

static func _first_whitespace_index(text: String) -> int:
	for index in range(text.length()):
		if text[index] == " " or text[index] == "\t":
			return index
	return -1
```

- [x] **Step 4: Run test to verify it passes**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_tokenizer.gd
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add scripts/chart/tja_tokenizer.gd tests/chart/test_tja_tokenizer.gd
git commit -m "feat: tokenize tja chart text"
```

### Task 4: Add TJA Parser Phase 1

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\chart\tja_parser.gd`
- Create: `E:\10_创作\GDTaiko\tests\chart\test_tja_parser.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\chart\taiko_chart.gd`

- [x] **Step 1: Write parser test**

Create `tests/chart/test_tja_parser.gd`:

```gdscript
extends SceneTree

const TjaParser := preload("res://scripts/chart/tja_parser.gd")

func _init() -> void:
	var text := """
TITLE:Parser Song
SUBTITLE:Unit Test
BPM:120
OFFSET:-0.5
WAVE:parser.ogg
COURSE:Oni
LEVEL:5
#START
1002,
0100,
#END
"""
	var chart = TjaParser.parse_text(text)
	assert(chart.title == "Parser Song")
	assert(chart.subtitle == "Unit Test")
	assert(chart.wave == "parser.ogg")
	assert(chart.course == "Oni")
	assert(chart.level == 5)
	assert(is_equal_approx(chart.bpm, 120.0))
	assert(is_equal_approx(chart.offset_sec, -0.5))
	assert(chart.notes.size() == 3)
	assert(chart.notes[0]["lane"] == "don")
	assert(chart.notes[1]["lane"] == "ka")
	assert(chart.notes[2]["lane"] == "don")
	assert(is_equal_approx(chart.notes[0]["time_sec"], -0.5))
	assert(is_equal_approx(chart.notes[1]["time_sec"], 1.0))
	assert(is_equal_approx(chart.notes[2]["time_sec"], 2.0))
	quit(0)
```

The third note is `2.0` seconds because the second measure starts at chart time `2.0`, slot index `1` adds `0.5`, and `OFFSET:-0.5` is applied to note time.

- [x] **Step 2: Run parser test to verify it fails**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_parser.gd
```

Expected: FAIL because parser does not exist.

- [x] **Step 3: Implement parser**

Create `scripts/chart/tja_parser.gd`:

```gdscript
extends RefCounted
class_name TjaParser

const TaikoChart := preload("res://scripts/chart/taiko_chart.gd")
const TjaTokenizer := preload("res://scripts/chart/tja_tokenizer.gd")

static func parse_file(path: String) -> TaikoChart:
	return parse_text(FileAccess.get_file_as_string(path))

static func parse_text(text: String) -> TaikoChart:
	var chart := TaikoChart.new()
	var in_chart := false
	var current_time := 0.0
	var current_bpm := 120.0
	var measure_index := 0
	var measure_numerator := 4.0
	var measure_denominator := 4.0

	for token in TjaTokenizer.tokenize(text):
		match String(token["kind"]):
			"metadata":
				_apply_metadata(chart, token)
				current_bpm = chart.bpm
			"command":
				var command := String(token["command"])
				var argument := String(token.get("argument", ""))
				if command == "START":
					in_chart = true
					current_time = 0.0
					current_bpm = chart.bpm
					chart.add_timing_event(current_time, "bpm", current_bpm)
				elif command == "END":
					in_chart = false
				elif in_chart and command == "BPMCHANGE":
					current_bpm = argument.to_float()
					chart.add_timing_event(current_time + chart.offset_sec, "bpm", current_bpm)
				elif in_chart and command == "MEASURE":
					var parts := argument.split("/")
					if parts.size() == 2 and parts[1].to_float() != 0.0:
						measure_numerator = parts[0].to_float()
						measure_denominator = parts[1].to_float()
						chart.add_timing_event(current_time + chart.offset_sec, "measure", argument)
			"notes":
				if in_chart:
					var result := _parse_note_line(
						chart,
						String(token["text"]),
						current_time,
						current_bpm,
						measure_numerator,
						measure_denominator,
						measure_index
					)
					current_time = result["time_sec"]
					measure_index = result["measure_index"]
	chart.sort_notes()
	return chart

static func _apply_metadata(chart: TaikoChart, token: Dictionary) -> void:
	var key := String(token["key"])
	var value := String(token["value"])
	match key:
		"TITLE":
			chart.title = value
		"SUBTITLE":
			chart.subtitle = value
		"WAVE":
			chart.wave = value
		"BPM":
			chart.bpm = value.to_float()
		"OFFSET":
			chart.offset_sec = value.to_float()
		"COURSE":
			chart.course = value
		"LEVEL":
			chart.level = int(value)

static func _parse_note_line(
	chart: TaikoChart,
	line: String,
	start_time: float,
	bpm: float,
	measure_numerator: float,
	measure_denominator: float,
	measure_index: int
) -> Dictionary:
	var current_time := start_time
	var measure_text := ""
	for character in line:
		var value := String(character)
		if value == ",":
			current_time = _parse_measure(chart, measure_text, current_time, bpm, measure_numerator, measure_denominator, measure_index)
			measure_index += 1
			measure_text = ""
		else:
			measure_text += value
	if measure_text != "":
		current_time = _parse_measure(chart, measure_text, current_time, bpm, measure_numerator, measure_denominator, measure_index)
		measure_index += 1
	return {"time_sec": current_time, "measure_index": measure_index}

static func _parse_measure(
	chart: TaikoChart,
	measure_text: String,
	start_time: float,
	bpm: float,
	measure_numerator: float,
	measure_denominator: float,
	measure_index: int
) -> float:
	var slots := measure_text.length()
	if slots <= 0:
		return start_time
	var beat_count := measure_numerator * (4.0 / measure_denominator)
	var measure_duration := beat_count * 60.0 / bpm
	var slot_duration := measure_duration / float(slots)
	for index in range(slots):
		var value := measure_text[index]
		var lane := _lane_for_note_char(value)
		if lane != "":
			var note_time := start_time + (slot_duration * float(index)) + chart.offset_sec
			chart.add_note(note_time, lane, lane, measure_index, index)
		elif value != "0":
			chart.warnings.append("Unsupported note character '%s' in measure %d" % [value, measure_index])
	return start_time + measure_duration

static func _lane_for_note_char(value: String) -> String:
	if value == "1":
		return "don"
	if value == "2":
		return "ka"
	return ""
```

- [x] **Step 4: Run parser test to verify it passes**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_parser.gd
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add scripts/chart/tja_parser.gd tests/chart/test_tja_parser.gd
git commit -m "feat: parse phase one tja charts"
```

### Task 5: Add Timing Judge

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\judge.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_judge.gd`

- [x] **Step 1: Write judge test**

Create `tests/gameplay/test_judge.gd`:

```gdscript
extends SceneTree

const Judge := preload("res://scripts/gameplay/judge.gd")

func _init() -> void:
	var judge := Judge.new()
	assert(judge.judge(1.000, 1.020)["judgment"] == "perfect")
	assert(judge.judge(1.000, 1.080)["judgment"] == "good")
	assert(judge.judge(1.000, 1.140)["judgment"] == "bad")
	assert(judge.judge(1.000, 1.220)["judgment"] == "miss")
	assert(judge.is_expired(1.000, 1.180))
	assert(not judge.is_expired(1.000, 1.100))
	quit(0)
```

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_judge.gd
```

Expected: FAIL because `judge.gd` does not exist.

- [x] **Step 3: Implement judge**

Create `scripts/gameplay/judge.gd`:

```gdscript
extends RefCounted
class_name Judge

const PERFECT_SEC := 0.045
const GOOD_SEC := 0.095
const BAD_SEC := 0.150

func judge(scheduled_time_sec: float, hit_time_sec: float) -> Dictionary:
	var error_sec := hit_time_sec - scheduled_time_sec
	var abs_error := absf(error_sec)
	var judgment := "miss"
	if abs_error <= PERFECT_SEC:
		judgment = "perfect"
	elif abs_error <= GOOD_SEC:
		judgment = "good"
	elif abs_error <= BAD_SEC:
		judgment = "bad"
	return {
		"judgment": judgment,
		"timing_error_sec": error_sec,
		"timing_error_ms": error_sec * 1000.0,
	}

func is_expired(scheduled_time_sec: float, song_time_sec: float) -> bool:
	return song_time_sec > scheduled_time_sec + BAD_SEC
```

- [x] **Step 4: Run test to verify it passes**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_judge.gd
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add scripts/gameplay/judge.gd tests/gameplay/test_judge.gd
git commit -m "feat: add taiko timing judge"
```

### Task 6: Add Scoring

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\scoring.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_scoring.gd`

- [x] **Step 1: Write scoring test**

Create `tests/gameplay/test_scoring.gd`:

```gdscript
extends SceneTree

const Scoring := preload("res://scripts/gameplay/scoring.gd")

func _init() -> void:
	var scoring := Scoring.new()
	scoring.apply_judgment("perfect")
	scoring.apply_judgment("good")
	assert(scoring.combo == 2)
	assert(scoring.max_combo == 2)
	assert(scoring.score == 1600)
	scoring.apply_judgment("bad")
	assert(scoring.combo == 0)
	assert(scoring.score == 1700)
	scoring.apply_judgment("miss")
	assert(scoring.combo == 0)
	assert(scoring.misses == 1)
	quit(0)
```

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_scoring.gd
```

Expected: FAIL because `scoring.gd` does not exist.

- [x] **Step 3: Implement scoring**

Create `scripts/gameplay/scoring.gd`:

```gdscript
extends RefCounted
class_name Scoring

var score := 0
var combo := 0
var max_combo := 0
var perfects := 0
var goods := 0
var bads := 0
var misses := 0

func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	perfects = 0
	goods = 0
	bads = 0
	misses = 0

func apply_judgment(judgment: String) -> void:
	match judgment:
		"perfect":
			perfects += 1
			combo += 1
			score += 1000
		"good":
			goods += 1
			combo += 1
			score += 600
		"bad":
			bads += 1
			combo = 0
			score += 100
		"miss":
			misses += 1
			combo = 0
	max_combo = max(max_combo, combo)
```

- [x] **Step 4: Run test to verify it passes**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_scoring.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add scripts/gameplay/scoring.gd tests/gameplay/test_scoring.gd
git commit -m "feat: add basic taiko scoring"
```

### Task 7: Add Song Clock

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\song_clock.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_song_clock.gd`

- [x] **Step 1: Implement clock**

Create `scripts/gameplay/song_clock.gd`:

```gdscript
extends Node
class_name SongClock

var audio_player: AudioStreamPlayer
var chart_offset_sec := 0.0
var fallback_time_sec := 0.0
var using_audio_position := true

func configure(player: AudioStreamPlayer, offset_sec: float) -> void:
	audio_player = player
	chart_offset_sec = offset_sec
	fallback_time_sec = 0.0

func reset() -> void:
	fallback_time_sec = 0.0

func advance(delta: float) -> void:
	if audio_player != null and audio_player.playing and using_audio_position:
		return
	fallback_time_sec += delta

func time_sec() -> float:
	if audio_player != null and audio_player.playing and using_audio_position:
		return audio_player.get_playback_position() + chart_offset_sec
	return fallback_time_sec + chart_offset_sec
```

- [x] **Step 2: Add focused headless SongClock test**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_song_clock.gd
```

Expected: PASS.

- [ ] **Step 3: Commit**

```powershell
git add scripts/gameplay/song_clock.gd tests/gameplay/test_song_clock.gd
git commit -m "feat: add song clock"
```

### Task 8: Create Main Scene

**Files:**

- Create: `E:\10_创作\GDTaiko\scenes\Main.tscn`
- Create: `E:\10_创作\GDTaiko\scripts\app\main.gd`

- [x] **Step 1: Create `main.gd`**

Create `scripts/app/main.gd`:

```gdscript
extends Node

func _ready() -> void:
	get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")
```

- [x] **Step 2: Create `Main.tscn`**

Create `scenes/Main.tscn`:

```text
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/app/main.gd" id="1_main"]

[node name="Main" type="Node"]
script = ExtResource("1_main")
```

- [x] **Step 3: Add and run headless scene verification**

Run:

```powershell
godot --headless --path E:\10_����\GDTaiko\.worktrees\phase1-task2-chart-model -s res://tests/app/test_main_scene.gd
```

Expected: The headless test asserts `Main` node and script without entering the scene tree.

- [ ] **Step 4: Commit**

```powershell
git add scenes/Main.tscn scripts/app/main.gd
git commit -m "feat: add main scene entrypoint"
```
### Task 9: Add HUD

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\ui\hud.gd`
- Create: `tests\ui\test_hud.gd`

- [x] **Step 1: Implement HUD script**

Create `scripts/ui/hud.gd`:

```gdscript
extends CanvasLayer
class_name TaikoHud

var score_label: Label
var combo_label: Label
var judgment_label: Label
var status_label: Label

func build() -> void:
	score_label = _label("Score: 0", Vector2(24, 20), 28)
	combo_label = _label("Combo: 0", Vector2(24, 58), 28)
	judgment_label = _label("F = Don    J = Ka    Space = Start", Vector2(360, 610), 26)
	status_label = _label("Ready", Vector2(24, 660), 22)

func update_score(score: int, combo: int) -> void:
	score_label.text = "Score: %d" % score
	combo_label.text = "Combo: %d" % combo

func show_judgment(judgment: String, timing_error_ms: float = 0.0) -> void:
	if judgment == "":
		judgment_label.text = "F = Don    J = Ka    Space = Start"
	else:
		judgment_label.text = "%s  %+.0f ms" % [judgment.capitalize(), timing_error_ms]

func set_status(text: String) -> void:
	status_label.text = text

func _label(text: String, position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
```

- [x] **Step 2: Add focused HUD test**

Create `tests/ui/test_hud.gd`.

Expected: HUD labels and text updates are deterministic in headless tests.

- [x] **Step 3: Commit**

```powershell
git add DEVELOPMENT_PLAN.md scripts/ui/hud.gd tests/ui/test_hud.gd
git commit -m "feat: add gameplay hud"
```

### Task 10: Add Note Lane

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\note_lane.gd`
- Create: `E:\10_创作\GDTaiko\scripts\gameplay\note_model.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_note_lane.gd`

- [x] **Step 1: Implement note model constants**

Create `scripts/gameplay/note_model.gd`:

```gdscript
extends RefCounted
class_name NoteModel

const DON := "don"
const KA := "ka"
const PENDING := "pending"
const HIT := "hit"
const MISSED := "missed"
```

- [x] **Step 2: Implement note lane**

Create `scripts/gameplay/note_lane.gd`:

```gdscript
extends Node2D
class_name NoteLane

const HIT_X := 260.0
const SPAWN_X := 1180.0
const NOTE_Y := 180.0
const APPROACH_TIME_SEC := 2.0

var note_nodes: Dictionary = {}
var don_texture: Texture2D
var ka_texture: Texture2D

func configure(don: Texture2D, ka: Texture2D) -> void:
	don_texture = don
	ka_texture = ka

func spawn_notes(notes: Array[Dictionary]) -> void:
	clear_notes()
	for note in notes:
		var sprite := Sprite2D.new()
		sprite.texture = don_texture if String(note.get("lane", "don")) == "don" else ka_texture
		sprite.position = Vector2(SPAWN_X, NOTE_Y)
		add_child(sprite)
		note_nodes[String(note["id"])] = sprite

func clear_notes() -> void:
	for child in get_children():
		child.queue_free()
	note_nodes.clear()

func update_notes(notes: Array[Dictionary], song_time_sec: float) -> void:
	for note in notes:
		var id := String(note["id"])
		if not note_nodes.has(id):
			continue
		var sprite: Sprite2D = note_nodes[id]
		var scheduled := float(note.get("time_sec", 0.0))
		var progress := clamp(1.0 - ((scheduled - song_time_sec) / APPROACH_TIME_SEC), 0.0, 1.25)
		sprite.position = Vector2(lerpf(SPAWN_X, HIT_X, progress), NOTE_Y)
		sprite.visible = String(note.get("state", "pending")) == "pending"
```

- [x] **Step 3: Add focused note lane test**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_note_lane.gd
```

Expected: PASS.

- [x] **Step 4: Commit**

```powershell
git add scripts/gameplay/note_model.gd scripts/gameplay/note_lane.gd tests/gameplay/test_note_lane.gd
git commit -m "feat: add note lane rendering"
```

### Task 11: Add Gameplay Controller and Scene

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\gameplay_controller.gd`
- Create: `E:\10_创作\GDTaiko\scenes\Gameplay.tscn`
- Add sample assets in `E:\10_创作\GDTaiko\assets\sample`

- Create: `tests/gameplay/test_gameplay_controller.gd`
- Modify: `docs/ASSET_AUDIT.md`

- [x] **Step 1: Create sample `.tja`**

Create `assets/sample/sample.tja`:

```text
TITLE:GDTaiko Sample
SUBTITLE:Phase 1
BPM:120
OFFSET:0
WAVE:sample.ogg
COURSE:Oni
LEVEL:1
#START
1002,
0100,
1002,
0100,
#END
```

- [x] **Step 2: Add placeholder audio**

Add `assets/sample/sample.ogg`.

Use a short locally generated placeholder and keep ownership/licensing tracked in `docs/ASSET_AUDIT.md`.

- [x] **Step 3: Add placeholder note textures**

Add:

```text
assets/notes/note_don.png
assets/notes/note_ka.png
```

Use simple original circles. Do not copy commercial Taiko assets.

- [x] **Step 4: Implement gameplay controller**

Create `scripts/gameplay/gameplay_controller.gd`:

```gdscript
extends Node2D

const TjaParser := preload("res://scripts/chart/tja_parser.gd")
const Judge := preload("res://scripts/gameplay/judge.gd")
const Scoring := preload("res://scripts/gameplay/scoring.gd")
const SongClock := preload("res://scripts/gameplay/song_clock.gd")
const NoteLane := preload("res://scripts/gameplay/note_lane.gd")
const TaikoHud := preload("res://scripts/ui/hud.gd")

var chart
var judge := Judge.new()
var scoring := Scoring.new()
var clock: SongClock
var lane: NoteLane
var hud: TaikoHud
var audio_player: AudioStreamPlayer
var playing := false

func _ready() -> void:
	_build_scene()
	_load_sample_chart()

func _process(delta: float) -> void:
	if not playing:
		return
	clock.advance(delta)
	var song_time := clock.time_sec()
	lane.update_notes(chart.notes, song_time)
	_process_misses(song_time)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("taiko_start"):
		_start_song()
	elif event.is_action_pressed("taiko_don"):
		_hit("don")
	elif event.is_action_pressed("taiko_ka"):
		_hit("ka")

func _build_scene() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	clock = SongClock.new()
	add_child(clock)
	lane = NoteLane.new()
	add_child(lane)
	hud = TaikoHud.new()
	add_child(hud)
	hud.build()

	var don_texture := load("res://assets/notes/note_don.png")
	var ka_texture := load("res://assets/notes/note_ka.png")
	lane.configure(don_texture, ka_texture)

func _load_sample_chart() -> void:
	chart = TjaParser.parse_file("res://assets/sample/sample.tja")
	var audio_path := "res://assets/sample/" + chart.wave
	if ResourceLoader.exists(audio_path):
		audio_player.stream = load(audio_path)
	clock.configure(audio_player, 0.0)
	lane.spawn_notes(chart.notes)
	hud.set_status("Loaded %s - press Space" % chart.title)

func _start_song() -> void:
	if chart == null:
		return
	for note in chart.notes:
		note["state"] = "pending"
	scoring.reset()
	clock.reset()
	lane.spawn_notes(chart.notes)
	playing = true
	if audio_player.stream != null:
		audio_player.play()
	hud.update_score(scoring.score, scoring.combo)
	hud.set_status("Playing")

func _hit(lane_name: String) -> void:
	if not playing:
		return
	var song_time := clock.time_sec()
	var best_note: Dictionary = {}
	var best_error := INF
	for note in chart.notes:
		if String(note.get("state", "pending")) != "pending":
			continue
		if String(note.get("lane", "don")) != lane_name:
			continue
		var error := absf(float(note["time_sec"]) - song_time)
		if error < best_error:
			best_error = error
			best_note = note
	if best_note.is_empty():
		_apply_empty_miss()
		return
	var result := judge.judge(float(best_note["time_sec"]), song_time)
	if result["judgment"] == "miss":
		_apply_empty_miss()
		return
	best_note["state"] = "hit"
	scoring.apply_judgment(result["judgment"])
	hud.update_score(scoring.score, scoring.combo)
	hud.show_judgment(result["judgment"], result["timing_error_ms"])

func _apply_empty_miss() -> void:
	scoring.apply_judgment("miss")
	hud.update_score(scoring.score, scoring.combo)
	hud.show_judgment("miss", 0.0)

func _process_misses(song_time: float) -> void:
	for note in chart.notes:
		if String(note.get("state", "pending")) != "pending":
			continue
		if judge.is_expired(float(note["time_sec"]), song_time):
			note["state"] = "missed"
			scoring.apply_judgment("miss")
			hud.update_score(scoring.score, scoring.combo)
			hud.show_judgment("miss", 0.0)
```

- [x] **Step 5: Create `Gameplay.tscn`**

Create `scenes/Gameplay.tscn`:

```text
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/gameplay/gameplay_controller.gd" id="1_gameplay"]

[node name="Gameplay" type="Node2D"]
script = ExtResource("1_gameplay")
```

- [x] **Step 6A: Add headless gameplay-controller test and asset audit updates**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_gameplay_controller.gd
```

Expected: PASS from deterministic loading/spawn/start/hit/miss coverage.

- [x] **Step 6: Run manual gameplay check**

Run:

```powershell
godot --path E:\10_创作\GDTaiko
```

Expected:

MCP run-project verification opened the Godot project without the parent-busy scene-change error. Headless gameplay-controller tests cover start, note movement, Don input, misses, and score/combo updates.

- Game opens.
- Sample chart loads.
- Pressing Space starts.
- Notes move from right to hit line.
- Pressing F hits Don.
- Pressing J hits Ka.
- Score/combo update.

- [x] **Step 7: Commit**

```powershell
git add DEVELOPMENT_PLAN.md docs/ASSET_AUDIT.md assets/sample/sample.tja assets/sample/sample.ogg assets/notes/note_don.png assets/notes/note_ka.png scripts/app/main.gd scripts/gameplay/gameplay_controller.gd scenes/Gameplay.tscn tests/gameplay/test_gameplay_controller.gd
git commit -m "feat: add gameplay controller and scene"
```

### Task 12: Phase 1 Acceptance Pass

**Files:**

- Modify: `E:\10_创作\GDTaiko\README.md`
- Create: `E:\10_创作\GDTaiko\docs\PHASE_1_ACCEPTANCE.md`

- [x] **Step 1: Create acceptance checklist**

Create `docs/PHASE_1_ACCEPTANCE.md`:

```markdown
# Phase 1 Acceptance

## Required

- [ ] Project opens in Godot.
- [ ] `res://scenes/Main.tscn` loads `Gameplay.tscn`.
- [ ] Sample `.tja` parses without crash.
- [ ] Sample audio plays or documented placeholder audio is loaded.
- [ ] Don notes can be hit with `F`.
- [ ] Ka notes can be hit with `J`.
- [ ] Misses occur when notes pass the timing window.
- [ ] Score updates.
- [ ] Combo updates.
- [ ] Parser tests pass.
- [ ] Judge tests pass.
- [ ] Scoring tests pass.

## Known Phase 1 Limits

- Roll notes are not implemented.
- Balloon notes are not implemented.
- GOGO time is not implemented.
- Branching is not implemented.
- Song select is not implemented.
- Skinning is not implemented.
```

- [x] **Step 2: Update README with run/test commands**

Append to `README.md`:

````markdown
## Run

```powershell
godot --path E:\10_创作\GDTaiko
```

## Tests

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/test_smoke.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_taiko_chart.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_tokenizer.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_parser.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_judge.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_scoring.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_song_clock.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_note_lane.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_gameplay_controller.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/ui/test_hud.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/app/test_main_scene.gd
```
````

- [x] **Step 3: Run verification commands**

Run:

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/test_smoke.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_taiko_chart.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_tokenizer.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_parser.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_judge.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_scoring.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_song_clock.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_note_lane.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_gameplay_controller.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/ui/test_hud.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/app/test_main_scene.gd
```

Expected: All exit 0.

- [x] **Step 4: Commit**

```powershell
git add DEVELOPMENT_PLAN.md README.md docs/PHASE_1_ACCEPTANCE.md tests/gameplay/test_gameplay_controller.gd
git commit -m "docs: document phase one acceptance"
```

## 7. Full Recreation Roadmap

The goal after Phase 1 is not a small MVP. The target is a Godot-native Taiko runtime with OpenTaiko-level compatibility where practical:

- `.tja` chart compatibility for common player charts.
- Song folder scanning and multi-course selection.
- Accurate timing, scrolling, judgment, roll, balloon, GOGO, branch, and gauge behavior.
- Configurable input, offset, audio, display, and gameplay settings.
- Theme/skin architecture using original or verified-license assets.
- Local profile, score, replay, and result persistence.
- Automated compatibility fixtures so behavior does not regress.

This remains a rewrite, not a mechanical C# translation.

## 8. Phase 2: Complete Taiko Gameplay Rules

Outcome: A single loaded chart plays with the major Taiko note/rule systems: roll, balloon, GOGO, BPM changes, scroll changes, measure changes, gauge, and result screen.

### Task 13: Expand Chart Model For Advanced Notes

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\chart\taiko_chart.gd`
- Modify: `E:\10_创作\GDTaiko\tests\chart\test_taiko_chart.gd`

- [x] **Step 1: Add failing assertions for advanced note fields**

Extend `test_taiko_chart.gd` with:

```gdscript
chart.add_note(2.0, "roll", "roll_big_start", 1, 0, {"duration_sec": 1.5, "required_hits": 0})
chart.add_note(4.0, "balloon", "balloon_start", 2, 0, {"duration_sec": 2.0, "required_hits": 8})
assert(chart.notes[1]["kind"] == "roll_big_start")
assert(is_equal_approx(chart.notes[1]["duration_sec"], 1.5))
assert(chart.notes[2]["required_hits"] == 8)
```

Expected before implementation: FAIL because `add_note` does not accept metadata.

- [x] **Step 2: Update `add_note` signature**

Change the method to:

```gdscript
func add_note(
	time_sec: float,
	lane: String,
	kind: String,
	measure_index: int,
	subdivision_index: int,
	extra: Dictionary = {}
) -> void:
	var note := {
		"id": "note_%04d" % (notes.size() + 1),
		"time_sec": time_sec,
		"lane": lane,
		"kind": kind,
		"measure_index": measure_index,
		"subdivision_index": subdivision_index,
		"state": "pending",
	}
	for key in extra:
		note[key] = extra[key]
	notes.append(note)
```

- [x] **Step 3: Run model tests**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_taiko_chart.gd
```

Expected: PASS.

- [x] **Step 4: Commit**

```powershell
git add DEVELOPMENT_PLAN.md scripts/chart/taiko_chart.gd tests/chart/test_taiko_chart.gd
git commit -m "feat: extend chart model for advanced notes"
```

### Task 14: Parse Roll And Balloon Notes

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\chart\tja_parser.gd`
- Modify: `E:\10_创作\GDTaiko\tests\chart\test_tja_parser.gd`

- [x] **Step 1: Add fixture test for roll and balloon**

Add parser test case:

```gdscript
var text := """
TITLE:Roll Balloon
BPM:120
BALLOON:8
#START
5008,
7008,
#END
"""
var chart = TjaParser.parse_text(text)
assert(chart.notes.size() == 2)
assert(chart.notes[0]["kind"] == "roll_start")
assert(is_equal_approx(chart.notes[0]["duration_sec"], 1.5))
assert(chart.notes[1]["kind"] == "balloon_start")
assert(chart.notes[1]["required_hits"] == 8)
```

Expected before implementation: FAIL because note characters `5`, `7`, and `8` are unsupported.

- [x] **Step 2: Parse `BALLOON:` metadata**

Add to `TaikoChart`:

```gdscript
var balloon_counts: Array[int] = []
```

Add metadata handling:

```gdscript
"BALLOON":
	chart.balloon_counts.clear()
	for part in value.split(","):
		if part.strip_edges() != "":
			chart.balloon_counts.append(int(part.strip_edges()))
```

- [x] **Step 3: Track active long note starts**

Inside `tja_parser.gd`, maintain:

```gdscript
var active_long_note: Dictionary = {}
var balloon_index := 0
```

When parsing a measure:

- `5`: start small roll, lane `roll`, kind `roll_start`.
- `6`: start big roll, lane `roll`, kind `roll_big_start`.
- `7`: start balloon, lane `balloon`, kind `balloon_start`, required hits from `BALLOON`.
- `8`: close current roll/balloon and set `duration_sec`.

- [x] **Step 4: Run parser tests**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_parser.gd
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add scripts/chart/taiko_chart.gd scripts/chart/tja_parser.gd tests/chart/test_tja_parser.gd
git commit -m "feat: parse roll and balloon notes"
```

### Task 15: Add Roll Hit Runtime

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\roll_manager.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\gameplay_controller.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_roll_manager.gd`

- [x] **Step 1: Write roll manager test**

Create:

```gdscript
extends SceneTree

const RollManager := preload("res://scripts/gameplay/roll_manager.gd")

func _init() -> void:
	var manager := RollManager.new()
	var note := {"id": "roll_1", "time_sec": 1.0, "duration_sec": 2.0, "kind": "roll_start"}
	assert(manager.is_active(note, 0.99) == false)
	assert(manager.is_active(note, 1.00) == true)
	assert(manager.is_active(note, 2.50) == true)
	assert(manager.is_active(note, 3.01) == false)
	manager.register_hit(note)
	manager.register_hit(note)
	assert(manager.hit_count("roll_1") == 2)
	quit(0)
```

- [x] **Step 2: Implement `roll_manager.gd`**

```gdscript
extends RefCounted
class_name RollManager

var hits_by_note: Dictionary = {}

func is_roll(note: Dictionary) -> bool:
	return String(note.get("kind", "")).contains("roll")

func is_active(note: Dictionary, song_time_sec: float) -> bool:
	var start := float(note.get("time_sec", 0.0))
	var end := start + float(note.get("duration_sec", 0.0))
	return song_time_sec >= start and song_time_sec <= end

func register_hit(note: Dictionary) -> void:
	var id := String(note.get("id", ""))
	hits_by_note[id] = int(hits_by_note.get(id, 0)) + 1

func hit_count(note_id: String) -> int:
	return int(hits_by_note.get(note_id, 0))

func reset() -> void:
	hits_by_note.clear()
```

- [x] **Step 3: Integrate rolls into input handling**

In `gameplay_controller.gd`, before normal note hit lookup:

```gdscript
for note in chart.notes:
	if roll_manager.is_roll(note) and roll_manager.is_active(note, song_time):
		roll_manager.register_hit(note)
		scoring.apply_roll_hit()
		hud.update_score(scoring.score, scoring.combo)
		return
```

- [x] **Step 4: Add roll scoring**

In `scoring.gd`:

```gdscript
var roll_hits := 0

func apply_roll_hit() -> void:
	roll_hits += 1
	score += 100
```

- [x] **Step 5: Run roll and scoring tests**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_roll_manager.gd
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_scoring.gd
```

Expected: PASS.

- [x] **Step 6: Commit**

```powershell
git add scripts/gameplay/roll_manager.gd scripts/gameplay/gameplay_controller.gd scripts/gameplay/scoring.gd tests/gameplay/test_roll_manager.gd tests/gameplay/test_scoring.gd
git commit -m "feat: add roll note gameplay"
```

### Task 16: Add Balloon Runtime

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\balloon_manager.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\gameplay_controller.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_balloon_manager.gd`

- [x] **Step 1: Write balloon manager test**

Create:

```gdscript
extends SceneTree

const BalloonManager := preload("res://scripts/gameplay/balloon_manager.gd")

func _init() -> void:
	var manager := BalloonManager.new()
	var note := {"id": "balloon_1", "required_hits": 3}
	assert(manager.remaining(note) == 3)
	assert(manager.register_hit(note) == false)
	assert(manager.remaining(note) == 2)
	assert(manager.register_hit(note) == false)
	assert(manager.register_hit(note) == true)
	assert(manager.remaining(note) == 0)
	assert(manager.is_cleared("balloon_1"))
	quit(0)
```

- [x] **Step 2: Implement balloon manager**

```gdscript
extends RefCounted
class_name BalloonManager

var hits_by_note: Dictionary = {}
var cleared: Dictionary = {}

func is_balloon(note: Dictionary) -> bool:
	return String(note.get("kind", "")) == "balloon_start"

func register_hit(note: Dictionary) -> bool:
	var id := String(note.get("id", ""))
	var next_hits := int(hits_by_note.get(id, 0)) + 1
	hits_by_note[id] = next_hits
	var complete := next_hits >= int(note.get("required_hits", 1))
	if complete:
		cleared[id] = true
	return complete

func remaining(note: Dictionary) -> int:
	var id := String(note.get("id", ""))
	return max(0, int(note.get("required_hits", 1)) - int(hits_by_note.get(id, 0)))

func is_cleared(note_id: String) -> bool:
	return bool(cleared.get(note_id, false))

func reset() -> void:
	hits_by_note.clear()
	cleared.clear()
```

- [x] **Step 3: Integrate balloon handling**

In gameplay input handling, check active balloon before normal notes. On completion:

```gdscript
if balloon_manager.register_hit(note):
	note["state"] = "hit"
	scoring.apply_balloon_clear()
else:
	scoring.apply_roll_hit()
```

Add to `scoring.gd`:

```gdscript
var balloons_cleared := 0

func apply_balloon_clear() -> void:
	balloons_cleared += 1
	score += 5000
```

- [x] **Step 4: Run tests**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_balloon_manager.gd
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_scoring.gd
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add scripts/gameplay/balloon_manager.gd scripts/gameplay/gameplay_controller.gd scripts/gameplay/scoring.gd tests/gameplay/test_balloon_manager.gd
git commit -m "feat: add balloon note gameplay"
```

### Task 17: Add GOGO Time

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\chart\tja_parser.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\scoring.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\gameplay_controller.gd`
- Modify: `E:\10_创作\GDTaiko\tests\chart\test_tja_parser.gd`
- Modify: `E:\10_创作\GDTaiko\tests\gameplay\test_scoring.gd`

- [x] **Step 1: Add parser assertion**

Use fixture:

```gdscript
var text := """
TITLE:Gogo
BPM:120
#START
#GOGOSTART
1000,
#GOGOEND
1000,
#END
"""
var chart = TjaParser.parse_text(text)
assert(chart.timing_events.any(func(e): return e["type"] == "gogo" and e["value"] == true))
assert(chart.timing_events.any(func(e): return e["type"] == "gogo" and e["value"] == false))
```

- [x] **Step 2: Parse GOGO commands**

In command handling:

```gdscript
elif in_chart and command == "GOGOSTART":
	chart.add_timing_event(current_time + chart.offset_sec, "gogo", true)
elif in_chart and command == "GOGOEND":
	chart.add_timing_event(current_time + chart.offset_sec, "gogo", false)
```

- [x] **Step 3: Add scoring multiplier**

In `scoring.gd`:

```gdscript
var gogo_active := false

func set_gogo(active: bool) -> void:
	gogo_active = active

func _apply_multiplier(points: int) -> int:
	return int(round(float(points) * (1.2 if gogo_active else 1.0)))
```

Use `_apply_multiplier(1000)`, `_apply_multiplier(600)`, and `_apply_multiplier(100)` for normal note judgments.

- [x] **Step 4: Update gameplay controller**

Each frame, apply current timing event state:

```gdscript
func _update_timing_states(song_time: float) -> void:
	var gogo := false
	for event in chart.timing_events:
		if float(event["time_sec"]) <= song_time and String(event["type"]) == "gogo":
			gogo = bool(event["value"])
	scoring.set_gogo(gogo)
	hud.set_gogo(gogo)
```

Add `set_gogo(active: bool)` to HUD and change lane color/text.

- [x] **Step 5: Run parser and scoring tests**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_parser.gd
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_scoring.gd
```

Expected: PASS.

- [x] **Step 6: Commit**

```powershell
git add scripts/chart/tja_parser.gd scripts/gameplay/scoring.gd scripts/gameplay/gameplay_controller.gd scripts/ui/hud.gd tests/chart/test_tja_parser.gd tests/gameplay/test_scoring.gd
git commit -m "feat: add gogo time"
```

### Task 18: Add BPM, MEASURE, And SCROLL Timing Map

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\chart\timing_map.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\chart\tja_parser.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\note_lane.gd`
- Create: `E:\10_创作\GDTaiko\tests\chart\test_timing_map.gd`

- [x] **Step 1: Write timing map test**

Create:

```gdscript
extends SceneTree

const TimingMap := preload("res://scripts/chart/timing_map.gd")

func _init() -> void:
	var map := TimingMap.new()
	map.add_event(0.0, "scroll", 1.0)
	map.add_event(2.0, "scroll", 2.0)
	assert(is_equal_approx(map.scroll_at(1.0), 1.0))
	assert(is_equal_approx(map.scroll_at(2.5), 2.0))
	map.add_event(0.0, "bpm", 120.0)
	map.add_event(4.0, "bpm", 180.0)
	assert(is_equal_approx(map.bpm_at(3.0), 120.0))
	assert(is_equal_approx(map.bpm_at(4.0), 180.0))
	quit(0)
```

- [x] **Step 2: Implement timing map**

Create:

```gdscript
extends RefCounted
class_name TimingMap

var events: Array[Dictionary] = []

func add_event(time_sec: float, event_type: String, value) -> void:
	events.append({"time_sec": time_sec, "type": event_type, "value": value})
	events.sort_custom(func(a, b): return float(a["time_sec"]) < float(b["time_sec"]))

func value_at(event_type: String, song_time_sec: float, default_value):
	var current = default_value
	for event in events:
		if float(event["time_sec"]) > song_time_sec:
			break
		if String(event["type"]) == event_type:
			current = event["value"]
	return current

func bpm_at(song_time_sec: float) -> float:
	return float(value_at("bpm", song_time_sec, 120.0))

func scroll_at(song_time_sec: float) -> float:
	return float(value_at("scroll", song_time_sec, 1.0))
```

- [x] **Step 3: Parse `#SCROLL`**

In `tja_parser.gd` command handling:

```gdscript
elif in_chart and command == "SCROLL":
	chart.add_timing_event(current_time + chart.offset_sec, "scroll", argument.to_float())
```

- [x] **Step 4: Use scroll in note lane**

Change visual progress:

```gdscript
var scroll := timing_map.scroll_at(scheduled)
var progress := clamp(1.0 - ((scheduled - song_time_sec) / (APPROACH_TIME_SEC / max(0.1, scroll))), 0.0, 1.25)
```

Pass `TimingMap` into `note_lane.update_notes`.

- [x] **Step 5: Run tests**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_timing_map.gd
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_parser.gd
```

Expected: PASS.

- [x] **Step 6: Commit**

```powershell
git add scripts/chart/timing_map.gd scripts/chart/tja_parser.gd scripts/gameplay/note_lane.gd tests/chart/test_timing_map.gd tests/chart/test_tja_parser.gd
git commit -m "feat: add timing map for bpm measure and scroll"
```

### Task 19: Add Soul Gauge And Result Screen

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\gameplay\soul_gauge.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_soul_gauge.gd`
- Create: `E:\10_创作\GDTaiko\scenes\Result.tscn`
- Create: `E:\10_创作\GDTaiko\scripts\ui\result_screen.gd`

- [x] **Step 1: Write gauge test**

Create:

```gdscript
extends SceneTree

const SoulGauge := preload("res://scripts/gameplay/soul_gauge.gd")

func _init() -> void:
	var gauge := SoulGauge.new()
	gauge.apply_judgment("perfect")
	gauge.apply_judgment("good")
	assert(gauge.value > 0.0)
	gauge.apply_judgment("miss")
	assert(gauge.value < 4.0)
	gauge.value = 80.0
	assert(gauge.is_clear())
	gauge.value = 79.9
	assert(not gauge.is_clear())
	quit(0)
```

- [x] **Step 2: Implement gauge**

```gdscript
extends RefCounted
class_name SoulGauge

var value := 0.0
var clear_threshold := 80.0

func reset() -> void:
	value = 0.0

func apply_judgment(judgment: String) -> void:
	match judgment:
		"perfect":
			value += 2.0
		"good":
			value += 1.2
		"bad":
			value -= 1.5
		"miss":
			value -= 3.0
	value = clamp(value, 0.0, 100.0)

func is_clear() -> bool:
	return value >= clear_threshold
```

- [x] **Step 3: Add result payload**

At song end, build:

```gdscript
{
	"score": scoring.score,
	"max_combo": scoring.max_combo,
	"perfects": scoring.perfects,
	"goods": scoring.goods,
	"bads": scoring.bads,
	"misses": scoring.misses,
	"gauge": soul_gauge.value,
	"clear": soul_gauge.is_clear(),
}
```

- [x] **Step 4: Run tests and manual result check**

Run:

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_soul_gauge.gd
godot --path E:\10_创作\GDTaiko
```

Expected: Gauge test passes; after the sample chart ends, result screen appears.

- [x] **Step 5: Commit**

```powershell
git add scripts/gameplay/soul_gauge.gd tests/gameplay/test_soul_gauge.gd scenes/Result.tscn scripts/ui/result_screen.gd scripts/gameplay/gameplay_controller.gd
git commit -m "feat: add soul gauge and result screen"
```

## 9. Phase 3: Song Library And OpenTaiko-Style Content Flow

Outcome: GDTaiko scans a songs folder, reads `.tja` metadata, presents courses, launches gameplay, and stores local results.

### Task 20: Define Song Folder Model

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\song\song_entry.gd`
- Create: `E:\10_创作\GDTaiko\scripts\song\song_course.gd`
- Create: `E:\10_创作\GDTaiko\tests\song\test_song_entry.gd`

- [ ] **Step 1: Create directories**

Run:

```powershell
New-Item -ItemType Directory -Force E:\10_创作\GDTaiko\scripts\song, E:\10_创作\GDTaiko\tests\song, E:\10_创作\GDTaiko\songs
```

- [ ] **Step 2: Add song model test**

Create:

```gdscript
extends SceneTree

const SongEntry := preload("res://scripts/song/song_entry.gd")
const SongCourse := preload("res://scripts/song/song_course.gd")

func _init() -> void:
	var song := SongEntry.new()
	song.title = "Song"
	song.folder_path = "res://songs/song"
	var course := SongCourse.new()
	course.course = "Oni"
	course.level = 7
	course.tja_path = "res://songs/song/chart.tja"
	song.courses.append(course)
	assert(song.best_course("Oni").level == 7)
	quit(0)
```

- [ ] **Step 3: Implement models**

`song_course.gd`:

```gdscript
extends RefCounted
class_name SongCourse

var course: String = ""
var level: int = 0
var tja_path: String = ""
var wave: String = ""
```

`song_entry.gd`:

```gdscript
extends RefCounted
class_name SongEntry

var title: String = ""
var subtitle: String = ""
var folder_path: String = ""
var preview_audio_path: String = ""
var courses: Array[SongCourse] = []

func best_course(course_name: String) -> SongCourse:
	for course in courses:
		if course.course.to_lower() == course_name.to_lower():
			return course
	return null
```

- [ ] **Step 4: Run test**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/song/test_song_entry.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add scripts/song/song_entry.gd scripts/song/song_course.gd tests/song/test_song_entry.gd
git commit -m "feat: add song library data model"
```

### Task 21: Scan Songs Folder

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\song\song_folder_scanner.gd`
- Create: `E:\10_创作\GDTaiko\tests\song\test_song_folder_scanner.gd`

- [ ] **Step 1: Write scanner test**

Test fixture creates a temporary `user://scan_test` folder with:

```text
sample/
  sample.tja
  sample.ogg
```

Test asserts:

```gdscript
var songs := SongFolderScanner.scan("user://scan_test")
assert(songs.size() == 1)
assert(songs[0].title == "Scanner Song")
assert(songs[0].courses.size() == 1)
assert(songs[0].courses[0].course == "Oni")
```

- [ ] **Step 2: Implement recursive scanner**

Behavior:

- Scan immediate child folders.
- Find `.tja` files in each folder.
- Parse metadata only using `TjaParser.parse_file`.
- Create one `SongEntry` per folder.
- Add one `SongCourse` per `.tja`.
- Use `WAVE` to resolve audio path relative to folder.
- Sort songs by title.

- [ ] **Step 3: Run scanner test**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/song/test_song_folder_scanner.gd
```

Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add scripts/song/song_folder_scanner.gd tests/song/test_song_folder_scanner.gd
git commit -m "feat: scan tja song folders"
```

### Task 22: Add Song Select Scene

**Files:**

- Create: `E:\10_创作\GDTaiko\scenes\SongSelect.tscn`
- Create: `E:\10_创作\GDTaiko\scripts\ui\song_select.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\app\main.gd`

- [ ] **Step 1: Implement song select controller**

Features:

- Scan `res://songs`.
- Render a vertical list of songs.
- Show title, subtitle, available courses, and selected level.
- Up/down changes song.
- Left/right changes course.
- Enter starts gameplay with selected course.

- [ ] **Step 2: Add launch payload**

Use autoload or a simple singleton `scripts/app/session_state.gd`:

```gdscript
extends Node
class_name SessionState

var selected_tja_path: String = ""
var selected_audio_path: String = ""
```

Register in `project.godot`:

```ini
[autoload]
SessionState="*res://scripts/app/session_state.gd"
```

- [ ] **Step 3: Modify gameplay controller**

If `SessionState.selected_tja_path` is not empty, load that chart instead of `assets/sample/sample.tja`.

- [ ] **Step 4: Manual check**

Run:

```powershell
godot --path E:\10_创作\GDTaiko
```

Expected:

- Starts at Song Select.
- Shows sample song.
- Enter launches gameplay.

- [ ] **Step 5: Commit**

```powershell
git add scenes/SongSelect.tscn scripts/ui/song_select.gd scripts/app/session_state.gd scripts/app/main.gd scripts/gameplay/gameplay_controller.gd project.godot
git commit -m "feat: add song select flow"
```

### Task 23: Add Local Score Storage

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\storage\score_store.gd`
- Create: `E:\10_创作\GDTaiko\tests\storage\test_score_store.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\ui\result_screen.gd`

- [ ] **Step 1: Create directories**

```powershell
New-Item -ItemType Directory -Force E:\10_创作\GDTaiko\scripts\storage, E:\10_创作\GDTaiko\tests\storage
```

- [ ] **Step 2: Write score store test**

Expected API:

```gdscript
var store := ScoreStore.new()
store.path = "user://test_scores.json"
store.save_result("song_hash", "Oni", {"score": 1000, "max_combo": 5, "clear": true})
var best := store.best_result("song_hash", "Oni")
assert(best["score"] == 1000)
store.save_result("song_hash", "Oni", {"score": 900, "max_combo": 9, "clear": true})
assert(store.best_result("song_hash", "Oni")["score"] == 1000)
```

- [ ] **Step 3: Implement JSON store**

Store shape:

```json
{
  "song_hash": {
    "Oni": {
      "score": 1000,
      "max_combo": 5,
      "clear": true,
      "played_at": "2026-06-13T00:00:00"
    }
  }
}
```

- [ ] **Step 4: Hook result screen**

On result display, save only if score beats previous best for song/course.

- [ ] **Step 5: Run tests**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/storage/test_score_store.gd
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add scripts/storage/score_store.gd tests/storage/test_score_store.gd scripts/ui/result_screen.gd
git commit -m "feat: persist local scores"
```

## 10. Phase 4: OpenTaiko And TJA Compatibility

Outcome: GDTaiko supports enough common `.tja` behavior to run real-world charts with predictable diagnostics.

### Task 24: Build Compatibility Fixture Suite

**Files:**

- Create: `E:\10_创作\GDTaiko\tests\fixtures\tja\`
- Create: `E:\10_创作\GDTaiko\tests\chart\test_tja_compatibility.gd`
- Create: `E:\10_创作\GDTaiko\docs\COMPATIBILITY_EVIDENCE.md`

- [ ] **Step 1: Create fixture files**

Create fixture `.tja` files for:

```text
basic_notes.tja
bpm_changes.tja
scroll_changes.tja
measure_changes.tja
roll_balloon.tja
gogo.tja
branch_basic.tja
metadata_variants.tja
unsupported_commands.tja
```

Each fixture must be original and minimal. Do not use copyrighted song charts.

- [ ] **Step 2: Add expected JSON sidecars**

For each fixture, create `.expected.json` with:

```json
{
  "title": "Fixture Name",
  "note_count": 4,
  "timing_event_count": 2,
  "warnings": []
}
```

- [ ] **Step 3: Write compatibility runner**

Test loads every fixture, parses it, and compares counts and warnings to expected sidecar.

- [ ] **Step 4: Record compatibility evidence**

Create or update `docs/COMPATIBILITY_EVIDENCE.md`. Each supported behavior must record:

- Behavior name.
- OpenTaiko repository URL.
- OpenTaiko commit or tag used for reference.
- Relevant file, function, issue, documentation page, or observed behavior.
- Original GDTaiko fixture path.
- Expected sidecar or test assertion path.
- Decision notes for intentional differences.

- [ ] **Step 5: Run compatibility tests**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_compatibility.gd
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add tests/fixtures/tja tests/chart/test_tja_compatibility.gd docs/COMPATIBILITY_EVIDENCE.md
git commit -m "test: add tja compatibility fixtures"
```

### Task 25: Support Metadata Variants

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\chart\tja_parser.gd`
- Modify: `E:\10_创作\GDTaiko\tests\fixtures\tja\metadata_variants.tja`
- Modify: `E:\10_创作\GDTaiko\tests\chart\test_tja_compatibility.gd`

- [ ] **Step 1: Extend metadata handling**

Support and store:

```text
TITLEJA
TITLEEN
SUBTITLEJA
SUBTITLEEN
DEMOSTART
GENRE
MAKER
LYRICFILE
SCOREINIT
SCOREDIFF
```

Add `metadata: Dictionary` to `TaikoChart`. Keep known fields as direct properties and also preserve all metadata in `metadata`.

- [ ] **Step 2: Test language fallback**

Expected:

- `TITLE` wins when present.
- `TITLEEN` may be used as fallback when `TITLE` is missing.
- Unknown metadata is preserved in `metadata` and does not crash parsing.

- [ ] **Step 3: Run compatibility tests**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_compatibility.gd
```

Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add scripts/chart/tja_parser.gd scripts/chart/taiko_chart.gd tests/fixtures/tja/metadata_variants.tja tests/chart/test_tja_compatibility.gd
git commit -m "feat: support common tja metadata variants"
```

### Task 26: Implement Branch Charts

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\chart\taiko_chart.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\chart\tja_parser.gd`
- Create: `E:\10_创作\GDTaiko\scripts\gameplay\branch_evaluator.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_branch_evaluator.gd`

- [ ] **Step 1: Add branch data model**

Represent branch notes as:

```gdscript
{
	"time_sec": 12.0,
	"type": "branch_start",
	"condition": "score",
	"normal_notes": [],
	"expert_notes": [],
	"master_notes": []
}
```

For first implementation, parse branch sections into separate arrays and choose one branch at runtime.

- [ ] **Step 2: Parse commands**

Support:

```text
#BRANCHSTART
#N
#E
#M
#BRANCHEND
```

If branch condition is unsupported, default to normal branch and add warning.

- [ ] **Step 3: Implement branch evaluator**

Inputs:

```gdscript
{
  "score_rate": 0.92,
  "roll_hits": 12,
  "accuracy": 0.88
}
```

Output:

```text
"normal" | "expert" | "master"
```

- [ ] **Step 4: Run tests**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_branch_evaluator.gd
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_compatibility.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add scripts/chart/taiko_chart.gd scripts/chart/tja_parser.gd scripts/gameplay/branch_evaluator.gd tests/gameplay/test_branch_evaluator.gd tests/fixtures/tja/branch_basic.tja
git commit -m "feat: add basic branch chart support"
```

### Task 27: Add Parser Diagnostics

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\chart\parse_diagnostic.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\chart\tja_tokenizer.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\chart\tja_parser.gd`
- Modify: `E:\10_创作\GDTaiko\tests\chart\test_tja_compatibility.gd`

- [ ] **Step 1: Add diagnostic model**

Fields:

```gdscript
var line_number: int
var severity: String
var code: String
var message: String
```

- [ ] **Step 2: Preserve line numbers in tokenizer**

Each token includes:

```gdscript
"line_number": line_number
```

- [ ] **Step 3: Replace plain warnings**

Use diagnostic codes:

```text
unsupported_command
unsupported_note
invalid_metadata
unterminated_long_note
branch_fallback
missing_audio
```

- [ ] **Step 4: Run compatibility tests**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/chart/test_tja_compatibility.gd
```

Expected: PASS and fixture sidecars assert diagnostic codes.

- [ ] **Step 5: Commit**

```powershell
git add scripts/chart/parse_diagnostic.gd scripts/chart/tja_tokenizer.gd scripts/chart/tja_parser.gd tests/chart/test_tja_compatibility.gd tests/fixtures/tja
git commit -m "feat: add tja parser diagnostics"
```

## 11. Phase 5: OpenTaiko-Style Presentation, Skinning, And UX

Outcome: GDTaiko feels like a complete Taiko game: configurable UI, original skin system, good feedback, song select, result screen, options, and stable 60fps.

## 11A. Phase 5A: Asset Audit And Import

Outcome: GDTaiko has real, usable skin/font/SFX resources where licenses allow redistribution, while music and song packs remain user-supplied and are not bundled by default.

Policy:

- Music and song packs are not bundled in the repository or release unless a specific track has a clear license allowing redistribution.
- The game supports user-local `.tja` + audio import.
- OpenTaiko skin, font, and sound resources may be used only after asset-level license review.
- Every imported resource must have source, author, license, redistribution permission, and release inclusion status recorded.
- Assets with unclear licenses may be used only as local developer references and must not enter release builds.

### Task A1: Create Asset Audit System

**Files:**

- Create: `E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md`
- Create: `E:\10_创作\GDTaiko\docs\ASSET_POLICY.md`
- Create: `E:\10_创作\GDTaiko\tools\asset_audit\validate_asset_audit.py`
- Create: `E:\10_创作\GDTaiko\tools\asset_audit\tests\test_validate_asset_audit.py`

- [ ] **Step 1: Write `docs\ASSET_POLICY.md`**

Create:

```markdown
# Asset Policy

## Music And Song Packs

Music and song packs are not bundled by default. GDTaiko supports user-local import of `.tja` charts and audio files. A music file can enter the repository or release only when its license explicitly allows redistribution.

## Skin, Font, And SFX Assets

Skin, font, and sound-effect assets can be imported from OpenTaiko-related repositories only after asset-level license review.

Allowed for release:

- Original GDTaiko assets.
- Assets with clear MIT, CC0, CC-BY, or another compatible redistribution license.
- Assets whose license allows modification and redistribution in a game package.

Not allowed for release:

- Assets with unknown license.
- Assets copied from commercial Taiko games.
- Assets whose license allows personal use only.
- Assets that require attribution if attribution is not included in `NOTICE.md`.

## Permission Levels

- `local_reference`: may exist only outside release assets; useful for comparison.
- `repo_allowed`: may be committed to the repository.
- `release_allowed`: may be bundled in exported builds.
- `blocked`: must not be committed or distributed.
```

- [ ] **Step 2: Write `docs\ASSET_AUDIT.md`**

Create:

```markdown
# Asset Audit

| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gdtaiko-note-don | assets/notes/note_don.png | skin | original | GDTaiko | MIT | yes | yes | release_allowed | yes | yes | Original placeholder asset. |
| gdtaiko-note-ka | assets/notes/note_ka.png | skin | original | GDTaiko | MIT | yes | yes | release_allowed | yes | yes | Original placeholder asset. |
| gdtaiko-don-sfx | assets/sfx/don.wav | sfx | original | GDTaiko | MIT | yes | yes | release_allowed | yes | yes | Original placeholder SFX. |
| gdtaiko-ka-sfx | assets/sfx/ka.wav | sfx | original | GDTaiko | MIT | yes | yes | release_allowed | yes | yes | Original placeholder SFX. |
```

- [ ] **Step 3: Write failing audit validator test**

Create `tools\asset_audit\tests\test_validate_asset_audit.py`:

```python
from pathlib import Path

from validate_asset_audit import parse_table, validate_rows


def test_valid_rows_pass():
    text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | original | me | MIT | yes | yes | release_allowed | yes | yes | ok |
"""
    rows = parse_table(text)
    assert validate_rows(rows) == []


def test_release_asset_requires_clear_license():
    text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | unknown | unknown | unknown | unknown | unknown | release_allowed | yes | yes | bad |
"""
    rows = parse_table(text)
    errors = validate_rows(rows)
    assert any("clear license" in error for error in errors)
```

- [ ] **Step 4: Implement validator**

Create `tools\asset_audit\validate_asset_audit.py`:

```python
from __future__ import annotations

import sys
from pathlib import Path


REQUIRED_HEADERS = [
    "Asset ID",
    "Path",
    "Type",
    "Source",
    "Author",
    "License",
    "Redistribution",
    "Commercial Use",
    "Status",
    "Include In Repo",
    "Include In Release",
    "Notes",
]

CLEAR_LICENSES = {"MIT", "CC0", "CC-BY", "CC-BY-SA", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause"}


def parse_table(text: str) -> list[dict[str, str]]:
    lines = [line.strip() for line in text.splitlines() if line.strip().startswith("|")]
    if len(lines) < 3:
        return []
    headers = [part.strip() for part in lines[0].strip("|").split("|")]
    rows = []
    for line in lines[2:]:
        values = [part.strip() for part in line.strip("|").split("|")]
        if len(values) != len(headers):
            continue
        rows.append(dict(zip(headers, values)))
    return rows


def validate_rows(rows: list[dict[str, str]]) -> list[str]:
    errors: list[str] = []
    seen_ids: set[str] = set()
    for index, row in enumerate(rows, start=1):
        for header in REQUIRED_HEADERS:
            if header not in row or row[header] == "":
                errors.append(f"row {index}: missing {header}")
        asset_id = row.get("Asset ID", "")
        if asset_id in seen_ids:
            errors.append(f"row {index}: duplicate asset id {asset_id}")
        seen_ids.add(asset_id)
        include_release = row.get("Include In Release", "").lower() == "yes"
        status = row.get("Status", "")
        license_name = row.get("License", "")
        redistribution = row.get("Redistribution", "").lower()
        if include_release or status == "release_allowed":
            if license_name not in CLEAR_LICENSES:
                errors.append(f"row {index}: release asset requires clear license")
            if redistribution != "yes":
                errors.append(f"row {index}: release asset requires redistribution=yes")
    return errors


def main(argv: list[str] | None = None) -> int:
    args = argv or sys.argv[1:]
    path = Path(args[0]) if args else Path("docs/ASSET_AUDIT.md")
    errors = validate_rows(parse_table(path.read_text(encoding="utf-8")))
    for error in errors:
        print(error)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 5: Run validator tests**

Run:

```powershell
cd E:\10_创作\GDTaiko\tools\asset_audit
python -m unittest discover tests
python validate_asset_audit.py E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md
```

Expected: Tests pass and audit validation exits 0.

- [ ] **Step 6: Commit**

```powershell
git add docs/ASSET_POLICY.md docs/ASSET_AUDIT.md tools/asset_audit/validate_asset_audit.py tools/asset_audit/tests/test_validate_asset_audit.py
git commit -m "docs: add asset audit system"
```

### Task A2: Audit OpenTaiko Skin, Font, And SFX Sources

**Files:**

- Modify: `E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md`
- Modify: `E:\10_创作\GDTaiko\NOTICE.md`
- Create: `E:\10_创作\GDTaiko\docs\OPEN_TAIKO_ASSET_SOURCES.md`

- [ ] **Step 1: Record candidate sources**

Create `docs\OPEN_TAIKO_ASSET_SOURCES.md`:

```markdown
# OpenTaiko Asset Sources

This document tracks candidate skin, font, and sound-effect sources before import.

## Candidate Repositories

| Source | URL | Asset Types | License Location | Notes |
| --- | --- | --- | --- | --- |
| OpenTaiko main | https://github.com/0auBSQ/OpenTaiko | code, bundled minimum assets, licenses | `LICENSE`, `OpenTaiko/Licenses/` | Code is MIT; assets require per-file review. |
| OpenTaiko-Skins | https://github.com/OpenTaiko/OpenTaiko-Skins | skins, global assets | repository files and README | Must inspect asset and license files before import. |
| OpenTaiko-Soundtrack | https://github.com/OpenTaiko/OpenTaiko-Soundtrack | songs | repository files and README | Default policy: do not bundle music. |
```

- [ ] **Step 2: Audit skin assets**

For each candidate skin asset:

- record exact path
- record source repository URL
- record author if available
- record license file or README statement
- classify status as `release_allowed`, `repo_allowed`, `local_reference`, or `blocked`

- [ ] **Step 3: Audit fonts**

For each font:

- record font name
- record upstream font license
- confirm whether embedding in a game release is allowed
- record attribution text required in `NOTICE.md`

- [ ] **Step 4: Audit sound effects**

For each SFX:

- record original source
- record license
- confirm redistribution and modification rights
- record whether attribution is required

- [ ] **Step 5: Validate audit**

Run:

```powershell
python E:\10_创作\GDTaiko\tools\asset_audit\validate_asset_audit.py E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md
```

Expected: Exit 0. If assets are not clear enough for release, mark `Include In Release` as `no`.

- [ ] **Step 6: Commit**

```powershell
git add docs/ASSET_AUDIT.md docs/OPEN_TAIKO_ASSET_SOURCES.md NOTICE.md
git commit -m "docs: audit OpenTaiko skin font and sfx sources"
```

### Task A3: Import Approved Skin, Font, And SFX Asset Pack

**Files:**

- Create: `E:\10_创作\GDTaiko\assets\skins\opentaiko_approved\`
- Create: `E:\10_创作\GDTaiko\assets\fonts\`
- Create: `E:\10_创作\GDTaiko\assets\sfx\opentaiko_approved\`
- Modify: `E:\10_创作\GDTaiko\themes\default\theme.json`
- Modify: `E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md`

- [ ] **Step 1: Create approved asset directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  E:\10_创作\GDTaiko\assets\skins\opentaiko_approved, `
  E:\10_创作\GDTaiko\assets\fonts, `
  E:\10_创作\GDTaiko\assets\sfx\opentaiko_approved
```

- [ ] **Step 2: Copy only approved assets**

Only copy rows from `ASSET_AUDIT.md` where:

```text
Status = release_allowed
Include In Repo = yes
Include In Release = yes
```

Do not copy music, `.tja`, or song package audio in this task.

- [ ] **Step 3: Update theme paths**

Update `themes/default/theme.json` to point to imported assets:

```json
{
  "name": "Default",
  "note_don": "res://assets/skins/opentaiko_approved/note_don.png",
  "note_ka": "res://assets/skins/opentaiko_approved/note_ka.png",
  "sfx_don": "res://assets/sfx/opentaiko_approved/don.wav",
  "sfx_ka": "res://assets/sfx/opentaiko_approved/ka.wav",
  "font_main": "res://assets/fonts/main.ttf",
  "lane_color": "#1b1b1b",
  "gogo_color": "#f5a623"
}
```

- [ ] **Step 4: Validate audit and theme**

Run:

```powershell
python E:\10_创作\GDTaiko\tools\asset_audit\validate_asset_audit.py E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md
godot --headless --path E:\10_创作\GDTaiko -s res://tests/theme/test_taiko_theme.gd
```

Expected: Audit validator exits 0; theme test passes.

- [ ] **Step 5: Manual visual/audio check**

Run:

```powershell
godot --path E:\10_创作\GDTaiko
```

Expected:

- Approved note skins appear.
- Approved SFX play on Don/Ka.
- Approved font displays HUD and song select text.
- No music from OpenTaiko or third-party song packs is bundled.

- [ ] **Step 6: Commit**

```powershell
git add assets/skins/opentaiko_approved assets/fonts assets/sfx/opentaiko_approved themes/default/theme.json docs/ASSET_AUDIT.md
git commit -m "assets: import approved skin font and sfx pack"
```

### Task A4: Add User-Local Music And Song Import Flow

**Files:**

- Create: `E:\10_创作\GDTaiko\docs\USER_SONG_IMPORT.md`
- Modify: `E:\10_创作\GDTaiko\scripts\song\song_folder_scanner.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\ui\song_select.gd`

- [ ] **Step 1: Document user-local import**

Create `docs\USER_SONG_IMPORT.md`:

```markdown
# User Song Import

GDTaiko does not bundle music by default. Users can place their own `.tja` charts and matching audio files in:

```text
user://songs/
```

Recommended folder:

```text
user://songs/My Song/
  chart.tja
  song.ogg
```

The `.tja` `WAVE:` field should point to the audio file in the same folder.
```

- [ ] **Step 2: Scan `user://songs` in addition to `res://songs`**

Update scanner call:

```gdscript
var songs := []
songs.append_array(SongFolderScanner.scan("res://songs"))
songs.append_array(SongFolderScanner.scan("user://songs"))
```

- [ ] **Step 3: Add missing-audio diagnostics in UI**

If a chart exists but the `WAVE` file is missing:

- show song in list
- mark it as `Missing audio`
- prevent gameplay launch
- show path expected

- [ ] **Step 4: Manual import check**

Create a local test folder under `user://songs` and verify it appears in song select without adding music to git.

- [ ] **Step 5: Commit**

```powershell
git add docs/USER_SONG_IMPORT.md scripts/song/song_folder_scanner.gd scripts/ui/song_select.gd
git commit -m "feat: add user-local song import flow"
```

### Task 28: Define Theme Resource Format

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\theme\taiko_theme.gd`
- Create: `E:\10_创作\GDTaiko\themes\default\theme.json`
- Create: `E:\10_创作\GDTaiko\tests\theme\test_taiko_theme.gd`

- [ ] **Step 1: Create directories**

```powershell
New-Item -ItemType Directory -Force E:\10_创作\GDTaiko\scripts\theme, E:\10_创作\GDTaiko\tests\theme, E:\10_创作\GDTaiko\themes\default
```

- [ ] **Step 2: Define theme JSON**

```json
{
  "name": "Default",
  "note_don": "res://assets/notes/note_don.png",
  "note_ka": "res://assets/notes/note_ka.png",
  "sfx_don": "res://assets/sfx/don.wav",
  "sfx_ka": "res://assets/sfx/ka.wav",
  "lane_color": "#1b1b1b",
  "gogo_color": "#f5a623"
}
```

- [ ] **Step 3: Implement theme loader**

Load JSON, validate required keys, resolve resource paths, expose typed getters.

- [ ] **Step 4: Run theme test**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/theme/test_taiko_theme.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add scripts/theme/taiko_theme.gd themes/default/theme.json tests/theme/test_taiko_theme.gd
git commit -m "feat: add taiko theme resource format"
```

### Task 29: Add Original Skin Rendering

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\note_lane.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\gameplay_controller.gd`
- Create: `E:\10_创作\GDTaiko\scripts\gameplay\hit_effects.gd`

- [ ] **Step 1: Add lane background and target**

In `note_lane.gd`, create:

- lane background band
- target circle
- timing line
- GOGO color overlay

- [ ] **Step 2: Add hit effects**

`hit_effects.gd` exposes:

```gdscript
func spawn_hit(position: Vector2, judgment: String) -> void
func spawn_miss(position: Vector2) -> void
```

Use simple Godot primitives first: circles, scale tweens, alpha fade.

- [ ] **Step 3: Wire effects to controller**

On `perfect`, `good`, `bad`, and `miss`, spawn distinct effects.

- [ ] **Step 4: Manual visual check**

Run:

```powershell
godot --path E:\10_创作\GDTaiko
```

Expected: Notes, target, hit effects, and GOGO state are visible and do not overlap HUD.

- [ ] **Step 5: Commit**

```powershell
git add scripts/gameplay/note_lane.gd scripts/gameplay/gameplay_controller.gd scripts/gameplay/hit_effects.gd
git commit -m "feat: add original gameplay skin rendering"
```

### Task 30: Add Input Configuration

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\config\game_config.gd`
- Create: `E:\10_创作\GDTaiko\scenes\Options.tscn`
- Create: `E:\10_创作\GDTaiko\scripts\ui\options_menu.gd`

- [ ] **Step 1: Create config model**

Fields:

```gdscript
var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var chart_offset_ms := 0
var input_offset_ms := 0
var don_keys := [KEY_F]
var ka_keys := [KEY_J]
var fullscreen := false
```

- [ ] **Step 2: Persist config to `user://config.json`**

Add:

```gdscript
func load_config() -> void
func save_config() -> void
func apply_to_project() -> void
```

- [ ] **Step 3: Build options scene**

Options UI includes:

- chart offset stepper
- input offset stepper
- volume sliders
- fullscreen toggle
- key binding buttons

- [ ] **Step 4: Manual check**

Run:

```powershell
godot --path E:\10_创作\GDTaiko
```

Expected: Options can be changed, saved, and applied after restart.

- [ ] **Step 5: Commit**

```powershell
git add scripts/config/game_config.gd scenes/Options.tscn scripts/ui/options_menu.gd
git commit -m "feat: add configurable options"
```

### Task 31: Add Audio Preview And Song Metadata UX

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\ui\song_select.gd`
- Modify: `E:\10_创作\GDTaiko\scripts\song\song_entry.gd`

- [ ] **Step 1: Support `DEMOSTART`**

Song scanner stores preview start:

```gdscript
song.preview_start_sec = chart.metadata.get("DEMOSTART", "0").to_float()
```

- [ ] **Step 2: Add preview player**

When selected song changes:

- stop previous preview
- load selected audio
- seek to `preview_start_sec`
- fade in preview volume over 0.25 sec

- [ ] **Step 3: Display metadata**

Song select displays:

- title
- subtitle
- genre
- maker
- course list
- best score
- clear marker

- [ ] **Step 4: Manual check**

Expected: Moving selection changes visible metadata and preview audio.

- [ ] **Step 5: Commit**

```powershell
git add scripts/ui/song_select.gd scripts/song/song_entry.gd scripts/song/song_folder_scanner.gd
git commit -m "feat: add song preview and metadata display"
```

### Task 32: Add Replay Recording

**Files:**

- Create: `E:\10_创作\GDTaiko\scripts\replay\replay_recorder.gd`
- Create: `E:\10_创作\GDTaiko\scripts\replay\replay_player.gd`
- Create: `E:\10_创作\GDTaiko\tests\replay\test_replay_roundtrip.gd`

- [ ] **Step 1: Define replay schema**

```json
{
  "version": 1,
  "chart_hash": "abc",
  "course": "Oni",
  "offset_ms": 0,
  "inputs": [
    {"time_sec": 1.234, "lane": "don"}
  ],
  "result": {
    "score": 1000,
    "max_combo": 1
  }
}
```

- [ ] **Step 2: Record inputs**

Every player hit records song time and lane.

- [ ] **Step 3: Playback replay**

Replay player injects hits into gameplay controller at recorded times.

- [ ] **Step 4: Roundtrip test**

Save replay, load replay, assert input count and lanes match.

- [ ] **Step 5: Commit**

```powershell
git add scripts/replay/replay_recorder.gd scripts/replay/replay_player.gd tests/replay/test_replay_roundtrip.gd scripts/gameplay/gameplay_controller.gd
git commit -m "feat: add replay recording and playback"
```

## 12. Phase 6: Polish, Performance, And Release

Outcome: GDTaiko can be distributed as a stable playable build.

### Task 33: Add Performance Budget

**Files:**

- Create: `E:\10_创作\GDTaiko\docs\PERFORMANCE_BUDGET.md`
- Create: `E:\10_创作\GDTaiko\scripts\debug\frame_monitor.gd`

- [ ] **Step 1: Define budget**

`docs/PERFORMANCE_BUDGET.md`:

```markdown
# Performance Budget

- Target FPS: 60 stable.
- Gameplay frame time: under 16.67 ms.
- Input-to-judgment path: no allocations in hot path after chart load.
- Note node count: pool notes; do not create/free nodes every frame.
- Audio clock: use audio playback position during normal play.
```

- [ ] **Step 2: Add frame monitor**

Displays:

- FPS
- frame time
- active notes
- missed frames count

- [ ] **Step 3: Manual check**

Run a dense fixture and verify stable 60fps.

- [ ] **Step 4: Commit**

```powershell
git add docs/PERFORMANCE_BUDGET.md scripts/debug/frame_monitor.gd
git commit -m "docs: define performance budget"
```

### Task 34: Add Note Pooling

**Files:**

- Modify: `E:\10_创作\GDTaiko\scripts\gameplay\note_lane.gd`
- Create: `E:\10_创作\GDTaiko\tests\gameplay\test_note_pool.gd`

- [ ] **Step 1: Write pool test**

Assert:

- Spawning 100 notes creates 100 sprites.
- Clearing returns sprites to pool.
- Spawning another 100 notes reuses existing sprites.

- [ ] **Step 2: Implement pool**

Maintain:

```gdscript
var active_sprites: Dictionary = {}
var pooled_sprites: Array[Sprite2D] = []
```

Use `visible=false` instead of `queue_free`.

- [ ] **Step 3: Run test**

```powershell
godot --headless --path E:\10_创作\GDTaiko -s res://tests/gameplay/test_note_pool.gd
```

Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add scripts/gameplay/note_lane.gd tests/gameplay/test_note_pool.gd
git commit -m "perf: pool note sprites"
```

### Task 35: Add Export Presets

**Files:**

- Create: `E:\10_创作\GDTaiko\export_presets.cfg`
- Create: `E:\10_创作\GDTaiko\docs\RELEASE.md`

- [ ] **Step 1: Add Windows export preset**

Configure:

- target: Windows Desktop
- architecture: x86_64
- export path: `builds/windows/GDTaiko.exe`

- [ ] **Step 2: Add release instructions**

`docs/RELEASE.md` includes:

```powershell
godot --headless --path E:\10_创作\GDTaiko --export-release "Windows Desktop" builds\windows\GDTaiko.exe
```

- [ ] **Step 3: Test export**

Run the export command and launch build.

- [ ] **Step 4: Commit**

```powershell
git add export_presets.cfg docs/RELEASE.md
git commit -m "build: add windows export preset"
```

### Task 36: Add License And Asset Policy

**Files:**

- Create: `E:\10_创作\GDTaiko\LICENSE`
- Create: `E:\10_创作\GDTaiko\NOTICE.md`
- Modify: `E:\10_创作\GDTaiko\docs\ASSET_POLICY.md`
- Modify: `E:\10_创作\GDTaiko\docs\ASSET_AUDIT.md`

- [ ] **Step 1: Choose project code license**

Use MIT if compatible with project goals:

```text
MIT License

Copyright (c) 2026
```

- [ ] **Step 2: Finalize asset policy**

Rules:

- Music and song packs are user-local by default and are not bundled unless explicitly licensed for redistribution.
- OpenTaiko code is MIT and may be referenced or ported with notice.
- OpenTaiko-related skins, fonts, and SFX may be included only when `docs/ASSET_AUDIT.md` marks them `release_allowed`.
- MIT/CC0/CC-BY-compatible assets are allowed when attribution and license text are included.
- Assets with unclear license remain `local_reference` or `blocked`.
- Commercial Taiko assets are not allowed.

- [ ] **Step 3: Add NOTICE**

Mention OpenTaiko as behavioral reference and MIT-licensed source inspiration without bundling its assets.

- [ ] **Step 4: Commit**

```powershell
git add LICENSE NOTICE.md docs/ASSET_POLICY.md
git commit -m "docs: add license and asset policy"
```

## 13. Final Compatibility Matrix

Track this table in `docs/COMPATIBILITY_MATRIX.md`.

| Area | Target | Phase |
| --- | --- | --- |
| `TITLE`, `SUBTITLE`, `BPM`, `OFFSET`, `WAVE`, `COURSE`, `LEVEL` | Full support | Phase 1 |
| Don/Ka `1`/`2` | Full support | Phase 1 |
| Roll `5`/`6`/`8` | Full support | Phase 2 |
| Balloon `7`/`8` + `BALLOON` | Full support | Phase 2 |
| `#GOGOSTART`, `#GOGOEND` | Full support | Phase 2 |
| `#BPMCHANGE` | Full support | Phase 2 |
| `#SCROLL` | Full support | Phase 2 |
| `#MEASURE` | Full support | Phase 2 |
| Song folder scanning | Full support | Phase 3 |
| Multi-course song select | Full support | Phase 3 |
| Local best scores | Full support | Phase 3 |
| Branching | Basic support first, expand by fixtures | Phase 4 |
| Metadata variants | Common fields preserved | Phase 4 |
| Parser diagnostics | Full support | Phase 4 |
| Skin/theme system | Original compatible architecture | Phase 5 |
| Asset audit | Skin/font/SFX audit, import, and release gate | Phase 5A |
| User music import | User-local `.tja` and audio folders, no bundled music by default | Phase 5A |
| Replay | Local replay support | Phase 5 |
| Export builds | Windows first | Phase 6 |

## 14. Definition Of "Perfect Recreation"

For this project, "perfect recreation" means functional parity with the core player experience, not copying protected assets or preserving OpenTaiko's internal architecture.

Required before calling GDTaiko a full recreation:

- Real `.tja` song folders can be scanned and selected.
- Common `.tja` charts parse without manual editing.
- Don, Ka, roll, balloon, GOGO, BPM, SCROLL, MEASURE, and common branching work.
- Judgment, score, combo, gauge, result, and local scores are stable.
- Offset settings allow chart/audio/input calibration.
- Theme system can reproduce Taiko-style UI using original or audited OpenTaiko-compatible skin/font/SFX assets.
- Music and song packs are user-local by default, with no unlicensed music bundled in the repository or release.
- `docs/ASSET_AUDIT.md` proves every bundled skin, font, and SFX asset has a clear source, author, license, redistribution status, and release decision.
- The game holds stable 60fps on dense charts.
- Compatibility fixtures cover every supported `.tja` command.
- Unsupported commands produce clear diagnostics instead of silent bad charts.

Non-goals even for a "perfect" GDTaiko:

- Copying commercial Taiko UI, art, sounds, songs, or fonts without a verified license.
- Blindly porting every OpenTaiko C# class.
- Depending on OpenTaiko runtime libraries.

## 15. Self-Review Checklist

- Every Phase 1 subsystem has a task.
- Later phases are expanded into concrete work, not only summaries.
- Parser behavior is defined before gameplay consumes it.
- Tests exist for parser, judge, scoring, song scanning, storage, compatibility, theme loading, and replay.
- Gameplay scene is delayed until data and rules exist.
- OpenTaiko compatibility is fixture-driven.
- No task requires copying commercial assets.
- No direct C# to GDScript translation is assumed.
