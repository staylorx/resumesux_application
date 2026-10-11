/// Status bar (height 1, bottom row).
///
/// Left: `●` status dot in the semantic color + word. Then context hints for
/// the focused pane (`key` accent + `action` dim). Right-aligned resource
/// count + sort/filter when space permits. No fill — the app background shows
/// through.
library;

import '../app/store.dart';
import '../term/screen_buffer.dart';
import '../term/strings.dart';
import '../term/theme.dart';

class StatusBar {
  final int width;
  final AppState state;
  final int row;
  StatusBar(this.width, this.state, {this.row = 0});

  ColorSlot _statusColor() {
    switch (state.status) {
      case StatusLevel.ok:
        return ColorSlot.statusOk;
      case StatusLevel.working:
        return ColorSlot.statusWarn;
      case StatusLevel.error:
        return ColorSlot.statusErr;
      case StatusLevel.info:
        return ColorSlot.statusInfo;
      case StatusLevel.warning:
        return ColorSlot.statusWarn;
    }
  }

  String _statusWord() {
    switch (state.status) {
      case StatusLevel.ok:
        return 'ready';
      case StatusLevel.working:
        return 'working';
      case StatusLevel.error:
        return 'error';
      case StatusLevel.info:
        return 'info';
      case StatusLevel.warning:
        return 'warn';
    }
  }

  void render(ScreenBuffer buf, Theme theme) {
    final statusStyle = theme.id(_statusColor());
    final keyStyle = theme.id(ColorSlot.fgAccent);
    final dimStyle = theme.id(ColorSlot.fgDim);

    var x = 1;
    buf.write(row, x, '● ${_statusWord()}', statusStyle);
    x += 2 + _statusWord().length + 2;

    // right cluster (count + sort), only if wide enough
    final right = '${state.currentView.filteredRows.length} · sort:${_sortWord()}';
    if (width - x > right.length + 4) {
      buf.write(row, width - right.length - 1, right, dimStyle);
    }

    final remaining = width - x - 4;

    // If a status message is set, show it; else show hints.
    final msg = state.statusMessage;
    if (msg != null && msg.isNotEmpty && remaining > 0) {
      buf.write(row, x, truncate(msg, remaining), dimStyle);
      return;
    }
    final hints = _hints();
    var hx = x;
    for (final h in hints) {
      buf.write(row, hx, h, keyStyle);
      hx += h.length + 2;
      if (hx >= width - 2) break;
    }
  }

  String _sortWord() {
    switch (state.currentView.sort) {
      case Sorting.none:
        return '-';
      case Sorting.asc:
        return '^';
      case Sorting.desc:
        return 'v';
    }
  }

  List<String> _hints() => ['c generate', ': cmd', '? help', 'q quit'];
}
