# ResumesUX TUI — Design & Component Specification

**Status:** Implementation-ready (v1). A developer can build the shell, theme,
widgets, interactions, and state from this document without making further
design decisions.

**Reference aesthetic:** k9s — crisp borders, clear focus indicators,
consistent alignment, dense-but-readable information, calm 16-color-safe
palette, per-widget focus color, header with context breadcrumb, bottom status
bar with contextual hints, and a `:` command bar.

**Package to build:** `resumesux_tui` (new top-level package, the presentation
ring). Depends inward on `resumesux_application` -> `resumesux_domain`. See
`docs/tui-gap-analysis.md` §4 for the architecture rationale. The seams this
spec assumes already exist are the domain entities; the adapter/use-case wiring
is specified inline as a contract where it matters.

---

## 0. Scope & non-goals

In scope: the shell, the layout grid, the widget inventory, theme tokens,
state pattern, input model, and all view states (empty / loading / error).
Explicitly out of scope for THIS document (later cards): performance
optimization details beyond base rules, multi-monitor / alternate-screen edge
cases, and localization. Non-goals that hold: no GUI/Flutter rendering; the
TUI is a full-screen raw-mode terminal app on `dart_console` + an in-repo
widget layer (per the gap analysis). No webview.

Theme model: **always 16-color ANSI-safe by default, with automatic truecolor
upgrade when the terminal reports `COLORTERM=truecolor`** and 256-color when
it reports neither but supports 256. Every color token must have a defined
16-color fallback so the app never looks broken on a 16-color terminal.

---

## 1. Color palette & theme tokens

### 1.1 Token scale (single source of truth)

All styling flows through tokens. Widgets reference token *names*, never raw
ANSI values, so a theme swap is a data change. Two named themes ship: `k9s`
(default) and `light`. Every token has a 16-color (`base16`) and a truecolor
(`rgb`) value. All tokens are defined for both FG (foreground) and BG (for
those that carry a background fill).

Primary semantic tokens (FG unless noted):

| Token | Role | k9s base16 | k9s rgb |
|---|---|---|---|
| `fg` | default text | white | #d8d8d8 |
| `fg.dim` | secondary/muted text | bright-black | #8f96a0 |
| `fg.faint` | least important metadata (timestamps, hints) | dark-gray(8) | #5f6670 |
| `fg.accent` | brand/emphasis | cyan(6) | #56b6c2 |
| `fg.title` | header title text | bright-white | #eeeeee |
| `header.bg` | header bar fill | blue(4) | #3e4a61 (fill) |
| `header.fg` | header bar text | white | #f0f1f3 |
| `border` | normal pane border | dark-gray(8) | #6b7280 |
| `border.focus` | focused pane border | cyan(6) | #56b6c2 |
| `border.title` | frame title text | bright-white | #dfe3e8 |
| `select` | selection highlight fill | cyan(4) | #264f5c |
| `select.fg` | text on selection | white | #ffffff |
| `cursor` | vim cursor / active char | bright-cyan(14) | #7fdbca |
| `status.ok` | success/ready | green(2) | #89ca78 |
| `status.warn` | warning | yellow(3) | #e5c07b |
| `status.err` | error | red(1) | #e06c75 |
| `status.info` | info/neutral | bright-blue | #61afef |
| `cmd.bg` | command bar fill | black(0) | #1e2730 |
| `cmd.fg` | command bar text | bright-white | #e6e6e6 |
| `cmd.prompt` | `:` prompt + matched fz chars | cyan(6) | #56b6c2 |
| `modal.bg` | modal fill | black(0) | #1b242e |
| `modal.border` | modal border | bright-white | #cfd4da |
| `help.kbd` | keycap background | dark-gray(8) | #3a4450 |
| `help.kbd.fg` | keycap text | bright-white | #ffffff |
| `tag.bg` | tag chip fill | blue(4) | #3e4a61 |
| `tag.fg` | tag chip text | white | #e8eaed |
| `progress.bar` | progress bar fill | cyan(6) | #56b6c2 |
| `progress.track` | progress track / unfilled | dark-gray(8) | #3a4450 |
| `spin` | spinner glyph color | cyan(6) | #56b6c2 |
| `scrollbar` | scrollbar thumb | dark-gray(8) | #4b5563 |

