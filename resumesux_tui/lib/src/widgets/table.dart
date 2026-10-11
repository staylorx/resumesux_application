/// Virtualized, selectable table with an uppercase header row, per-column
/// renderers, a selection-fill current row, a right-edge scrollbar and a sort
/// caret in the header. Renders only visible rows (O(visible)) so large
/// collections stay cheap.
library;

import '../app/store.dart';
import '../term/screen_buffer.dart';
import '../term/strings.dart';
import '../term/theme.dart';
import 'frame.dart';
import 'rect.dart';

class Table {
  final Rect rect; // the full pane rect (frame border already drawn by caller)
  final String title;
  final bool focused;
  final ViewState view;
  final List<ColumnDef> columns;
  final ColorSlot? errorColor;

  Table({
    required this.rect,
    required this.title,
    required this.focused,
    required this.view,
    required this.columns,
    this.errorColor,
  });

  /// Draw the table frame + header + rows into [buf].
  void render(ScreenBuffer buf, Theme theme) {
    // Frame
    Frame(rect: rect, title: title, focused: focused, errorColor: errorColor)
        .render(buf, theme);

    final inner = rect.inset(1);
    // Content area excludes the header row: header sits on the frame's top
    // interior line, body below it.
    final headerRow = inner.y;
    final bodyTop = headerRow + 1;
    final bodyRows = inner.height - 1;

    // Compute column widths (fixed + flex sharing the remainder).
    final widths = _columnWidths(inner.width);
    final colX = <int>[];
    var x = inner.x;
    for (final w in widths) {
      colX.add(x);
      x += w;
    }

    // Header
    _renderHeader(buf, theme, headerRow, inner.x, widths, colX, inner.width);

    if (view.load == LoadState.error) {
      _renderError(buf, theme, bodyTop, inner);
      return;
    }
    if (view.load == LoadState.loading) {
      _renderLoading(buf, theme, bodyTop, inner);
      return;
    }
    final rows = view.filteredRows;
    if (rows.isEmpty) {
      _renderEmpty(buf, theme, bodyTop, inner);
      return;
    }

    // Virtualized body: map rows onto visible window honouring scrollTop.
    final visible = _visibleWindow(rows.length, bodyRows);
    var seq = 0;
    for (final idx in visible) {
      final row = bodyTop + seq;
      if (row > inner.bottom - 1) break;
      final r = rows[idx];
      final isSel = idx == view.cursor;
      _renderRow(buf, theme, row, inner.x, widths, colX, r, isSel);
      seq++;
    }

    // Scrollbar when overflowing.
    if (rows.length > bodyRows) {
      _renderScrollbar(buf, theme, bodyTop, inner, rows.length, bodyRows);
    }
  }

  List<int> _columnWidths(int total) {
    final fixed = <int>[];
    var fixedSum = 0;
    var flexCount = 0;
    for (final c in columns) {
      if (c.width != null) {
        fixed.add(c.width!);
        fixedSum += c.width!;
      } else {
        fixed.add(-1);
        flexCount++;
      }
    }
    if (total <= 0) return List.filled(columns.length, 1);
    final remaining = total - fixedSum;
    final flexShare = flexCount == 0 ? 0 : (remaining / flexCount).floor();
    return [
      for (var i = 0; i < columns.length; i++)
        columns[i].width != null ? columns[i].width! : flexShare,
    ];
  }

  void _renderHeader(buf, theme, row, x0, widths, colX, totalWidth) {
    final style = theme.id(ColorSlot.borderTitle, bold: true);
    var x = x0;
    for (var i = 0; i < columns.length; i++) {
      var label = columns[i].label.toUpperCase();
      // sort caret
      if (i == 0 && view.sort != Sorting.none) {
        label += view.sort == Sorting.asc ? ' ^' : ' v';
      }
      buf.write(row, x, truncate(padRight(label, widths[i]), widths[i]), style);
      x += widths[i];
    }
  }

  void _renderRow(buf, theme, row, x0, widths, colX, TableViewRow r, bool isSel) {
    final bg = isSel ? ColorSlot.select : (r.rowColor ?? ColorSlot.appBg);
    final fill = theme.id(isSel ? ColorSlot.selectFg : ColorSlot.fg, bg: bg);
    buf.fillRect(row, x0, row, x0 + _rowWidth(widths) - 1, ' ', fill);

    var x = x0;
    for (var i = 0; i < columns.length && i < r.cells.length; i++) {
      final cell = r.cells[i];
      final color = cell.color ?? (r.rowColor ?? ColorSlot.fg);
      buf.write(
        row,
        x,
        truncate(padRight(cell.text, widths[i]), widths[i]),
        theme.id(color, bg: isSel ? ColorSlot.select : null),
      );
      x += widths[i];
    }
  }

