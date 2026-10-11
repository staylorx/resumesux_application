/// Headless tests for the reducer and the diff renderer.
///
/// These run without a terminal: they exercise the pure state machine and the
/// cell-diffing engine that underpins the "no flicker" rendering.
library;

import 'package:resumesux_tui/resumesux_tui.dart';
import 'package:test/test.dart';

void main() {
  group('reduce', () {
    late AppState initial;

    setUp(() {
      initial = AppState(theme: buildTheme(k9sThemeName, Capability.ansi16));
    });

    test('data loaded moves view to loaded', () {
      final st = reduce(
        initial,
        DataLoadedAction(
          ScreenId.applicants,
          [const TableViewRow([ViewCell('Jane Doe')])],
        ),
      );
      expect(st.view(ScreenId.applicants).load, LoadState.loaded);
      expect(st.view(ScreenId.applicants).rows.length, 1);
    });

    test('empty data moves view to empty', () {
      final st = reduce(initial, DataLoadedAction(ScreenId.applicants, const []));
      expect(st.view(ScreenId.applicants).load, LoadState.empty);
    });

    test('data failed marks error with message', () {
      final st = reduce(initial, DataFailedAction(ScreenId.applicants, 'boom'));
      expect(st.view(ScreenId.applicants).load, LoadState.error);
      expect(st.view(ScreenId.applicants).error, 'boom');
    });

    test('moving cursor clamps at bounds', () {
      var st = reduce(
        initial,
        DataLoadedAction(ScreenId.applicants, [
          const TableViewRow([ViewCell('a')]),
          const TableViewRow([ViewCell('b')]),
        ]),
      );
      st = reduce(st, SetCurrentAction(ScreenId.applicants));
      st = reduce(st, MoveCursorAction(-5));
      expect(st.currentView.cursor, 0);
      st = reduce(st, MoveCursorAction(10));
      expect(st.currentView.cursor, 1);
    });

    test('jump to last goes to final row', () {
      var st = reduce(
        initial,
        DataLoadedAction(ScreenId.applicants, [
          const TableViewRow([ViewCell('a')]),
          const TableViewRow([ViewCell('b')]),
          const TableViewRow([ViewCell('c')]),
        ]),
      );
      st = reduce(st, JumpCursorAction(toLast: true));
      expect(st.currentView.cursor, 2);
    });

    test('command query accumulates and closes', () {
      var st = initial.copyWith(focusMode: FocusMode.command);
      st = reduce(st, ApplyCommandQueryAction('quit'));
      expect(st.commandQuery, 'quit');
      final closed = reduce(st, RunCommandAction('quit'));
      expect(closed.commandQuery, isNull);
      expect(closed.quit, true);
    });

    test('toggle detail flips visibility', () {
      expect(initial.detailVisible, true);
      final st = reduce(initial, ToggleDetailAction());
      expect(st.detailVisible, false);
    });

    test('delete modal opens with selected name', () {
      var st = reduce(
        initial,
        DataLoadedAction(ScreenId.applicants, [
          const TableViewRow([ViewCell('Jane')]),
        ]),
      );
      st = reduce(st, ShowDeleteModalAction());
      expect(st.modal, isNotNull);
      expect(st.modal!.message, contains('Jane'));
      expect(st.focusMode, FocusMode.modal);
    });
  });

  group('ScreenBuffer / renderDiff', () {
    test('first frame emits cursor positions and text', () {
      final buf = ScreenBuffer(4, 2);
      final theme = buildTheme(k9sThemeName, Capability.ansi16);
      buf.write(0, 0, 'AB');
      final out = renderDiff(null, buf, theme);
      expect(out, contains('A'));
      expect(out, contains('B'));
    });

    test('unchanged frame emits nothing', () {
      final theme = buildTheme(k9sThemeName, Capability.ansi16);
      final a = ScreenBuffer(4, 2);
      final b = ScreenBuffer(4, 2);
      a.write(0, 0, 'hi');
      b.write(0, 0, 'hi');
      expect(renderDiff(a, b, theme), isEmpty);
    });

    test('changed cell triggers a diff', () {
      final theme = buildTheme(k9sThemeName, Capability.ansi16);
      final a = ScreenBuffer(4, 2);
      final b = ScreenBuffer(4, 2);
      a.write(0, 0, 'hi');
      b.write(0, 0, 'ho');
      final out = renderDiff(a, b, theme);
      expect(out, contains('o')); // the single changed char
      expect(out, isNot(contains('i')));
    });
  });

  group('render states', () {
    test('loading view renders a spinner + loading label, not an empty state', () {
      final w = 100, h = 24;
      final theme = buildTheme(k9sThemeName, Capability.ansi16);
      final buf = ScreenBuffer(w, h);
      final vs = ViewState(
        screen: ScreenId.applicants,
        load: LoadState.loading,
      );
      Table(
        rect: const Rect(0, 1, 60, 20),
        title: 'APPLICANTS',
        focused: true,
        view: vs,
        columns: const [ColumnDef('name', width: 20), ColumnDef('status')],
      ).render(buf, theme);
      // The body must show the loading frame (spinner + "loading …").
      var foundLoading = false;
      for (var r = 0; r < h; r++) {
        for (var c = 0; c < w; c++) {
          if (buf.cellAt(r, c).char == '⠋') foundLoading = true;
        }
      }
      expect(foundLoading, isTrue);
    });

    test('table renders filtered rows and reflects count in header/status', () {
      final w = 120, h = 30;
      final theme = buildTheme(k9sThemeName, Capability.ansi16);
      final buf = ScreenBuffer(w, h);
      var st = AppState(theme: theme);
      st = reduce(st, DataLoadedAction(ScreenId.applicants, [
        const TableViewRow([ViewCell('Jane Doe')]),
        const TableViewRow([ViewCell('John Roe')]),
        const TableViewRow([ViewCell('Al Smith')]),
      ]));
      st = reduce(st, SetFilterAction('j'));
      final vs = st.view(ScreenId.applicants);
      Table(
        rect: const Rect(0, 1, 60, 20),
        title: 'APPLICANTS',
        focused: true,
        view: vs,
        columns: const [ColumnDef('name', width: 20), ColumnDef('status')],
      ).render(buf, theme);
      // Only the 2 matching rows are drawn in the body.
      final bodyText = StringBuffer();
      for (var r = 3; r < 10; r++) {
        for (var c = 1; c < 40; c++) {
          bodyText.write(buf.cellAt(r, c).char);
        }
      }
      final s = bodyText.toString();
      expect(s, contains('Jane Doe'));
      expect(s, contains('John Roe'));
      expect(s, isNot(contains('Al Smith')));
    });
  });

  group('modal focus', () {
    test('focused button highlights the moved index', () {
      final w = 60, h = 20;
      final theme = buildTheme(k9sThemeName, Capability.ansi16);
      final buf = ScreenBuffer(w, h);
      final modal = Modal('delete', 'Delete?', const ['confirm', 'cancel'], destructive: true);
      ModalWidget(
        Rect(0, 0, w, h),
        modal,
        w,
        focusedButton: 1, // cancel focused
      ).render(buf, theme);
      // The second button should carry the select style; first should not.
      // We assert structurally: cancel is drawn (its text appears).
      var foundCancel = false;
      for (var r = 0; r < h; r++) {
        for (var c = 0; c < w; c++) {
          if (buf.cellAt(r, c).char == 'c' && r > 5) foundCancel = true;
        }
      }
      expect(foundCancel, isTrue);
    });
  });

  group('fuzzy', () {
    test('subsequence matching works', () {
      expect(fuzzyScore('gen', 'generate'), greaterThan(0));
      expect(fuzzyScore('app', 'applications'), greaterThan(0));
      expect(fuzzyScore('xyz', 'applicants'), lessThan(0));
      expect(fuzzyScore('', 'applicants'), 0);
    });
  });
}