Semantic **status mapping** (used in table Status columns and detail badges):
`matched/green` -> `status.ok`, `pending/warning` -> `status.warn`, `failed/
error` -> `status.err`, `ready/info` -> `status.info`. See §6.2 for how color
is never the *only* signal.

### 1.2 Rule set

1. Background of the whole app is `black`/`#10151c`; every pane is drawn over
   it. No pane gets its own background fill except header, command bar,
   selection highlights, modals, and tag chips — anything else must let the
   background show through to stay calm.
2. Selection is a **fill**, not a border or underline: `select` bg + `select.fg`
   text. The focused *pane* is a **border** change (`border.focus`) — these two
   focus signals are deliberately distinct (row-selection vs pane-focus).
3. The command-bar fill and header fill are the only large color fields; keep
   them low-saturation so text over them stays readable.
4. Never render a token's raw RGB when the terminal is 16-color — the base16
   fallback applies per terminal capability, decided once at startup (§7).

---

## 2. Typography & spacing

### 2.1 Typography

- Font is the terminal's fixed-width font. Set **no** font control; instead
  guarantee monospace integrity by using only single-width, single-cell glyphs
  in the CJK-safe ASCII/Unicode block set below.
- Glyph set (whitelist): box-drawing `─│┌┐└┘├┤┬┴┼`, rounded corners `╭╮╰╯`,
  medium shade `▒`, full block `█`, thin spinner `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` (Braille
  spinner; fall back to `|/-\` on terminals that mangle it), ellipsis `…`,
  bullets `•`, check `✓`, warn `!`, mixed `◐`, and middot `·`. Everything else
  is plain ASCII.
- Case rules: column headers, section titles, and the header breadcrumb are
  **uppercase** (k9s style). Table cell data keeps its natural case.
- Numeric alignment: numbers that are fitness/score percentages right-align in
  their column; durations/timestamps are left-aligned but zero-padded so they
  sort visually.

### 2.2 Spacing grid

The app uses a **1-cell unit grid** with these rules (no fractional cells, no
partial runes in a row — a truncated cell/line always ends on a cell boundary):

| Token | Value | Use |
|---|---|---|
| `space.xs` | 1 cell | padding inside tag chips; between border and frame title |
| `space.sm` | 2 cells | horizontal padding inside a table cell; pane content left inset |
| `space.md` | 3 cells | gutter between multi-row key/value groups in detail pane |
| `space.lg` | 4 cells | left inset of detail pane body |
| `gutter` | 1 cell | vertical row pitch between table rows — always exactly 1 (dense) |
| `panel.pad` | 1 cell | interior padding from a pane's inner border to its content |

Rules:
- Horizontal content inset inside any bordered pane = `panel.pad` (1) on each
  side, plus `space.sm` (2) between the first renderable cell and the border.
- Table row height is always 1 line; no multi-line rows in the table widget.
- Detail pane sections are separated by `space.md` (3 blank... 1 blank line +
  2), i.e. one blank line between sections, with an uppercase section header.

---

## 3. Border & shadow treatment

- **Borders:** every pane is a `Frame` with a `─┐┘└├┤┬┴┼` single-line border by
  default. Focused pane switches to `border.focus` color — **nothing else about
  the border changes** (no double line, no dimming of the rest).
- **Frame titles:** each pane may carry an optional title drawn inset at the
  top border (k9s header style), colored `border.title`, uppercase. Title text
  is left-aligned starting 2 cells in from the border corner.
- **Shadow:** none. TUI panes never cast shadows (no alpha, terminal can't do
  it cleanly, and it reads as noise). Depth is conveyed by border color +
  focus, never by shadow. The modal is the sole exception, and even it uses a
  **dimming overlay** (render reduced-intensity copies of the under-surface
  glyphs, `fg.faint`) rather than a shadow.
- **Corner radii:** default sharp corners; the modal uses rounded corners
  `╭╮╰╯` to visually lift it above the panes. No other element gets rounded
  corners.
- **Scrollbar:** a 1-cell-wide thumb column on the right inner edge of a
  scrollable pane, colored `scrollbar`, drawn only when the content overflows.

---

## 4. Layout grid (the shell)

A single root layout divides the terminal ownership region (the full
alternate screen) into four stacked/arranged regions. Coordinates use the
convention that row 0 / col 0 is the top-left inner cell of the screen buffer.

```
┌────────────────────────────────────────────────────────────────────┐
│  HEADER  (1 line)                                                │← header
├────────────────────────────────────────────────────────────────────┘
│  MAIN SPLIT (fills remaining height)                             │
│  ┌─ table pane ────┐┌─ detail pane ────┐                         │← main
│  │                 ││                  │                         │  content
│  └─────────────────┘└──────────────────┘                         │
├────────────────────────────────────────────────────────────────────┐
│  COMMAND BAR (1 line, hidden unless active)                       │← command
├────────────────────────────────────────────────────────────────────┤
│  STATUS BAR (1 line)                                              │← status
└────────────────────────────────────────────────────────────────────┘
```

### 4.1 Header bar (height 1, always)

`header.bg` fill across full width. Contents, left to right, each separated by
two spaces:
1. App title, `resumesux` in `fg.title` (bold).
2. Current view breadcrumb in `fg.accent`: `applicants / matched` (screen /
   filter), uppercase.
3. Context count in `fg.dim`: `(12)` — the number of items in the *current
   filtered* view, not total.
4. (When a detail pane is open) the selected item identifier in `fg.dim`,
   prefixed with `·`. e.g. `· JobReq: RN-Pediatric`.
5. Right-aligned: the current active command or running op status, e.g.
   `generating…` with spinner, in `fg.accent`.

### 4.2 Main content (fills everything between header and command/status)

A horizontal split of two panes controlled by the `SourcesPaneLayout`:
- **Table/List pane** (left): width = `max(40%, 30 cells)`, grows with
  available width. Holds the primary collection view.
- **Detail pane** (right): the remaining width, min `24` cells. Hidden when
  `detail.visible == false` (full-width table) — toggled since-contextual state
  (`ctl+d`).

Both panes are `Frame`s with independent scroll state (§8.4). There is a
**1-cell gutter** between the two panes (a blank column) so borders never
touch.

### 4.3 Command bar (height 1, overlays the status bar when active)

Initially hidden. When visible (user pressed `:`), it replaces the status bar
row: a `:` prompt in `cmd.prompt`, then the typed input, then the fuzzy-match
completion dropdown drawn *above* this row as an overlay listing up to 8
matches (first line = currently highlighted). See §9.3.

### 4.4 Status bar (height 1, always visible unless command bar is up)

No fill (app background shows). Contents, left to right:
1. App status dot: `●` in the semantic status color + word, e.g.
   `● ready`, `● working`, `● error`. (§6.3)
2. Two spaces, then context-dependent hints for the *focused* pane, each
   `key in fg.accent + action in fg.dim`, separated by 2 spaces.
   Example: `c add · ⌥1..4 panes · ? help · q quit`.
3. Right-aligned (only if space permits): resource count + current sort/filter,
   e.g. `12/142 · sort:score`.
4. When an async op is running, the right side shows the spinner + current step.

Total shell height = `1 (header) + MAIN + 1 (status|command)`. Width = full
terminal. Min viable terminal is `100 x 24`; below that the app shows a
centered `resize terminal` notice (see §6.4).

### 4.5 Responsive rules

- `SIGWINCH`/resize triggers a full relayout; no state is lost. The next paint
  redraws the entire buffer once (cheap at this size), then returns to
  dirty-region deltas (§7).
- Under `60` columns width: hide the detail pane automatically (full-width
  table) regardless of `detail.visible`, until width returns.
- Under `80` columns: `statusbar` right-side cluster (item 3) is dropped; hints
  are trimmed to the two most important per pane.
- The layout engine recomputes on every frame from the current viewport size +
  state; nothing is cached as a fixed layout.

---

## 5. Component inventory

Every component is a widget in the in-repo `widgets/` layer. All widgets:
implement `render(Surface, Rect, AppState) -> void` + `onKey/keyHit` + focus
awareness, and are stateless w.r.t. app state (they read `AppState` and emit
`Action`s; see §8).

### 5.1 `Frame`
Bordered box with optional title. Parameters: `title`, `titleStyle`, `border
style`. Renders inner content clipped to the inner rect. Base of all panes.

### 5.2 `Table`
The workhorse for all collection screens (Applicants, JobReqs, Applications,
Gigs, Assets).
- Column model: `List<Column>` where `Column { label, key, width (fixed|flex|auto), align, renderer(Item)->String }`.
- Header row: uppercase labels, `fg.title`, separated by two spaces.
- Rows are **virtualized**: only visible rows are rendered; scrolling maps a
  window index onto the full items list.
- Current row: `select` fill + `select.fg`. Column sort indicator: a `^`/`v`
  caret in the header next to the sort key label.
- Vertical scrollbar on overflow (see §3).
- Keyboard/mouse per §9/§10. Single selection (no multi-select v1).

### 5.3 `List`
Simpler single-column list used for the command palette results, tags, and
lightweight pickers (e.g. "which asset type"). Same selection + virtualization
rules as Table. No column headers.

### 5.4 `Detail` (k9s info-view analogue)
Right pane. Body is key/value + free text grouped into sections:
- Section header: uppercase `fg.accent`, 1 blank line above.
- Key/value rows: `key` in `fg.dim` padded to a consistent label column, then
  `value` in `fg`. Long values wrap; wrapped continuation lines align to the
  value column (no hanging indent in the label column).
- Overrides: known scalar fields render typed (see §5.4.1); markdown bodies
  (resume content, job req content) render as a plain, hard-wrapped text region
  with the first line hanging.
- Scrollable independently of the table.
- Compact/`raw` mode: `⌥R` toggles from the formatted section view to the raw
  source markdown of the selected document — same widget, different fields.

5.4.1 Field groups per entity (guaranteed by the adapter; see §8.2):

| Screen | Group 1 (identity) | Group 2 | Group 3 |
|---|---|---|---|
| Applicants | name, preferredName, email | phone, linkedin, github, portfolio | gigs (count), assets (count) |
| JobReqs | title, concern.name, location | salary, whereFound, createdDate | content (markdown) |
| Applications | applicant.name, jobReq.title | createdAt, updatedAt | resume / coverLetter / feedback presence flags |
| Gigs | title, concern.name, location | dates | achievements (bulleted) |
| Assets | tags (chips) | content | — |

(Adapters render from the domain entity fields; doc presence flags e.g.
`resume ✓`, `cover ✓`, `feedback ✓` are computed booleans.)

### 5.5 `Modal`
Centered `╭╮╰╯`-corners dialog over a dimmed overlay. Y = centered, width =
`min(60%, 60)` cells. Contents: optional title line, message body (wrapped),
then a button row (see §5.8), then `enter · confirm   esc · cancel` hint.
Focus moves into the modal; nothing else is interactive while it is up. Used
for confirmations (delete, over-write a generated doc) and error dialogs
(§6.3).

### 5.6 `Help`
Full-screen view (`?`) replacing main content: a two-column table of key →
action, grouped by section (Navigation, Selection, Actions, Command bar,
Mouse). Uses `help.kbd` keycap chips for keys. Scrollable if taller than the
viewport. `esc` returns to the prior view without losing any table state.

### 5.7 `CommandPalette`
Drawn as the command-bar region plus the overlay match list (§4.3). Input
prefix `:` (user types after it). Fuzzy match over the command registry
(§9.3); the top match is highlighted and `enter` runs it. `esc` closes and
restores the status bar. Empty query shows the full command list (max 8 shown).

### 5.8 `Button`
Used inside `Modal` and the detail pane for explicit actions. A chip: bordered
box, label, key hint on the right, e.g. `[ confirm ]`. Focused button gets
`select` fill. Activated by `enter` or a mouse click.

### 5.9 `StatusBar` + `ProgressIndicator`
StatusBar composition is in §4.4. `ProgressIndicator` is an inline one-liner:
`▰▰▰▱▱ 62% · step 3/5` where the bar is `progress.bar` fill over
`progress.track`, plus a `spin` glyph while indeterminate. Used in the header
right cluster and inside the detail pane for long generations.

### 5.10 `TagChip`
A small `bracketed` pill: `tag.bg` fill, `tag.fg` text, e.g. `<license>`.
Used to render `Tags`/`Asset.tags` and entity tags. Low contrast by design;
never the sole signal when it matters (paired with text).

---

## 6. State model & rendering loop

### 6.1 Unidirectional store (no heavy lib)

App state is a single immutable-ish `AppState`:
```
AppState {
  ScreenRoute route                 // which screen (/applicants ... )
  Map<ScreenId, ViewState> views    // per-screen table/view/detail state
  Focus focus                       // PaneFocus | ModalFocus | CommandFocus | Help
  Modal? modal
  CommandState? command             // command bar active: query, matches, highlight
  Status status                     // ready|working|error + message
  Theme theme
  UiPrefs prefs                     // displayed pane split %, detail.visible
}
ViewState {
  List<Item> rows; int total
  int cursor; int scrollTop
  SortKey sort; SortDir dir
  String? filterQuery; List<Item> filtered
  bool detailVisible
  LoadState load                     // idle|loading(progress)|loaded|error(msg)
}
```
Flow: `Action` -> `Store.dispatch(Action)` -> `Store` (pure reducer) returns a
new `AppState` -> subscribers (`ChangeNotifier`-style `Stream<void>`) trigger a
render pass. **No widget mutates `AppState` directly**; widgets emit actions,
the store reduces. UI command handlers are thin: they dispatch one action.

### 6.2 Adapter / use-case seam (the missing adapter ring)

The store holds no I/O. Async work (loading collections, running generation)
is done by **adapter objects bound at the outer ring**, which the store calls
through thin constructor-injected ports. Each adapter:
- exposes `Stream<TuiProgress>` for long ops (replacing the old
  `void Function(String)` callback — the core use cases must expose a
  state stream; see gap-analysis §3.11),
- returns `Result<List<T>>` wrapped in fpdart `TaskEither` (matching the
  existing error style),
- is dry-runnable — a `FakeStore` adapter ships in `tool/` so the shell is
  fully explorable with seed data and no network (`resumesux_tui --demo`).

The store dispatches an async action into an adapter, and adapts the resulting
`TaskEither`/`Stream` back into `Action.dataLoaded` / `Action.dataFailed` /
`Action.progress`. This keeps rendering pure.

### 6.3 Load / empty / error states (mandatory, every view)

1. **Loading:** pane body shows, vertically centered over the content area:
   `spin glyph + " loading applicants…"` in `fg.dim`. If the adapter emits
   progress steps, the right side of the header shows `generating…` + bar.
   The table keeps its border + previous header; only the body is the load UI.
   No spinner in a pane that already has data (only the async *refresh* uses a
   header spinner + a subtle `…` in the affected column).
2. **Empty:** pane body shows, vertically centered: a `fg.faint` glyph then a
   `fg.dim` line `no applicants yet`. Below it, a hint line in `fg.faint`
   naming the add action, e.g. `press  a  to add`. Empty is never rendered as
   a blank pane; the hint is what makes it feel intentional.
3. **Error (non-modal):** the pane body shows an error panel: `status.err`
   `!` glyph + `fg` message (one wrapped line) + `fg.faint` retry hint
   `press  r  to retry`. The pane border turns `status.err`. This is a soft,
   recoverable state — the pane stays in place and retry is one keypress.
4. **Error (modal):** only for catastrophic/global failures (adapter init
   failure, terminal binding failure, a core exception with no valid pane
   target). A `Modal` with the error and a single `[ quit ]` button. The app
   stays drawn behind it.
5. **Initial boot state:** the app paints the shell (header + border frame +
   status bar) immediately, with each main pane in `loading`, then fills as
   data arrives. The user sees a shell appear in under one frame — never a
   blank white screen before first paint.

### 6.4 Global states
- **Dirty state indicator:** if the current screen has unsaved edits (none in
  v1 — all writes are immediate modal-confirmed actions), reserved for future.
- **Blocked / busy:** during a modal-confirmed generation, the status bar shows
  `● working` + spinner + current step; input is still accepted but panes don't
  reorder; no second destructive `enter` is possible (in-flight guard on the
  action).
- **Terminal too small:** when height < 24 or width < 100, render a centered
  `resize to ≥ 100x24` message on app background (no panes), keep reading
  input, and recover automatically on next resize — no state loss.

### 6.5 Rendering loop & performance rules
- Single-threaded loop on the alternate screen buffer: every frame = draw to
  an in-memory `ScreenBuffer`, then **diff against the previous frame's buffer
  and emit only changed cells** to the terminal (`\x1b[row;colH` + text). No
  clear-and-redraw flicker.
- Frames render only in response to (a) input events, (b) store notifications,
  (c) resize, (d) a ~50ms async heartbeat while a spinner/progress is active.
  Idle app = zero CPU.
- Row virtualization (see Table) so a 10k-row collection still paints O(visible).
- ANSI spans are emitted as (fg,bg,attrs) cell runs; a run of identical-style
  cells is emitted as one escaped sequence.

---

## 7. Terminal binding & capability detection

Use `dart_console` for: entering raw mode, alternate-screen enter/leave, key
event reads, and ANSI output; use `dart_termlib`/`ansicolor` for capability:
1. Read `TERM`. If it mentions `truecolor` or `COLORTERM=truecolor` ->
   truecolor theme values. Else if `TERM` is e.g. `xterm-256color` -> 256-color
   (map each token to nearest 256 index). Else -> base16 values.
2. Query terminal size; subscribe to `SIGWINCH`/resize events and re-derive.
3. On exit (always, including via `q`, `ctrl+c`, or a crash) restore the
   normal screen, cursor show, and echo before returning to the shell.
4. Mouse: enable SGR mouse reporting (`\x1b[?1000;1006h`) so coordinates are
   SGR-absolute (works in tmux). Disable on exit.

---

## 8. Lightweight footprint note

No third-party widget/gui framework. The widget layer is ~1k lines in-repo.
Dependency surface added to `resumesux_tui/pubspec.yaml`:

```yaml
dependencies:
  resumesux_application: { path: ../resumesux_application }
  resumesux_domain:      { git: ... }   # already a dep of application
  dart_console: ^4.0.0
  fpdart: ^1.2.0
dev_dependencies:
  test: ^1.28.0
```

---

## 9. Keyboard interaction model

### 9.1 Keys & focus routing
Input is delivered to the focused target: the focused pane's widget first; if
it reports unhandled, the app-level keymap runs. Global keys (quit, help,
command bar, pane switching) always win over pane-local.

### 9.2 Default keymap

| Key | Action | Scope |
|---|---|---|
| `↑` / `k` | cursor up | table/list |
| `↓` / `j` | cursor down | table/list |
| `PgUp` / `Ctrl-b` | page up | table/list |
| `PgDn` / `Ctrl-f` | page down | table/list |
| `Home` / `g` | jump to first row | table/list |
| `End` / `G` | jump to last row | table/list |
| `←` / `h`, `→` / `l` | horizontal scroll | table/detail |
| `Tab` | next pane / next focusable | global |
| `Shift+Tab` | previous pane | global |
| `⌥1..4` | jump to pane 1..4 (table, detail, modal, help) | global |
| `Enter` | select / open detail / confirm | context |
| `Esc` | back / close modal / close command bar / leave help | global |
| `:` | toggle command palette | global |
| `/` | filter/search within current pane | view |
| `n` | next match (after `/`) | view |
| `s` | sort (cycle: none → asc → desc on focused column) | table |
| `r` | refresh current view (empty/error: retry) | view |
| `a` | add new item (opens modal form) | view |
| `d` | delete selected (confirmation modal) | view |
| `c` | generate (create resume/cover) for selected | view |
| `v` | preview raw markdown of selected doc | view |
| `⌥R` | toggle formatted ↔ raw detail mode | detail |
| `⌥D` | toggle detail pane visibility | detail |
| `?` | open help view | global |
| `q` | quit (confirmation modal if dirty/busy; else immediate) | global |
| `Ctrl+C` | quit (same as `q`) | global |
| `Ctrl+L` | redraw / repaint screen | global |

The table/list also reserves `:`-style filtering via `/`: typing a query
filters rows live (matches on name/email/title), `esc` while in filter mode
clears it and returns to normal, `n` cycles matches.

### 9.3 Command palette commands (registry)

`:` opens the palette; fuzzy match on command name (`fzf`-style substring
subsequence scoring). Commands (v1), with aliases:

| Command | Alias | Action | Args |
|---|---|---|---|
| `applicants` | `app` | switch view to Applicants | — |
| `jobreqs` | `jobs` | switch view to JobReqs | — |
| `applications` | `apps` | switch view to Applications | — |
| `gigs` | `g` | switch view to Gigs | — |
| `assets` | `a` | switch view to Assets | — |
| `generate` | `gen` | generate resume for selected | optional `applicant id` / `jobreq id` |
| `filter <q>` | `f` | set filter query in current view | query |
| `sort <col>` | `s` | sort current table by column | column key |
| `help` | `h`,`?` | open help view | — |
| `quit` | `q` | quit app | — |
| `theme <name>` | `th` | switch active + persisted theme | k9s\|light |
| `clear` | | clear current filter | — |

Fuzzy match highlights matched characters in `cmd.prompt`. Selection with
`↑`/`↓` + `Enter`; `Esc` cancels. See §4.3/§5.7 for display.

### 9.4 Mouse interaction model

- **Hover** on a table row highlights it with a subtle `fg.faint` underline
  (never a fill — hover ≠ selection).
- **Click** a table row sets the cursor to that row (becomes selection).
- **Click** on a pane (any where) moves focus to that pane (`<` = pane
  boundary highlight in `border.focus`).
- **Scroll wheel** over a scrollable pane scrolls it (`SGR` wheel up/down).
  Wheel over the table scrolls the table; over detail scrolls the detail.
- **Click** a `Button` activates it. **Click** the header breadcrumb right side
  opens nothing (reserved); **double-click** not used in v1.
- Only one pane receives wheel events at a time (the focused one, or the one
  hovered if hover-focus is enabled — default: focused pane).
- Clicking into the command bar area (when visible) focuses the command input.

---

## 10. Empty/loading/error summary (quick reference)

| State | Render | Recovery |
|---|---|---|
| loading | `spin + "loading X…"` centered in pane; header right `generating…` | auto |
| empty | glyph + `no X yet` + `press a to add` | `a` |
| pane error | `!` + message + `press r to retry`, border→err | `r` |
| global error | modal `[ quit ]` | `esc`/`q` |
| too small | centered `resize to ≥ 100x24` | resize |
| busy/in-flight | status `● working` + progress bar; destructive enter locked | wait / `esc` cancels step |

---

## 11. Acceptance traceability (maps to t_7d570efb / t_b07436ba)

- Shell/layout/render (t_7d570efb): §4 grid, §3 borders, §6.5 diff renderer,
  §1 theme — a `--demo` run shows the wireframes below with seed rows.
- Interactions (t_b07436ba): §9 keymap, §9.3 palette, §9.4 mouse, §5 modals +
  help.
- Every wireframe below is directly reproducible from this spec with zero
  extra decisions.

---

## 12. ASCII wireframes (main views)

Notation: `▓░` = selection fill, `#` = border.focus, `·` = panel pad.

### 12.1 Applicants (table + detail, focused = table)

```
┌ RESUMESUX · applicants / matched (12) · Jane Doe ──────────────── generating… ┐
│                                                                            │
├─ APPLICANTS ──────────────────────┐ ├─ DETAIL · Jane Doe ──────────────────┤
│  NAME        STATUS   SCORE  AGE  │ │  NAME        Jane Doe                │
│  Jane Doe    matched  ▓0.92▓ 10m  │ │  PREF NAME   Jay                    │
│  John Roe    pending  0.61  1h    │ │  EMAIL       jane@x.com              │
│  Al Smith    failed   0.44  3h    │ │  PHONE       +1 555 0100             │
│  …                                 │ │  LINKEDIN    /in/janedoe            │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓│ │  GITHUB      github.com/jane       │
│                                    │ │                                     │
│                                    │ │  GIGS        3                      │
│                                    │ │  ASSETS      5                      │
│                                    │ │                                     │
│                                    │ │  TAGS  <license> <edu>              │
├────────────────────────────────────┼┴─┴────────────────────────────────────┤
│  ● ready    c generate · ⌥D detail · ? help · : cmd · q quit  12/142 score  │
└────────────────────────────────────────────────────────────────────────────┘
```
(row 4 shows the selection fill `▓`; the focused pane border is `#`.)

### 12.2 Command palette open (`:gen`)

```
┌ RESUMESUX · applicants / matched (12) ─────────────────────────────────────┐
│   … (table + detail as §12.1, dimmed under overlay)                         │
│  ┌──────────────────────────────────┐                                       │
│  │ :gen                             │  ← command bar area                   │
│  ├──────────────────────────────────┤                                       │
│  │ ⌃ generate <id>                  │  ← match list (top = highlighted)    │
│  │ ⌃ generate for selected          │                                       │
│  └──────────────────────────────────┘                                       │
├───────────────────────────────────────────────────────────────────────────┤
│  enter run · esc close                                                      │
└────────────────────────────────────────────────────────────────────────────┘
```

### 12.3 Confirm modal (`d` on selected applicant)

```
┌ RESUMESUX · applicants / matched (12) ─────────────────────────────────────┐
│   … (underlying dimmed to fg.faint)                                         │
│  ┌────────────────────────────────────────┐                                 │
│  │ ╭ delete applicant ─────────────╮  #  │                                 │
│  │ │  Delete Jane Doe? This also      │  │                                 │
│  │ │  removes her linked documents.   │  │                                 │
│  │ │  [ confirm ]   [ cancel ]        │  │                                 │
│  │ ╰───────────────────────────────╯  │  │                                 │
│  │  enter confirm · esc cancel          │                                 │
│  └────────────────────────────────────────┘                                 │
└────────────────────────────────────────────────────────────────────────────┘
```

### 12.4 Loading / empty / error panes

```
LOADING                EMPTY                 ERROR (pane)
┌─ APPLICANTS ──┐      ┌─ APPLICANTS ──┐     ┌─ APPLICANTS ──┐
│                │      │                │     │ ! could not    │
│    ⠋ loading   │      │    ◐           │     │   reach adapter │
│    applicants… │      │   no applicants│     │   press r retry │
│                │      │   press a add  │     │                │
└────────────────┘      └────────────────┘     └────────────────┘
```

---

## 13. Definition of done (for the implementer)

1. `dart run bin/resumesux.dart --demo` launches the alternate-screen shell
   with seed rows on every screen; no flicker on keystroke or resize.
2. All §9 keys work; `:` palette fuzzy-filters; `?` help renders; modal
   confirm/cancel works; mouse click/wheel/scroll behave per §9.4.
3. Theme tokens: `k9s` and `light`, each correct in 16-color, 256, and
   truecolor modes; switching theme with `:theme light` recolors live.
4. Each of the five views renders its wireframe layout with real domain
   columns; empty/loading/error states per §10 are demonstrable (via `--demo
   --state=empty|error` flags).
5. Resizing below `100x24` shows the resize notice and recovers on grow,
   losing no state.
6. All ASCII in §12 is reproduced (borders, gutters, selection fill, focus
   border, status bar layout).

This spec leaves no open design decisions — a developer implementing against
§1–§13 will converge on a single consistent result. If any downstream card
finds a genuine gap (e.g. the core's async callback really cannot become a
stream without a use-case change), stop and surface it rather than inventing a
second seam.
