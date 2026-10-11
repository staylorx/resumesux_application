# ResumesUX TUI Gap Analysis

## 1. Current stack (what actually exists)

There is **no TUI** in this repository. The closest thing to a "UI" is a
one-shot, batch, text-to-stdout CLI. Concretely:

| Concern | Current state |
|---|---|
| Framework / library | None (no tview, Bubble Tea, termui, curses, or Dart terminal widget lib) |
| Entry points | `bin/resumesux.dart` (single AI inference, prints result, exits); `tool/fitness/run_fitness.dart` (batch persona×job matrix, prints a report at the end) |
| Rendering loop | None — a sequential `main()` that writes `stdout.writeln(...)` once and returns |
| Layout | None — flat lines of text, no header/main/status/command regions, no pane split, no resize handling |
| Styling / theme | None — zero ANSI color, no borders, no focus or selection highlighting |
| Input handling | `ArgParser` parses args **once** at startup; no live keyboard, no focus model, no keymaps |
| State management | None — plain `Future<void> main()`; no view state, no controller, no navigation stack |
| Async UI | `GenerateApplicationUsecase` exposes a bare `void Function(String) progress` callback — a UI-effect channel threaded through the core (already flagged in `BACKLOG.md`); nothing renders it |
| Mouse | None |

The dependency surface confirms it: `pubspec.yaml` has **no** terminal/UI
package — only `fpdart`, `args`, `dotenv`, `http`, `yaml`, and the domain git
dep. The repo is a clean clean-architecture back end (domain / application /
infrastructure) with a CLI shim bolted on. There is no presentation ring.

## 2. The kernel of the question: "do I not understand what a TUI is?"

You do — and your hunch is correct. A **TUI** is a *full-screen interactive
terminal application*: it enters raw mode, owns the whole screen, runs a
render loop, dispatches keystrokes/mouse to a focused widget, redraws only
the dirty regions, and holds a navigation/state model. k9s is a TUI.

This repo has never had one. It ships a *batch script that prints text* —
which is the class of tool that "looks sad and provincial" **regardless of
styling**, because there is no canvas, no layout, no theme, no input, and no
update path to make graceful. You are not missing a styling trick; you are
missing an entire application category. That is good news: the polish problem
is not a retrofit problem, it is a greenfield build, and this repo's data +
use-case layer is already a clean seam to build a TUI on.

## 3. Concrete gaps vs k9s (≥8)

1. **No render loop / screen buffer.** Nothing enters raw mode, owns the
   terminal, or redraws. Output is write-once. k9s renders continuously and
   diffs.
2. **No layout system.** No header / main split / status bar / command bar
   regions; no responsive panes that reflow on `SIGWINCH`/resize. k9s panes
   are a live grid.
3. **No component reuse.** No `Table`, `List`, `DetailView`, `Modal`, `Help`,
   `CommandPalette`, `StatusBar`, or `Spinner` widgets. Every present output
   is a hand-built `stdout.writeln` dump with no shared widget vocabulary.
4. **No theme / styling.** No color tokens, no borders, no selection or focus
   highlight. k9s ships a full theme system (custom palettes, selection
   colors, heading bars).
5. **No input model.** CLI args parsed once; no keyboard navigation, no focus
   state, no keymap, no command palette (`:` in k9s). All interactivity is
   absent.
6. **No state management.** No per-screen controller, no navigation stack,
   no app-level view state. k9s keeps view state per resource + a focused-view
   stack.
7. **No mouse support.** k9s supports hover/click on table rows and pane
   focus. Nothing here reads pointer input.
8. **No performance model.** No dirty-region diffing, no row virtualization.
   Any future table would re-render everything on every keystroke (or, today,
   simply never updates live).
9. **No accessibility.** No color-independent indicators (k9s pairs color with
   bold/underline/icons), no configurable keymap, no screen-reader-friendly
   focus tracking.
10. **No loading / progress / error UI.** The only async seam —
    `void Function(String) progress` in `GenerateApplicationUsecase` — is a
    bare string callback; there is no spinner, per-step status, or error modal.
