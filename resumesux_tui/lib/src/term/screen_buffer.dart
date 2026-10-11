/// In-memory screen buffer + dirty-cell diff renderer.
///
/// Every frame is drawn into an immutable-ish [ScreenBuffer], then [Renderer]
/// diffs it against the previous frame and emits only changed cells to the
/// terminal (cursor-position + text + the minimal SGR transition). This is the
/// "no clear-and-redraw flicker" rule from the spec (§6.5): there is never a
/// full-screen erase.
library;

import 'ansi.dart';
import 'theme.dart';

/// A single cell of the buffer. [style] is a theme style id (see Theme); a
/// value of 0 means "plain/reset".
class Cell {
  const Cell(this.char, this.style);
  final String char;
  final int style;

  bool get isBlank => char == ' ';
}

/// The off-screen canvas. [cols] x [rows], all cells initially blank in the
/// plain style.
class ScreenBuffer {
  final int cols;
  final int rows;
  final List<int> _styles;
  final List<String> _chars;

  ScreenBuffer(this.cols, this.rows)
      : _styles = List.filled(cols * rows, 0),
        _chars = List.filled(cols * rows, ' ');

  int get size => cols * rows;

  int _idx(int row, int col) => row * cols + col;

  void set(int row, int col, String char, [int style = 0]) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return;
    final i = _idx(row, col);
    _chars[i] = char;
    _styles[i] = style;
  }

  void style(int row, int col, int style) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return;
    _styles[_idx(row, col)] = style;
  }

  /// Overwrite a horizontal range in [row] with [text], clipping to the
  /// buffer. Single-width cells only.
  void write(int row, int col, String text, [int style = 0]) {
    if (row < 0 || row >= rows) return;
    for (var i = 0; i < text.length; i++) {
      final c = col + i;
      if (c >= cols) break;
      if (c < 0) continue;
      set(row, c, text[i], style);
    }
  }

  /// Fill a rectangle with a fill character and style.
  void fillRect(int r0, int c0, int r1, int c1, String char, int style) {
    for (var r = r0; r <= r1 && r < rows; r++) {
      if (r < 0) continue;
      for (var c = c0; c <= c1 && c < cols; c++) {
        if (c < 0) continue;
        set(r, c, char, style);
      }
    }
  }

  Cell cellAt(int row, int col) =>
      Cell(_chars[_idx(row, col)], _styles[_idx(row, col)]);

}

/// Emits the minimal sequence to transform [prev] into [buf]. [theme] resolves
/// style ids to their SGR sequences. Returns the ANSI string to write to the
/// terminal (empty string if nothing changed).
String renderDiff(ScreenBuffer? prev, ScreenBuffer buf, Theme theme) {
  final sb = StringBuffer();
  int curRow = -1;
  int curCol = -1;
  int curStyle = -1;

  void moveTo(int row, int col) {
    if (curRow != row) {
      sb.write(cursorPos(row, col));
      curRow = row;
      curCol = col;
    } else if (curCol != col) {
      sb.write(cursorPos(row, col));
      curCol = col;
    }
  }

  void setStyle(int id) {
    if (id == curStyle) return;
    sb.write(theme.seqFor(id));
    curStyle = id;
  }

  if (prev == null || prev.cols != buf.cols || prev.rows != buf.rows) {
    // Full repaint (first frame or resize): restart and draw every cell.
    sb.write(sgrReset);
    curStyle = 0;
    for (var row = 0; row < buf.rows; row++) {
      for (var col = 0; col < buf.cols; col++) {
        final c = buf.cellAt(row, col);
        if (c.char == ' ' && c.style == 0) continue;
        setStyle(c.style);
        moveTo(row, col);
        sb.write(c.char);
        curCol = col + 1;
      }
    }
    if (curStyle != 0) sb.write(sgrReset);
    return sb.toString();
  }

  for (var row = 0; row < buf.rows; row++) {
    for (var col = 0; col < buf.cols; col++) {
      final p = prev.cellAt(row, col);
      final c = buf.cellAt(row, col);
      if (p.char == c.char && p.style == c.style) continue;
      setStyle(c.style);
      moveTo(row, col);
      sb.write(c.char);
      curCol = col + 1;
    }
  }
  if (curStyle > 0) sb.write(sgrReset);
  return sb.toString();
}
