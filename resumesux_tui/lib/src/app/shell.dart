/// The app shell: layout grid + focus + key routing + render loop.
///
/// Owns the full terminal rectangle and divides it into header / main split /
/// status-or-command bar. Renders each frame into a [ScreenBuffer], diffs it
/// against the previous frame and writes only the changed cells to the
/// terminal. Input is routed to the focused target; global keys win.
library;

import '../app/store.dart';
import '../data/demo_data.dart';
import '../input/keymap.dart';
import '../input/key_model.dart';
import '../input/mouse.dart';
import '../term/screen_buffer.dart';
import '../term/terminal.dart';
import '../term/theme.dart';
import '../widgets/detail.dart';
import '../widgets/header.dart';
import '../widgets/help.dart';
import '../widgets/modal.dart';
import '../widgets/palette.dart';
import '../widgets/rect.dart';
import '../widgets/status_bar.dart';
import '../widgets/table.dart';

/// Column sets per screen, matching the spec wireframes.
List<ColumnDef> _columns(ScreenId s) {
  switch (s) {
    case ScreenId.applicants:
      return const [
        ColumnDef('name', width: 22),
        ColumnDef('status', width: 10),
        ColumnDef('score', width: 8),
        ColumnDef('age'),
      ];
    case ScreenId.jobreqs:
      return const [
        ColumnDef('title', width: 26),
        ColumnDef('concern', width: 18),
        ColumnDef('fit', width: 8),
        ColumnDef('location'),
      ];
    case ScreenId.applications:
      return const [
        ColumnDef('applicant', width: 18),
        ColumnDef('job', width: 22),
        ColumnDef('docs', width: 8),
        ColumnDef('updated'),
      ];
    case ScreenId.gigs:
      return const [
        ColumnDef('title', width: 22),
        ColumnDef('concern', width: 20),
        ColumnDef('dates'),
      ];
    case ScreenId.assets:
      return const [
        ColumnDef('content', width: 30),
        ColumnDef('tags'),
      ];
  }
}

/// Default the app shell on a [Terminal]. Runs the render loop until quit.
class AppShell {
  final Terminal term;
  final bool demo;
  final String? demoState;
  final String? initialThemeName;

  AppShell({
    required this.term,
    required this.demo,
    this.demoState,
    this.initialThemeName = k9sThemeName,
  });

  late AppState _state;
  ScreenBuffer? _prev;

  void run() {
    _state = _initialState();
    term.enter();

    try {
      // First paint before any input (boot shell, then data).
      _paint(force: true);
      // Seed demo data immediately (simulate fast adapter).
      _seed();
      _paint();

      while (!_state.quit) {
        final ev = term.readEvent();
        if (ev == null) break;
        final AppState next;
        if (ev is TermKeyEvent) {
          next = _dispatch(termKeyToInput(ev.key));
        } else if (ev is TermMouseEvent) {
          next = _dispatchMouse(ev.event);
        } else {
          next = _state;
        }
        if (next != _state) {
          _state = next;
          _paint();
        }
      }
    } finally {
      term.exit();
    }
  }

  AppState _initialState() {
    final cap = term.capability;
    final theme = buildTheme(initialThemeName ?? k9sThemeName, cap);
    return AppState(theme: theme, commands: kCommands, themeName: initialThemeName ?? k9sThemeName);
  }

  void _seed() {
    var st = _state;
    for (final s in ScreenId.values) {
      final rows = demoRows(s, demoState);
      final load = demoLoadState(s, demoState);
      final err = demoError(s, demoState);
      st = reduce(st, DataLoadedAction(s, rows));
      final vs = st.view(s).copyWith(load: load, error: err);
      st = st.copyWith(views: {...st.views, s: vs});
    }
    _state = st;
  }