11. **Poor async-UI seam.** That progress callback is a UI-effect channel
    threaded *through the application core*, which `BACKLOG.md` already flags
    as a doctrine deviation. A TUI needs the core to expose a stream of
    states, not a void callback into the middle of it.

## 4. Recommended target architecture

New top-level **`resumesux_tui`** package = the presentation ring. It depends
inward on `resumesux_application` (the existing use cases) and thus on
`resumesux_domain`. No domain/application code changes except (a) replacing
the `void Function(String)` progress callback with a `Stream<TuiProgress>`
or a small state object returned by a use case, and (b) adding the missing
adapter ring `BACKLOG.md` calls out.

### 4.1 Libraries

- **Terminal binding + raw input:** `dart_console` for raw mode, ANSI output,
  and synchronous key reads; pair it with `dart_termlib` (or `ansicolor`) for
  capability detection (256-color / truecolor, live resize via `SIGWINCH`).
  This is the tcell analogue in k9s (tview sits on tcell).
- **Widget layer:** a thin, in-repo tview-style widget tree (Table, List,
  Box/Frame, Detail, Modal, StatusBar) built on that console base, with a
  dirty-rect diff renderer and row virtualization. Treat `moxi_tui` as a
  candidate if its API fits the component shape; otherwise own the ~1k-line
  widget layer — it is small and gives full control over "grace and detail."
  Do **not** reach for a Flutter/GUI framework; the ask is a TUI.
- **State:** lightweight unidirectional store (fpdart `TaskEither` is already
  the error style). Per-collection `Store` + per-screen `Controller`, a
  focused-view navigation stack, and a `CommandBus` for keymap + command
  palette. No heavy state library.

### 4.2 Component boundaries (packages / directories)

```
lib/src/
  app/app.dart            # root: owns run loop (render + input + resize)
  app/theme.dart          # color tokens, palettes, per-widget styles
  layout/shell.dart       # header / main split / status bar / command bar grid
  layout/pane.dart        # responsive split, focus + resize handling
  widgets/table.dart      # virtualized, sortable, selectable table
  widgets/list.dart
  widgets/detail.dart     # right-hand detail pane (k9s info view)
  widgets/frame.dart      # bordered box with title bar
  widgets/modal.dart, help.dart, command_palette.dart, status_bar.dart,
          spinner.dart
  controller/<screen>.dart  # one Controller per domain view
                           # (Applicants, JobReqs, Applications, Gigs, Assets)
  store/store.dart        # per-collection store, ChangeNotifier/Stream
  command/keys.dart, command/bus.dart   # keymap + `:` command palette
  bindings/<adapter>.dart # wires use cases in at the outer ring (the
                          # missing adapter seam), exposing states as streams
```

### 4.3 The screen

```
┌ RESUMESUX ─ applicants(12) ───────── JobReq: RN-Pediatric ─────────────┐
│  NAME        STATUS   SCORE  UPDATED        │  POSITION  RN Pediatric   │
│  Jane Doe    matched  0.92   10m ago        │  FIT       0.92  strong   │
│  John Roe    pending  0.61   1h  ago        │  RESUME    ·····░░░  9/12  │
│  ...                                        │  COVER ·    8/10           │
├──────────────────────────────┬─────────────┴───────────────────────────┤
│  :  gen resume 			   │   logs / errors   │
├──────────────────────────────┴─────────────────────────────────────────┤
│  STATUS  ● ready      CTRL-K help   : cmd    ⌥+1..4 panes             │
└─────────────────────────────────────────────────────────────────────────┘
```

## 5. Sequencing

1. (this task) audit + architecture — done.
2. `t_1d623f92` — full design spec (palette, spacing, borders, components,
   keymap, mouse, loading/error states, wireframes).
3. Scaffold `resumesux_tui` package; wire theme + shell + one table view
   (Applicants) end-to-end through a real use case as the vertical slice.
4. Add remaining screens, command palette, mouse, virtualization.
