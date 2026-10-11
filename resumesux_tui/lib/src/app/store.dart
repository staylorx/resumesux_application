/// Unidirectional store: immutable-ish [AppState] reduced by [Action]s.
///
/// Widgets never mutate [AppState] directly; they emit [Action]s, the pure
/// [reduce] passes them into a new state, and the app shell repaints on change.
/// The store holds no I/O — adapters (see `data/`) feed rows in via
/// `Action.dataLoaded` / `Action.dataFailed`.
library;

import '../term/theme.dart';

/// Which screen collection is being examined.
enum ScreenId {
  applicants('APPLICANTS', 'applicants'),
  jobreqs('JOB REQS', 'jobreqs'),
  applications('APPLICATIONS', 'applications'),
  gigs('GIGS', 'gigs'),
  assets('ASSETS', 'assets');

  final String title;
  final String route;
  const ScreenId(this.title, this.route);
}

/// A single row cell: text plus the semantic color slot to paint it with.
class ViewCell {
  final String text;
  final ColorSlot? color;
  const ViewCell(this.text, {this.color});
}

/// A table column definition (header label + fixed width; flex if null).
class ColumnDef {
  final String label;
  final int? width; // fixed display width; null = flex (share remaining)
  const ColumnDef(this.label, {this.width});
}

/// The load state of a view.
enum LoadState { idle, loading, loaded, empty, error }

/// Per-screen collection + view state.
class ViewState {
  final ScreenId screen;
  final List<TableViewRow> rows;
  final LoadState load;
  final String? error;
  final int cursor;
  final int scrollTop;
  final int detailScroll; // the detail pane's own scroll offset
  final String? filter;
  final Sorting sort;

  const ViewState({
    required this.screen,
    this.rows = const [],
    this.load = LoadState.loading,
    this.error,
    this.cursor = 0,
    this.scrollTop = 0,
    this.detailScroll = 0,
    this.filter,
    this.sort = Sorting.none,
  });