  void _paint({bool force = false}) {
    final w = term.width;
    final h = term.height;
    if (w <= 0 || h <= 0) return;

    final buf = ScreenBuffer(w, h);

    // App background fill.
    final appBg = _state.theme.id(ColorSlot.fg, bg: ColorSlot.appBg);
    buf.fillRect(0, 0, h - 1, w - 1, ' ', appBg);

    final isHelp = _state.helpOpen;
    final isModal = _state.modal != null;
    final isCmd = _state.focusMode == FocusMode.command;

    // If too small, just show the resize notice (recover on next frame).
    if (h < 24 || w < 100) {
      _resizeNotice(buf, w, h);
      _emit(buf, force);
      return;
    }

    final headerH = 1;
    final statusH = 1;
    final mainH = h - headerH - statusH;
    final mainTop = headerH;

    if (isHelp) {
      Header(w, _state).render(buf, _state.theme);
      Help(Rect(0, mainTop, w, mainH), _state).render(buf, _state.theme);
      StatusBar(w, _state, row: h - 1).render(buf, _state.theme);
      _emit(buf, force);
      return;
    }

    // Main split: table (left) + detail (right), 1-cell gutter; auto-hide
    // detail under 60 cols.
    final showDetail = _state.detailVisible && w >= 60;
    final tableW = showDetail ? _tableWidth(w) : w;
    final gutter = showDetail ? 1 : 0;
    final detailX = tableW + gutter;
    final detailW = showDetail ? w - detailX : 0;

    final tableRect = Rect(0, mainTop, tableW, mainH);
    final detailRect = Rect(detailX, mainTop, detailW, mainH);

    final vs = _state.currentView;
    final table = Table(
      rect: tableRect,
      title: _state.current.title,
      focused: _state.paneFocus == PaneFocus.table,
      view: vs,
      columns: _columns(_state.current),
      errorColor: vs.load == LoadState.error ? ColorSlot.statusErr : null,
    );
    table.render(buf, _state.theme);

    if (showDetail) {
      final sections = _selectedDetail();
      Detail(
        rect: detailRect,
        focused: _state.paneFocus == PaneFocus.detail,
        sections: sections,
        scrollTop: vs.detailScroll,
      ).render(buf, _state.theme);
    }

    // Header / status.
    Header(w, _state).render(buf, _state.theme);
    StatusBar(w, _state, row: h - 1).render(buf, _state.theme);

    // Command bar overlays the status bar row when active.
    if (isCmd) {
      CommandPalette(Rect(0, h - 1, w, 1), _state).render(buf, _state.theme);
    }

    // Modal on top.
    if (isModal) {
      ModalWidget(
        Rect(0, 0, w, h),
        _state.modal!,
        w,
        focusedButton: _state.modalButton,
      ).render(buf, _state.theme);
    }

    _emit(buf, force);
  }

  List<DetailSection> _selectedDetail() {
    final vs = _state.currentView;
    final frows = vs.filteredRows;
    if (frows.isEmpty) return const [];
    final sel = frows[vs.cursor];
    return demoDetail(_state.current, sel);
  }

  int _tableWidth(int w) {
    final want = (w * 0.4).round();
    return want < 30 ? 30 : want;
  }

  void _resizeNotice(ScreenBuffer buf, int w, int h) {
    final msg = 'resize to ≥ 100x24';
    final style = _state.theme.id(ColorSlot.fgDim);
    buf.write(h ~/ 2, (w - msg.length) ~/ 2, msg, style);
  }

  void _emit(ScreenBuffer buf, bool force) {
    final diff = renderDiff(force ? null : _prev, buf, _state.theme);
    if (diff.isNotEmpty) {
      term.writeRaw(diff);
      term.flush();
    }
    _prev = buf;
  }

  AppState _dispatch(InputKey key) {
    // Route through the pure interaction keymap covering all focus modes.
    final action = interact(_state, key);
    if (action == null) return _state;
    // The shell owns the adapter / refresh; RepaintAction is a pure no-op
    // (the render loop paints every iteration, so forcing is unnecessary).
    if (action is RefreshViewAction) return _refresh();
    return reduce(_state, action);
  }

  /// Route a parsed [MouseEvent] into the keymap's mouse dispatcher, using
  /// the same layout geometry the renderer uses.
  AppState _dispatchMouse(MouseEvent e) {
    final w = term.width;
    final h = term.height;
    final showDetail = _state.detailVisible && w >= 60;
    final tableW = showDetail ? _tableWidth(w) : w;
    final mainTop = 1; // below header
    final mainH = h - 2; // header + status rows
    final action = interactMouse(
      _state,
      e,
      tableTop: mainTop,
      tableLeft: 0,
      tableWidth: tableW,
      tableHeight: mainH,
      commandRow: _state.focusMode == FocusMode.command ? h - 1 : null,
    );
    if (action == null) return _state;
    return reduce(_state, action);
  }

  AppState _refresh() {
    // Simulate a refresh: re-seed the current screen and return a new state.
    var st = _state;
    final s = st.current;
    final rows = demoRows(s, demoState);
    final load = demoLoadState(s, demoState);
    final err = demoError(s, demoState);
    st = reduce(st, DataLoadedAction(s, rows));
    final vs = st.view(s).copyWith(load: load, error: err);
    st = st.copyWith(views: {...st.views, s: vs});
    return st;
  }
}

/// Convenience bridge from [TermKey] (terminal layer) to [InputKey] (input
/// layer), since [AppShell._dispatch] takes [InputKey].
InputKey termKeyToInput(TermKey k) {
  if (k.isControl) {
    if (k.charCode != Ctrl.none) return InputKey.control(k.charCode);
    return InputKey.control(Ctrl.none);
  }
  return InputKey.printable(k.char);
}
