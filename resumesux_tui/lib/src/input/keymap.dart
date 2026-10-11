/// Pure interaction keymap and mouse dispatch.
///
/// [interact] translates a focused [InputKey] into an [Action] for the
/// reducer, covering the full keybinding set from the spec (§9.2). [interactMouse]
/// translates a parsed [MouseEvent] into an [Action]. Both are pure functions
/// of (state, input) so every binding is testable headlessly; the shell's
/// input loop applies the returned action via `reduce`.
library;

import '../app/store.dart';
import 'key_model.dart';
import 'mouse.dart';

/// Route a focused key to an [Action] for [state], switching on the current
/// focus mode. Returns null when unhandled.
Action? interact(AppState state, InputKey key) {
  switch (state.focusMode) {
    case FocusMode.command:
      return _interactCommand(state, key);
    case FocusMode.modal:
      return _interactModal(state, key);
    case FocusMode.help:
      return _interactHelp(state, key);
    case FocusMode.filter:
      return _interactFilter(state, key);
    case FocusMode.pane:
      return _interactPane(state, key);
  }
}

/// Pane-mode input: global keys always win, then pane-local navigation.
Action? _interactPane(AppState state, InputKey key) {
  // Global keys.
  if (key.char == ':') return OpenCommandAction();
  if (key.char == '?') return OpenHelpAction();
  if (key.char == 'q') return QuitAppAction();
  if (key.isControl && key.code == Ctrl.ctrlC) return QuitAppAction();
  if (key.isControl && key.code == Ctrl.ctrlL) return RepaintAction();
  if (key.char == 'd') return ShowDeleteModalAction();
  if (key.char == 'r') return RefreshViewAction();
  if (key.char == 's') return CycleSortAction();
  if (key.char == '/') return BeginFilterAction();
  if (_isAlt(key, 'd')) return ToggleDetailAction();

  // Pane switching.
  if (key.isTab ||
      (key.isControl && (key.code == Ctrl.tab || key.code == Ctrl.shiftTab))) {
    return ToggleFocusAction();
  }
  if (key.isEnter) {
    return state.paneFocus == PaneFocus.table
        ? OpenDetailAction()
        : ToggleFocusAction();
  }
  if (key.isEsc) {
    // Esc clears a live filter when one is set.
    if (state.currentView.filter != null) return ClearFilterAction();
    return null;
  }

  // Table/list navigation (only when the table is focused).
  if (state.paneFocus == PaneFocus.table) {
    return _tableMove(state, key);
  }
  return null;
}

/// Filter / search mode input.
Action? _interactFilter(AppState state, InputKey key) {
  if (key.isEsc) return ClearFilterAction();
  if (key.isEnter) return ExitFilterAction();
  if (key.isBackspace) return BackspaceFilterAction();
  if (key.isControl) return null;
  // These are overlay triggers; ignore as literal filter chars.
  if (key.char == ':' || key.char == '?') return null;
  return EnterFilterCharAction(key.char);
}

/// Command palette input.
Action? _interactCommand(AppState state, InputKey key) {
  if (key.isEsc) return CloseCommandAction();
  if (key.isEnter) {
    final m = paletteMatches(state);
    if (m.isEmpty) return CloseCommandAction();
    final idx = state.paletteHighlight.clamp(0, m.length - 1);
    return RunCommandAction(m[idx].name);
  }
  if (key.isBackspace) {
    final q = state.commandQuery ?? '';
    if (q.isEmpty) return CloseCommandAction();
    return ApplyCommandQueryAction(q.substring(0, q.length - 1));
  }
  if (key.isControl) {
    if (key.code == Ctrl.up) return MovePaletteHighlightAction(-1);
    if (key.code == Ctrl.down) return MovePaletteHighlightAction(1);
    return null;
  }
  if (key.char == 'k') return MovePaletteHighlightAction(-1);
  if (key.char == 'j') return MovePaletteHighlightAction(1);
  if (key.isControl) return null;
  return ApplyCommandQueryAction((state.commandQuery ?? '') + key.char);
}

/// Modal input: tab cycles buttons, enter activates, esc cancels.
Action? _interactModal(AppState state, InputKey key) {
  if (key.isEsc) return DismissModalAction();
  if (key.isTab || (key.isControl && key.code == Ctrl.shiftTab)) {
    return MoveModalButtonAction(key.code == Ctrl.shiftTab ? -1 : 1);
  }
  if (key.isEnter) return RunModalButtonAction(state.modalButton);
  return null;
}

/// Help input.
Action? _interactHelp(AppState state, InputKey key) {
  if (key.isEsc || key.char == 'q' || key.char == '?') return CloseHelpAction();
  return null;
}

/// Table/list cursor movement.
Action? _tableMove(AppState state, InputKey key) {
  switch (key.code) {
    case Ctrl.up:
      return MoveCursorAction(-1);
    case Ctrl.down:
      return MoveCursorAction(1);
    case Ctrl.pageUp:
    case Ctrl.ctrlB:
      return PageCursorAction(-1);
    case Ctrl.pageDown:
    case Ctrl.ctrlF:
      return PageCursorAction(1);
    case Ctrl.home:
      return JumpCursorAction();
    case Ctrl.end:
      return JumpCursorAction(toLast: true);
    default:
      break;
  }
  if (key.isControl) return null;
  switch (key.char) {
    case 'k':
      return MoveCursorAction(-1);
    case 'j':
      return MoveCursorAction(1);
    case 'g':
      return JumpCursorAction();
    case 'G':
      return JumpCursorAction(toLast: true);
    default:
      return null;
  }
}

bool _isAlt(InputKey key, String ch) => !key.isControl && key.char == ch;

/// Translate a parsed [MouseEvent] into an [Action], or null when not
/// actionable. [tableRect] locates the table pane in buffer coords;
/// [commandRow] is the row of the command bar (or null when hidden).
Action? interactMouse(
  AppState state,
  MouseEvent e, {
  required int tableTop,
  required int tableLeft,
  required int tableWidth,
  required int tableHeight,
  int? commandRow,
}) {
  // Wheel: scroll the pane under the pointer (table if within table bounds,
  // else detail).
  if (e.button == MouseButton.wheelUp || e.button == MouseButton.wheelDown) {
    final dir = e.button == MouseButton.wheelUp ? -1 : 1;
    final inTable = e.row >= tableTop &&
        e.row < tableTop + tableHeight &&
        e.col >= tableLeft &&
        e.col < tableLeft + tableWidth;
    final pane = inTable ? PaneFocus.table : PaneFocus.detail;
    return ScrollPaneAction(dir, pane: pane);
  }
  if (e.button == MouseButton.release) return null;

  if (e.button == MouseButton.left) {
    final inTableCell = e.row >= tableTop &&
        e.row < tableTop + tableHeight &&
        e.col >= tableLeft &&
        e.col < tableLeft + tableWidth;
    // Click in a table body cell: pick the row (header offset 1) + focus table.
    if (inTableCell) {
      final bodyRow = e.row - tableTop - 1;
      if (bodyRow >= 0 && bodyRow < state.currentView.rows.length) {
        return ClickRowAction(bodyRow + state.currentView.scrollTop);
      }
      return ClickPaneAction(PaneFocus.table);
    }
    // Click the command-bar row: focus command input.
    if (commandRow != null && e.row == commandRow) return OpenCommandAction();
    return ClickPaneAction(PaneFocus.detail);
  }
  return null;
}