  ViewState copyWith({
    List<TableViewRow>? rows,
    LoadState? load,
    String? error,
    int? cursor,
    int? scrollTop,
    int? detailScroll,
    String? filter,
    Sorting? sort,
  }) {
    return ViewState(
      screen: screen,
      rows: rows ?? this.rows,
      load: load ?? this.load,
      error: error ?? this.error,
      cursor: cursor ?? this.cursor,
      scrollTop: scrollTop ?? this.scrollTop,
      detailScroll: detailScroll ?? this.detailScroll,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  /// The rows to display after the current filter is applied (display-level
  /// transform of [rows]; the source collection is never mutated). When no
  /// filter is set this is identical to [rows].
  List<TableViewRow> get filteredRows {
    final f = filter;
    if (f == null || f.isEmpty) return rows;
    final q = f.toLowerCase();
    return [
      for (final r in rows)
        if (r.cells.any((c) => c.text.toLowerCase().contains(q))) r,
    ];
  }

  ViewState setError(String message) => copyWith(load: LoadState.error, error: message);
}

/// Sorting descriptor.
enum Sorting { none, asc, desc }

/// A row of a table view, plus optional per-row accent color (e.g. status).
class TableViewRow {
  final List<ViewCell> cells;
  final ColorSlot? rowColor; // applied to the whole row (status)
  final Object? detail; // the underlying entity for the detail pane
  const TableViewRow(this.cells, {this.rowColor, this.detail});
}

/// Focus target within the shell.
enum PaneFocus { table, detail }

/// Whether focus lives in a pane, the filter box, the command palette,
/// the modal, or the help view.
enum FocusMode { pane, filter, command, modal, help }

/// A modal dialog descriptor (confirmations / global errors).
class Modal {
  final String title;
  final String message;
  final List<String> buttons;
  final bool destructive;
  const Modal(this.title, this.message, this.buttons, {this.destructive = false});
}

/// App-level status dot.
enum StatusLevel { ok, working, error, info, warning }

/// Command palette entry.
class Command {
  final String name;
  final List<String> aliases;
  final String hint;
  const Command(this.name, this.aliases, this.hint);
}

/// Immutable application state.
class AppState {
  final ScreenId current;
  final Map<ScreenId, ViewState> views;
  final FocusMode focusMode;
  final PaneFocus paneFocus;
  final Modal? modal;
  final String? commandQuery;
  final int paletteHighlight; // index into the *sorted* command match list
  final int modalButton; // index of the focused modal button
  final List<Command> commands;
  final bool helpOpen;
  final Theme theme;
  final StatusLevel status;
  final String? statusMessage;
  final bool detailVisible;
  final String themeName;
  final bool quit;

  const AppState({
    this.current = ScreenId.applicants,
    this.views = const {},
    this.focusMode = FocusMode.pane,
    this.paneFocus = PaneFocus.table,
    this.modal,
    this.commandQuery,
    this.paletteHighlight = 0,
    this.modalButton = 0,
    this.commands = const [],
    this.helpOpen = false,
    required this.theme,
    this.status = StatusLevel.ok,
    this.statusMessage,
    this.detailVisible = true,
    this.themeName = k9sThemeName,
    this.quit = false,
  });

  ViewState view(ScreenId s) => views[s] ?? ViewState(screen: s);

  ViewState get currentView => view(current);

  AppState copyWith({
    ScreenId? current,
    Map<ScreenId, ViewState>? views,
    FocusMode? focusMode,
    PaneFocus? paneFocus,
    Modal? modal,
    bool clearModal = false,
    String? commandQuery,
    bool clearCommand = false,
    int? paletteHighlight,
    int? modalButton,
    List<Command>? commands,
    bool? helpOpen,
    Theme? theme,
    StatusLevel? status,
    String? statusMessage,
    bool? detailVisible,
    String? themeName,
    bool? quit,
  }) {
    return AppState(
      current: current ?? this.current,
      views: views ?? this.views,
      focusMode: focusMode ?? this.focusMode,
      paneFocus: paneFocus ?? this.paneFocus,
      modal: clearModal ? null : (modal ?? this.modal),
      commandQuery: clearCommand ? null : (commandQuery ?? this.commandQuery),
      paletteHighlight: paletteHighlight ?? this.paletteHighlight,
      modalButton: modalButton ?? this.modalButton,
      commands: commands ?? this.commands,
      helpOpen: helpOpen ?? this.helpOpen,
      theme: theme ?? this.theme,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      detailVisible: detailVisible ?? this.detailVisible,
      themeName: themeName ?? this.themeName,
      quit: quit ?? this.quit,
    );
  }
}

/// Actions dispatched by widgets / the input loop.
sealed class Action {}

class SetCurrentAction extends Action {
  final ScreenId screen;
  SetCurrentAction(this.screen);
}

class DataLoadedAction extends Action {
  final ScreenId screen;
  final List<TableViewRow> rows;
  DataLoadedAction(this.screen, this.rows);
}

class DataFailedAction extends Action {
  final ScreenId screen;
  final String error;
  DataFailedAction(this.screen, this.error);
}

class SetEmptyAction extends Action {
  final ScreenId screen;
  SetEmptyAction(this.screen);
}

class MoveCursorAction extends Action {
  final int delta;
  MoveCursorAction(this.delta);
}

class JumpCursorAction extends Action {
  final bool toLast;
  JumpCursorAction({this.toLast = false});
}

class PageCursorAction extends Action {
  final int pageDelta;
  PageCursorAction(this.pageDelta);
}

class OpenDetailAction extends Action {}

class ToggleDetailAction extends Action {}

class ToggleFocusAction extends Action {}

class SetFilterAction extends Action {
  final String query;
  SetFilterAction(this.query);
}

class ClearFilterAction extends Action {}

class ApplyCommandQueryAction extends Action {
  final String query;
  ApplyCommandQueryAction(this.query);
}

class MovePaletteHighlightAction extends Action {
  final int delta;
  MovePaletteHighlightAction(this.delta);
}

class RunCommandAction extends Action {
  final String name;
  RunCommandAction(this.name);
}

class CloseCommandAction extends Action {}

/// Open the command palette (focus mode -> command, fresh query).
class OpenCommandAction extends Action {}

/// Quit the app.
class QuitAppAction extends Action {}

/// Request a forced repaint; reduces to the same state (the shell repaints).
class RepaintAction extends Action {}

/// Request a view refresh / retry; the shell re-runs the adapter.
class RefreshViewAction extends Action {}

/// Cycle table sort: none -> asc -> desc -> none.
class CycleSortAction extends Action {}

/// Set an explicit sort direction on the current view (not a cycle).
class SetSortAction extends Action {
  final Sorting sort;
  SetSortAction(this.sort);
}

/// Close filter mode and return to the pane (filter query is kept).
class ExitFilterAction extends Action {}

/// Run the focused modal button by index. The shell (and reducer in demo)
/// maps index 0 to the primary/confirm action, others to cancel.
class RunModalButtonAction extends Action {
  final int index;
  RunModalButtonAction(this.index);
}

class MoveModalButtonAction extends Action {
  final int delta;
  MoveModalButtonAction(this.delta);
}

class BeginFilterAction extends Action {}

class EnterFilterCharAction extends Action {
  final String char;
  EnterFilterCharAction(this.char);
}

class BackspaceFilterAction extends Action {}

/// Scroll a pane (wheel or h/l keys): scrollTop changes on the focused pane.
class ScrollPaneAction extends Action {
  final int delta; // rows to scroll (positive = down)
  final PaneFocus pane;
  ScrollPaneAction(this.delta, {this.pane = PaneFocus.table});
}

/// Click a table row at [index]: sets cursor.
class ClickRowAction extends Action {
  final int index;
  ClickRowAction(this.index);
}

/// Click a point in [pane]: moves focus there (no row target).
class ClickPaneAction extends Action {
  final PaneFocus pane;
  ClickPaneAction(this.pane);
}

class OpenHelpAction extends Action {}

class CloseHelpAction extends Action {}

class ShowDeleteModalAction extends Action {}

class DismissModalAction extends Action {}

class QuitRequestedAction extends Action {}

class SetThemeAction extends Action {
  final String name;
  SetThemeAction(this.name);
}

class SetStatusAction extends Action {
  final StatusLevel level;
  final String message;
  SetStatusAction(this.level, this.message);
}

/// Pure reducer. Returns a new [AppState] for [state] + [action].
AppState reduce(AppState state, Action action) {
  switch (action) {
    case SetCurrentAction(:final screen):
      return state.copyWith(
        current: screen,
        status: StatusLevel.info,
        statusMessage: 'view: ${screen.route}',
      );

    case DataLoadedAction(:final screen, :final rows):
      final vs = state.view(screen).copyWith(
        rows: rows,
        load: rows.isEmpty ? LoadState.empty : LoadState.loaded,
        cursor: 0,
        scrollTop: 0,
      );
      return state.copyWith(views: {...state.views, screen: vs});

    case DataFailedAction(:final screen, :final error):
      final vs = state.view(screen).setError(error);
      return state.copyWith(views: {...state.views, screen: vs});

    case SetEmptyAction(:final screen):
      final vs = state.view(screen).copyWith(rows: const [], load: LoadState.empty);
      return state.copyWith(views: {...state.views, screen: vs});

    case MoveCursorAction(:final delta):
      return state.copyWith(
        views: {...state.views, state.current: _move(state.currentView, delta)},
      );

    case JumpCursorAction(:final toLast):
      final v = state.currentView;
      final n = v.filteredRows.length;
      final target = toLast ? n - 1 : 0;
      return state.copyWith(
        views: {
          ...state.views,
          state.current: v.copyWith(cursor: target.clamp(0, n - 1), scrollTop: 0),
        },
      );

    case PageCursorAction(:final pageDelta):
      // Page size is derived in the shell; here roughly 10 rows.
      final page = 10;
      return state.copyWith(
        views: {
          ...state.views,
          state.current: _move(state.currentView, pageDelta * page),
        },
      );

    case OpenDetailAction():
      return state.copyWith(paneFocus: PaneFocus.detail, statusMessage: 'detail');

    case ToggleDetailAction():
      return state.copyWith(detailVisible: !state.detailVisible);

    case ToggleFocusAction():
      return state.copyWith(
        paneFocus: state.paneFocus == PaneFocus.table
            ? PaneFocus.detail
            : PaneFocus.table,
      );

    case SetFilterAction(:final query):
      return state.copyWith(
        views: {...state.views, state.current: _withFilter(state.currentView, query)},
      );

    case ClearFilterAction():
      // Clearing the filter also returns focus to the pane (matches `/` Esc).
      return state.copyWith(
        focusMode: FocusMode.pane,
        views: {...state.views, state.current: _withFilter(state.currentView, null)},
      );

    case ApplyCommandQueryAction(:final query):
      return state.copyWith(commandQuery: query);

    case RunCommandAction(:final name):
      final st = _runCommand(state, name);
      // Close the command bar (unless help opened or still modal).
      if (st.quit) return st.copyWith(clearCommand: true);
      if (st.helpOpen) {
        return st.copyWith(clearCommand: true, focusMode: FocusMode.help);
      }
      return st.copyWith(
        clearCommand: true,
        focusMode: FocusMode.pane,
        status: st.status,
        statusMessage: st.statusMessage,
      );

    case CloseCommandAction():
      return state.copyWith(
        clearCommand: true,
        focusMode: FocusMode.pane,
        status: StatusLevel.ok,
        statusMessage: null,
      );

    case OpenCommandAction():
      return state.copyWith(
        focusMode: FocusMode.command,
        commandQuery: '',
        paletteHighlight: 0,
      );

    case QuitAppAction():
      return state.copyWith(quit: true);

    case RepaintAction():
      return state; // no state change; the shell repaints on every dispatch

    case RefreshViewAction():
      // The shell owns the adapter; the reducer just surfaces a request via
      // status so the shell detects it and re-runs. We no-op here and let
      // the shell's bridge handle the actual refresh.
      return state;

    case CycleSortAction():
      final v = state.currentView;
      final next = switch (v.sort) {
        Sorting.none => Sorting.asc,
        Sorting.asc => Sorting.desc,
        Sorting.desc => Sorting.none,
      };
      return state.copyWith(
        views: {...state.views, state.current: _withSort(v, next)},
      );

    case SetSortAction(:final sort):
      return state.copyWith(
        views: {...state.views, state.current: _withSort(state.currentView, sort)},
      );

    case ExitFilterAction():
      return state.copyWith(focusMode: FocusMode.pane);

    case RunModalButtonAction():
      // In the demo both confirm and cancel end the modal; a real adapter
      // would act on the confirmed action.
      return state.copyWith(clearModal: true, focusMode: FocusMode.pane);

    case OpenHelpAction():
      return state.copyWith(helpOpen: true, focusMode: FocusMode.help);

    case CloseHelpAction():
      return state.copyWith(helpOpen: false, focusMode: FocusMode.pane);

    case ShowDeleteModalAction():
      final v = state.currentView;
      final frows = v.filteredRows;
      final sel = frows.isNotEmpty ? frows[v.cursor].cells.first.text : 'selection';
      return state.copyWith(
        modal: Modal(
          'delete',
          'Delete $sel? This also removes linked documents.',
          const ['confirm', 'cancel'],
          destructive: true,
        ),
        focusMode: FocusMode.modal,
      );

    case DismissModalAction():
      return state.copyWith(clearModal: true, focusMode: FocusMode.pane);

    case QuitRequestedAction():
      return state.copyWith(status: StatusLevel.ok, statusMessage: null);

    case SetThemeAction(:final name):
      final newTheme = buildTheme(name, state.theme.cap);
      return state.copyWith(
        theme: newTheme,
        themeName: name,
        status: StatusLevel.info,
        statusMessage: 'theme: $name',
      );

    case SetStatusAction(:final level, :final message):
      return state.copyWith(status: level, statusMessage: message);

    case MovePaletteHighlightAction(:final delta):
      // Clamp against the current fuzzy match list length.
      final n = _paletteMatchCount(state);
      final next = (state.paletteHighlight + delta).clamp(0, n - 1 < 0 ? 0 : n - 1);
      return state.copyWith(paletteHighlight: next);

    case MoveModalButtonAction(:final delta):
      final n = state.modal?.buttons.length ?? 1;
      final next = (state.modalButton + delta).clamp(0, n - 1);
      return state.copyWith(modalButton: next);

    case BeginFilterAction():
      return state.copyWith(focusMode: FocusMode.filter);

    case EnterFilterCharAction(:final char):
      final current = state.currentView.filter ?? '';
      final q = current + char;
      return state.copyWith(
        focusMode: FocusMode.filter,
        views: {...state.views, state.current: _withFilter(state.currentView, q)},
      );

    case BackspaceFilterAction():
      final current = state.currentView.filter ?? '';
      final q = current.isEmpty ? '' : current.substring(0, current.length - 1);
      if (q.isEmpty) {
        return state.copyWith(
          views: {...state.views, state.current: _withFilter(state.currentView, null)},
        );
      }
      return state.copyWith(
        views: {...state.views, state.current: _withFilter(state.currentView, q)},
      );

    case ScrollPaneAction(:final delta, :final pane):
      final v = state.currentView;
      if (pane == PaneFocus.table) {
        // Keep the pane's selection row visible; nudge scrollTop by delta.
        final maxScroll = (v.filteredRows.length - 10).clamp(0, v.filteredRows.length);
        final next = (v.scrollTop + delta).clamp(0, maxScroll);
        return state.copyWith(
          views: {
            ...state.views,
            state.current: v.copyWith(scrollTop: next),
          },
          paneFocus: pane,
        );
      }
      // Detail pane scrolls its own offset (capped generously; the widget
      // clamps against its content height when it renders).
      final nextD = (v.detailScroll + delta).clamp(0, 1 << 30);
      return state.copyWith(
        views: {
          ...state.views,
          state.current: v.copyWith(detailScroll: nextD),
        },
        paneFocus: pane,
      );

    case ClickRowAction(:final index):
      return state.copyWith(
        views: {...state.views, state.current: state.currentView.copyWith(cursor: index)},
        paneFocus: PaneFocus.table,
      );

    case ClickPaneAction(:final pane):
      return state.copyWith(paneFocus: pane);
  }
}

/// Number of fuzzy-matching commands given the current query.
int _paletteMatchCount(AppState state) => paletteMatches(state).length;

/// The current fuzzy-sorted command match list. Single source of truth used by
/// the keymap (Enter runs the highlighted command), the palette widget (renders
/// the same list), and the store (highlight clamping) — they must never
/// disagree on order or count.
List<Command> paletteMatches(AppState state) {
  final q = state.commandQuery ?? '';
  final scored = <(int, Command)>[];
  for (final c in state.commands) {
    int best = -1;
    for (final n in [c.name, ...c.aliases]) {
      final s = _fuzzyScore(q, n);
      if (s >= 0 && s > best) best = s;
    }
    if (best >= 0) scored.add((best, c));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final s in scored) s.$2];
}

/// fzf-style subsequence scoring: -1 when [query] isn't a subsequence of
/// [candidate], else a match-length bonus (longer/better alignments win).
int _fuzzyScore(String query, String candidate) {
  if (query.isEmpty) return 0;
  var qi = 0;
  var bonus = 0;
  for (var i = 0; i < candidate.length && qi < query.length; i++) {
    if (candidate[i].toLowerCase() == query[qi].toLowerCase()) {
      bonus += 1;
      qi++;
    }
  }
  return qi == query.length ? bonus : -1;
}

ViewState _move(ViewState v, int delta) {
  final n = v.filteredRows.length;
  if (n == 0) return v;
  final next = (v.cursor + delta).clamp(0, n - 1);
  return v.copyWith(cursor: next);
}

/// Build a copy of [v] with the filter updated (or cleared when null).
/// Constructs directly because [ViewState.copyWith] treats a null `filter`
/// argument as "keep the existing value", so clearing must not go through it.
ViewState _withFilter(ViewState v, String? filter) => ViewState(
      screen: v.screen,
      rows: v.rows,
      load: v.load,
      error: v.error,
      cursor: v.cursor,
      scrollTop: v.scrollTop,
      filter: filter,
      sort: v.sort,
    );

/// Sort [v.rows] by the target column (currently column 0, the spec's default
/// sort column) and set [v.sort], navigating the cursor to the matching row
/// when the sort direction changes. Sorting is a display-level transform of
/// the source rows.
ViewState _withSort(ViewState v, Sorting sort) {
  final rows = [...v.rows];
  if (sort == Sorting.asc) {
    rows.sort((a, b) => _cellText(a).compareTo(_cellText(b)));
  } else if (sort == Sorting.desc) {
    rows.sort((a, b) => _cellText(b).compareTo(_cellText(a)));
  }
  return ViewState(
    screen: v.screen,
    rows: rows,
    load: v.load,
    error: v.error,
    cursor: 0,
    scrollTop: 0,
    detailScroll: v.detailScroll,
    filter: v.filter,
    sort: sort,
  );
}

/// The first cell's text is the default sort key (matches the header caret).
String _cellText(TableViewRow r) =>
    r.cells.isNotEmpty ? r.cells.first.text : '';

AppState _runCommand(AppState state, String name) {
  final n = name.trim();
  // theme command with optional arg
  if (n == 'theme' || n.startsWith('theme ')) {
    final arg = n.split(' ').length > 1 ? n.split(' ')[1] : 'k9s';
    if (arg == 'light' || arg == 'k9s') {
      return reduce(state, SetThemeAction(arg));
    }
  }
  // filter <q>: set the current view's filter. RunCommandAction's tail returns
  // focus to the pane with the filter applied (query already fully specified).
  if (n == 'filter' || n.startsWith('filter ')) {
    final q = n.split(' ').length > 1 ? n.split(' ').skip(1).join(' ') : '';
    if (q.isEmpty) return reduce(state, BeginFilterAction());
    return reduce(state, SetFilterAction(q));
  }
  // sort <col>: set the sort direction (column 0 is the only sortable column
  // in v1); 'sort' alone cycles.
  if (n == 'sort' || n.startsWith('sort ')) {
    final arg = n.split(' ').length > 1 ? n.split(' ')[1] : '';
    if (arg == 'asc') return reduce(state, _sortTo(state, Sorting.asc));
    if (arg == 'desc') return reduce(state, _sortTo(state, Sorting.desc));
    if (arg == 'none' || arg == 'off') return reduce(state, _sortTo(state, Sorting.none));
    return reduce(state, CycleSortAction());
  }
  switch (n) {
    case 'applicants' || 'app':
      return reduce(state, SetCurrentAction(ScreenId.applicants));
    case 'jobreqs' || 'jobs':
      return reduce(state, SetCurrentAction(ScreenId.jobreqs));
    case 'applications' || 'apps':
      return reduce(state, SetCurrentAction(ScreenId.applications));
    case 'gigs' || 'g':
      return reduce(state, SetCurrentAction(ScreenId.gigs));
    case 'assets' || 'a':
      return reduce(state, SetCurrentAction(ScreenId.assets));
    case 'help' || 'h' || '?':
      return reduce(state, OpenHelpAction());
    case 'quit' || 'q':
      return state.copyWith(quit: true);
    case 'clear':
      return reduce(state, ClearFilterAction());
    case 'generate' || 'gen':
      return state.copyWith(
        status: StatusLevel.working,
        statusMessage: 'generating resume for ${_selectedName(state)}…',
      );
    default:
      return state.copyWith(
        status: StatusLevel.warning,
        statusMessage: 'unknown command: $n',
      );
  }
}

/// Apply a specific sort direction to the current view.
Action _sortTo(AppState state, Sorting sort) {
  final v = state.currentView;
  if (v.sort == sort) return CycleSortAction();
  return SetSortAction(sort);
}

/// The selected row's first cell (used by generate/delete messages).
String _selectedName(AppState state) {
  final v = state.currentView;
  final frows = v.filteredRows;
  if (frows.isEmpty) return 'selection';
  final idx = v.cursor.clamp(0, frows.length - 1);
  return frows[idx].cells.isNotEmpty ? frows[idx].cells.first.text : 'selection';
}