  int _rowWidth(List<int> widths) {
    var s = 0;
    for (final w in widths) {
      s += w;
    }
    return s;
  }

  void _renderScrollbar(buf, theme, bodyTop, inner, totalRows, bodyRows) {
    final thumbStyle = theme.id(ColorSlot.scrollbar);
    final col = inner.right - 1;
    final total = totalRows;
    final track = bodyRows;
    final thumbH = (track * track / total).ceil().clamp(1, track);
    final maxscroll = total - track;
    final scrolled = view.scrollTop.clamp(0, maxscroll);
    final start = scrolled == 0
        ? bodyTop
        : bodyTop + ((track - thumbH) * scrolled / maxscroll).floor();
    for (var r = bodyTop; r < bodyTop + track; r++) {
      if (r >= start && r < start + thumbH) {
        buf.set(r, col, '█', thumbStyle);
      }
    }
  }

  /// The window of row indices that should be visible, honouring scrollTop.
  List<int> _visibleWindow(int totalRows, int bodyRows) {
    final n = totalRows;
    final page = bodyRows > 0 ? bodyRows : 1;
    final top = view.scrollTop.clamp(0, (n - page).clamp(0, n));
    final end = (top + page).clamp(0, n);
    return [for (var i = top; i < end; i++) i];
  }

  void _renderEmpty(buf, theme, bodyTop, inner) {
    final dim = theme.id(ColorSlot.fgDim);
    final faint = theme.id(ColorSlot.fgFaint);
    final cx = inner.x + inner.width ~/ 2;
    final cy = bodyTop + inner.height ~/ 2;
    final glyph = '◐';
    buf.write(cy - 1, cx - glyph.length ~/ 2, glyph, faint);

    final filtered = view.filter != null && view.filter!.isNotEmpty;
    final msg = filtered
        ? 'no matches for “${view.filter}”'
        : 'no ${view.screen.title.toLowerCase()} yet';
    buf.write(cy, cx - msg.length ~/ 2, msg, dim);
    final hint = filtered ? 'esc clears filter' : 'press  a  to add';
    buf.write(
      cy + 1,
      (cx - hint.length ~/ 2).clamp(inner.x, inner.right - hint.length),
      hint,
      faint,
    );
  }

  /// Centred loading state per spec §6.3/§10: `spin + " loading X…"` in
  /// `fg.dim`. The table keeps its frame + header; only the body is the load
  /// UI. The spinner is static in a headless frame (it would animate on an
  /// async heartbeat in the live shell).
  void _renderLoading(buf, theme, bodyTop, inner) {
    final dim = theme.id(ColorSlot.fgDim);
    final spin = theme.id(ColorSlot.spin);
    final cx = inner.x + inner.width ~/ 2;
    final cy = bodyTop + inner.height ~/ 2;
    final frame = '⠋ loading ${view.screen.title.toLowerCase()}…';
    // Draw the spinner glyph first so it keeps its accent colour.
    buf.write(cy, cx - frame.length ~/ 2, '⠋', spin);
    buf.write(
      cy,
      cx - frame.length ~/ 2 + 1,
      ' loading ${view.screen.title.toLowerCase()}…',
      dim,
    );
  }

  void _renderError(buf, theme, bodyTop, inner) {
    final err = theme.id(ColorSlot.statusErr, bold: true);
    final fg = theme.id(ColorSlot.fg);
    final faint = theme.id(ColorSlot.fgFaint);
    final cx = inner.x + inner.width ~/ 2;
    final cy = bodyTop + inner.height ~/ 2;
    buf.write(cy - 1, cx - 1, '!', err);
    final msg = view.error ?? 'error'; // single wrapped line, hard-capped
    buf.write(cy, cx - msg.length ~/ 2, truncate(msg, inner.width - 2), fg);
    final hint = 'press  r  to retry';
    buf.write(
      cy + 1,
      (cx - hint.length ~/ 2).clamp(inner.x, inner.right - hint.length),
      hint,
      faint,
    );
  }
}
