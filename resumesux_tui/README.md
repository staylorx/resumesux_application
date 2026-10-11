# ResumesUX TUI

A k9s-style, full-screen, raw-mode terminal UI for ResumesUX — the
presentation ring of the clean-architecture stack. It depends inward on
`resumesux_application` -> `resumesux_domain`.

This is a *TUI*: it enters raw mode, owns the whole terminal (alternate
screen), runs a render loop with dirty-cell diffing, and dispatches
keystrokes to a focused widget. It is not a batch print-to-stdout script.

## Run

```sh
dart pub get
dart run bin/resumesux_tui.dart --demo
```

`--demo` launches the shell with seed rows on every screen (Applicants,
JobReqs, Applications, Gigs, Assets) and no network, so the whole layout and
interaction layer is explorable with just a terminal.

Extra demo flags:

```sh
dart run bin/resumesux_tui.dart --demo --state=empty   # every view shows its empty state
dart run bin/resumesux_tui.dart --demo --state=error   # every view shows a soft pane error
dart run bin/resumesux_tui.dart --demo --theme=light   # switch to the light theme
```

## Controls (v1)

| Key | Action |
|---|---|
| `↑`/`k` `↓`/`j` | move cursor in table / command palette match list |
| `PgUp`/`PgDn` | page up / down |
| `Home`/`g` `End`/`G` | first / last row |
| `Tab` / `Shift+Tab` | next / previous pane |
| `Enter` | confirm / open + focus detail |
| `Esc` | back / close modal / close command bar / leave help / clear filter |
| `:` | open command palette (fuzzy) |
| `/` | filter/search current view (live) |
| `s` | cycle sort on the first column (none → asc → desc) |
| `r` | refresh / retry current view |
| `c` | (stub) generate for selected |
| `d` | delete selected (confirmation modal) |
| `?` | open help |
| `q` / `Ctrl+C` | quit |

Command palette commands: `applicants`, `jobreqs`, `applications`, `gigs`,
`assets`, `generate`, `filter <q>`, `sort <asc|desc|none>`, `help`, `quit`,
`theme <k9s|light>`, `clear`. j/k (or Ctrl+Up/Down) move the highlight;
Enter runs the highlighted command.

## Views & states

Each screen (Applicants, JobReqs, Applications, Gigs, Assets) renders as a
table + detail split. Four view states are handled per pane:

- **Loading** — a centered spinner + `loading <view>…` while data is fetched;
  the table keeps its frame and header.
- **Empty** — a glyph + `no <view> yet` with a `press a to add` hint.
- **Error** — a `!` + message + `press r to retry` hint; the pane border
  turns `status.err`.
- **Loaded** — rows, filtered/sorted per the current `/` filter and `s` sort.

The `/` filter matches across all row cells (case-insensitive) and live-filters
the displayed rows; `Esc` clears it and returns to the pane. `s` reorders rows
by the first column (asc/desc) and back. The header and status-bar counts
reflect the *filtered* set. Clicking rows, scrolling with the wheel, and
drag/tab focus movement all work per the mouse model (§9.4 of the spec).

## Layout

```
┌ RESUMESUX · APPLICANTS / MATCHED (12) ───────────────────── generating… ┐
├─ APPLICANTS ──────────┤ ├─ DETAIL · JANE DOE ────────────────────────────┤
│  NAME     STATUS SCORE │ │  NAME      Jane Doe                            │
│  Jane Doe matched ▓0.92▓│ │  PREFRED   Jay                                │
│  …                      │ │  EMAIL     jane@x.com                         │
│                         │ └──────────────────────────────────────────────┤
├────────────────────────┴────────────────────────────────────────────────┤
│ ● ready  c generate · ⌥D detail · ? help · : cmd · q quit   12 · score │
└──────────────────────────────────────────────────────────────────────────┘
```

Header (title, breadcrumb, counts), a horizontal table | detail split with a
1-cell gutter, a command bar that overlays the status bar when the palette is
open, and a status bar with the app status dot, contextual hints and the
right-hand resource/sort cluster. See `docs/tui-design-spec.md` for the full
component + theme spec.

## Architecture (preview)

```
bin/resumesux_tui.dart        entry point: arg parse, capabilities, run loop
lib/src/
  term/term.dart              ScreenBuffer, diff renderer, ANSI spans
  term/theme.dart             token -> ANSI resolution, k9s + light themes
  term/capabilities.dart      16/256/truecolor detection
  term/terminal.dart          raw-mode binding + raw input/mouse decoder
  input/key_model.dart        normalised InputKey / Ctrl model
  input/keymap.dart           pure interaction keymap + mouse dispatch
  input/mouse.dart            SGR mouse-protocol parser
  widgets/frame.dart, table.dart, detail.dart, statusbar.dart, help.dart,
  widgets/modal.dart, palette.dart, empty.dart, spinner.dart
  app/app.dart                App shell: layout grid, focus, key routing
  app/store.dart              unidirectional store (immutable AppState → Action)
  app/actions.dart
  data/demo_data.dart         seed rows for --demo/--state flags
```

## Interaction layer

Input is routed through the pure `interact(state, key)` keymap in
`lib/src/input/keymap.dart`, which dispatches an `Action` per focus mode
(pane, filter, command palette, modal, help). The mouse model is a pure SGR
parser (`lib/src/input/mouse.dart`); the terminal binding decodes raw bytes
into keys and SGR mouse events (dart_console has no mouse support), and the
shell maps clicks/wheel to row selection + pane focus + scrolling.

