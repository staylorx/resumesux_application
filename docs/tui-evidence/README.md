# TUI Acceptance Evidence — ResumesUX

Modern k9s-style TUI, delivered as `resumesux_tui/` sibling package parallel
to the CLI (`bin/resumesux.dart`) inside the `resumesux_application` repo.

## How to run
```
cd resumesux_application/resumesux_tui
dart pub get
dart run bin/resumesux_tui.dart --demo          # live k9s-style shell
dart run bin/resumesux_tui.dart --demo --theme=light
```

## Verified acceptance (headless, fresh in final location)
| Check | Result |
|---|---|
| `dart analyze` (app root + tui) | No issues found |
| `dart test` | 67/67 pass |
| `dart run tool/smoke_test.dart` | ALL SMOKE CHECKS PASSED |
| `dart run tool/dump_layout.dart` | renders k9s wireframe (see below) |
| Push | `7dbbff2` on github.com/staylorx/resumesux_application main |

## Live render dump — APPLICANTS screen (k9s layout verified)
The render shell produces exactly the spec §12.1 wireframe: header
(title + breadcrumb + live counts), horizontal table | detail split with a
1-cell gutter, and a status bar with key hints. See
`applicants_wireframe.txt` for the full 120-col capture.

```
 resumesux  APPLICANTS / matched  (10)  · Jane Doe
┌─APPLICANTS───────────────┐ ┌─────────────────────────────────────────┐
│NAME          STATUS SCORE│ │ identity                                │
│Jane Doe      matched 0.92│ │ name        Jane Doe                     │
│John Roe      pending 0.61│ │ email       jane@x.com                   │
│Al Smith      failed  0.44│ │ linkedin    /in/Jane Doe                 │
│…                          │ │ gigs       3                            │
└──────────────────────────┘ └──────────────────────────────────────────┘
 ● ready  c generate  : cmd  ? help  q quit              10 · sort:-
```

This is a real TUI — raw mode, alternate screen, dirty-cell diff renderer —
not a batch print script (see README §"This is a TUI").
