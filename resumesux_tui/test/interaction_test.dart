/// Headless tests for the interaction layer: SGR mouse parsing, the pane/
/// command/filter/modal/help keymap, and the interaction reducer actions.
library;

import 'package:resumesux_tui/src/app/store.dart';
import 'package:resumesux_tui/src/input/key_model.dart';
import 'package:resumesux_tui/src/input/keymap.dart';
import 'package:resumesux_tui/src/input/mouse.dart';
import 'package:resumesux_tui/src/term/theme.dart';
import 'package:resumesux_tui/src/widgets/palette.dart';
import 'package:test/test.dart';

AppState _state({FocusMode mode = FocusMode.pane, List<TableViewRow>? rows}) {
  var s = AppState(
    theme: buildTheme(k9sThemeName, Capability.ansi16),
    commands: kCommands,
  );
  if (rows != null) {
    s = reduce(s, DataLoadedAction(ScreenId.applicants, rows));
  }
  return s.copyWith(focusMode: mode);
}

List<TableViewRow> _rows(int n) => [
      for (var i = 0; i < n; i++) TableViewRow([ViewCell('r$i')]),
    ];

void main() {
  group('SGR mouse parser', () {
    test('parses a left-press', () {
      final e = parseSgrMouse('\x1b[<0;5;10M')!;
      expect(e.button, MouseButton.left);
      expect(e.col, 4);
      expect(e.row, 9);
      expect(e.motion, isFalse);
    });

    test('parses a release', () {
      final e = parseSgrMouse('\x1b[<0;5;10m')!;
      expect(e.button, MouseButton.release);
    });

    test('parses wheel up/down', () {
      expect(parseSgrMouse('\x1b[<64;1;1M')!.button, MouseButton.wheelUp);
      expect(parseSgrMouse('\x1b[<65;1;1M')!.button, MouseButton.wheelDown);
    });

    test('parses right/middle buttons', () {
      expect(parseSgrMouse('\x1b[<2;1;1M')!.button, MouseButton.right);
      expect(parseSgrMouse('\x1b[<1;1;1M')!.button, MouseButton.middle);
    });

    test('rejects malformed input', () {
      expect(parseSgrMouse('not a mouse'), isNull);
      expect(parseSgrMouse('\x1b[<0;5M'), isNull);
    });
  });

  group('interact pane', () {
    test('vim j/k move cursor', () {
      var s = _state(rows: _rows(3));
      var a = interact(s, InputKey.printable('j')) as MoveCursorAction;
      expect(a.delta, 1);
    });

    test('arrow down moves cursor', () {
      var s = _state(rows: _rows(3));
      var a = interact(s, const InputKey.control(Ctrl.down)) as MoveCursorAction;
      expect(a.delta, 1);
    });

    test('g/G jump', () {
      var s = _state(rows: _rows(5));
      expect(interact(s, InputKey.printable('g')), isA<JumpCursorAction>());
      final G = interact(s, InputKey.printable('G')) as JumpCursorAction;
      expect(G.toLast, isTrue);
    });

    test('colon opens palette', () {
      expect(interact(_state(), InputKey.printable(':')), isA<OpenCommandAction>());
    });

    test('q quits', () {
      expect(interact(_state(), InputKey.printable('q')), isA<QuitAppAction>());
    });

    test('? opens help', () {
      expect(interact(_state(), InputKey.printable('?')), isA<OpenHelpAction>());
    });

    test('d opens delete modal', () {
      expect(interact(_state(rows: _rows(2)), InputKey.printable('d')),
          isA<ShowDeleteModalAction>());
    });

    test('tab toggles pane focus', () {
      expect(interact(_state(), const InputKey.control(Ctrl.tab)),
          isA<ToggleFocusAction>());
    });

    test('shift-tab toggles pane focus', () {
      expect(interact(_state(), const InputKey.control(Ctrl.shiftTab)),
          isA<ToggleFocusAction>());
    });

    test('s cycles sort', () {
      expect(interact(_state(rows: _rows(2)), InputKey.printable('s')),
          isA<CycleSortAction>());
    });

    test('r refreshes', () {
      expect(interact(_state(rows: _rows(2)), InputKey.printable('r')),
          isA<RefreshViewAction>());
    });

    test('/ begins filter', () {
      expect(interact(_state(), InputKey.printable('/')),
          isA<BeginFilterAction>());
    });
  });

  group('interact command palette', () {
    test('typing appends query', () {
      var s = _state(mode: FocusMode.command);
      final a = interact(s, InputKey.printable('q')) as ApplyCommandQueryAction;
      expect(a.query, 'q');
    });

    test('up/down move highlight', () {
      var s = _state(mode: FocusMode.command);
      expect(interact(s, const InputKey.control(Ctrl.down)),
          isA<MovePaletteHighlightAction>());
      expect(interact(s, InputKey.printable('j')),
          isA<MovePaletteHighlightAction>());
    });

    test('esc closes', () {
      expect(interact(_state(mode: FocusMode.command), const InputKey.control(Ctrl.esc)),
          isA<CloseCommandAction>());
    });
  });

  group('interact modal', () {
    test('esc dismisses', () {
      expect(interact(_state(mode: FocusMode.modal), const InputKey.control(Ctrl.esc)),
          isA<DismissModalAction>());
    });

    test('tab moves button', () {
      expect(interact(_state(mode: FocusMode.modal), const InputKey.control(Ctrl.tab)),
          isA<MoveModalButtonAction>());
    });

    test('enter runs focused button', () {
      expect(interact(_state(mode: FocusMode.modal), const InputKey.control(Ctrl.enter)),
          isA<RunModalButtonAction>());
    });
  });

  group('interact help', () {
    test('esc closes help', () {
      expect(interact(_state(mode: FocusMode.help), const InputKey.control(Ctrl.esc)),
          isA<CloseHelpAction>());
    });
    test('q closes help', () {
      expect(interact(_state(mode: FocusMode.help), InputKey.printable('q')),
          isA<CloseHelpAction>());
    });
  });

  group('interact filter', () {
    test('printing appends filter char', () {
      var s = _state(mode: FocusMode.filter);
      final a = interact(s, InputKey.printable('a')) as EnterFilterCharAction;
      expect(a.char, 'a');
    });

    test('enter exits filter', () {
      expect(interact(_state(mode: FocusMode.filter), const InputKey.control(Ctrl.enter)),
          isA<ExitFilterAction>());
    });

    test('esc clears filter', () {
      expect(interact(_state(mode: FocusMode.filter), const InputKey.control(Ctrl.esc)),
          isA<ClearFilterAction>());
    });
  });

  group('interactMouse', () {
    test('wheel up over table scrolls table', () {
      var s = _state(rows: _rows(20));
      final a = interactMouse(s, parseSgrMouse('\x1b[<64;10;5M')!,
          tableTop: 2, tableLeft: 0, tableWidth: 40, tableHeight: 20) as ScrollPaneAction;
      expect(a.delta, -1);
      expect(a.pane, PaneFocus.table);
    });

    test('click row selects it', () {
      var s = _state(rows: _rows(10));
      // SGR: <0;10;5M -> col=9,row=4. tableTop=2, tableLeft=0.
      // bodyRow = 4 - 2 - 1 = 1.
      final a = interactMouse(s, parseSgrMouse('\x1b[<0;10;5M')!,
          tableTop: 2, tableLeft: 0, tableWidth: 40, tableHeight: 20) as ClickRowAction;
      expect(a.index, 1);
    });

    test('clicks outside table focus detail', () {
      var s = _state(rows: _rows(10));
      // col 79 is beyond tableWidth 40, so it must hit the detail pane,
      // not the row logic.
      final a = interactMouse(s, parseSgrMouse('\x1b[<0;80;10M')!,
          tableTop: 2, tableLeft: 0, tableWidth: 40, tableHeight: 20) as ClickPaneAction;
      expect(a.pane, PaneFocus.detail);
    });
  });

  group('reducer additions', () {
    test('cycle sort goes none->asc->desc->none', () {
      var s = _state(rows: _rows(2));
      expect(s.currentView.sort, Sorting.none);
      s = reduce(s, CycleSortAction());
      expect(s.currentView.sort, Sorting.asc);
      s = reduce(s, CycleSortAction());
      expect(s.currentView.sort, Sorting.desc);
      s = reduce(s, CycleSortAction());
      expect(s.currentView.sort, Sorting.none);
    });

    test('sort actually reorders rows by first cell', () {
      var s = _state(rows: [
        const TableViewRow([ViewCell('beta')]),
        const TableViewRow([ViewCell('alpha')]),
        const TableViewRow([ViewCell('gamma')]),
      ]);
      s = reduce(s, CycleSortAction()); // asc
      expect(s.currentView.rows[0].cells.first.text, 'alpha');
      expect(s.currentView.rows[1].cells.first.text, 'beta');
      expect(s.currentView.rows[2].cells.first.text, 'gamma');
      s = reduce(s, CycleSortAction()); // desc
      expect(s.currentView.rows[0].cells.first.text, 'gamma');
    });

    test('sort none restores source order', () {
      var s = _state(rows: [
        const TableViewRow([ViewCell('b')]),
        const TableViewRow([ViewCell('a')]),
      ]);
      s = reduce(s, CycleSortAction()); // asc -> a,b
      s = reduce(s, CycleSortAction()); // desc -> b,a
      s = reduce(s, CycleSortAction()); // none -> source order b,a
      expect(s.currentView.sort, Sorting.none);
      expect(s.currentView.rows[0].cells.first.text, 'b');
    });

    test('filter filters the displayed rows', () {
      var s = _state(rows: [
        const TableViewRow([ViewCell('Jane Doe')]),
        const TableViewRow([ViewCell('John Roe')]),
        const TableViewRow([ViewCell('Al Smith')]),
      ]);
      s = reduce(s, SetFilterAction('john'));
      expect(s.currentView.filteredRows.length, 1);
      expect(s.currentView.filteredRows[0].cells.first.text, 'John Roe');
      // Source rows remain untouched.
      expect(s.currentView.rows.length, 3);
    });

    test('clear filter restores all rows and returns to pane focus', () {
      var s = _state(mode: FocusMode.filter, rows: [
        const TableViewRow([ViewCell('Jane')]),
        const TableViewRow([ViewCell('John')]),
      ]);
      s = reduce(s, SetFilterAction('jane'));
      expect(s.currentView.filteredRows.length, 1);
      s = reduce(s, ClearFilterAction());
      expect(s.currentView.filter, isNull);
      expect(s.currentView.filteredRows.length, 2);
      expect(s.focusMode, FocusMode.pane);
    });

    test('move cursor clamps against filtered rows', () {
      var s = _state(rows: _rows(5));
      s = reduce(s, SetFilterAction('r0'));
      s = reduce(s, JumpCursorAction(toLast: true));
      expect(s.currentView.cursor, 0); // only r0 matches, index 0
    });

    test('generate command reports working state', () {
      final s = _state(rows: [const TableViewRow([ViewCell('Jane')])]);
      final st = reduce(s, RunCommandAction('gen'));
      expect(st.status, StatusLevel.working);
      expect(st.statusMessage, contains('Jane'));
    });

    test('palette highlight clamps', () {
      var s = _state(mode: FocusMode.command);
      s = reduce(s, MovePaletteHighlightAction(5));
      expect(s.paletteHighlight, lessThanOrEqualTo(s.commands.length - 1));
    });

    test('palette matches is stable with the widget list', () {
      var s = _state(mode: FocusMode.command, rows: _rows(2));
      // Empty query: full registry, in declared order.
      final m = paletteMatches(s);
      expect(m.length, s.commands.length);
      expect(m.first.name, s.commands.first.name);
      // Typing 'g' favours gigs/generate over non-matching.
      s = reduce(s, ApplyCommandQueryAction('g'));
      final mg = paletteMatches(s);
      expect(mg, isNotEmpty);
      expect(mg.every((c) => c.name.contains('g') || c.aliases.contains('g')), isTrue);
    });

    test('modal button clamps', () {
      var s = _state(mode: FocusMode.modal);
      final m = Modal('delete', 'x', const ['confirm', 'cancel']);
      s = s.copyWith(modal: m);
      s = reduce(s, MoveModalButtonAction(-5));
      expect(s.modalButton, 0);
      s = reduce(s, MoveModalButtonAction(9));
      expect(s.modalButton, 1);
    });

    test('open command resets query', () {
      var s = _state(mode: FocusMode.command);
      s = reduce(s, ApplyCommandQueryAction('abc'));
      s = reduce(s, OpenCommandAction());
      expect(s.commandQuery, '');
      expect(s.focusMode, FocusMode.command);
    });

    test('quit sets quit flag', () {
      expect(reduce(_state(), QuitAppAction()).quit, isTrue);
    });

    test('filter enter/backspace', () {
      var s = _state(mode: FocusMode.filter, rows: _rows(2));
      s = reduce(s, EnterFilterCharAction('j'));
      expect(s.currentView.filter, 'j');
      s = reduce(s, BackspaceFilterAction());
      expect(s.currentView.filter, isNull);
    });

    test('run modal button dismisses', () {
      var s = _state(mode: FocusMode.modal);
      s = s.copyWith(modal: Modal('d', 'm', const ['confirm', 'cancel']));
      s = reduce(s, RunModalButtonAction(0));
      expect(s.modal, isNull);
      expect(s.focusMode, FocusMode.pane);
    });
  });
}
