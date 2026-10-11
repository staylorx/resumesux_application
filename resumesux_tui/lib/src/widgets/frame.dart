/// Bordered frame with optional inset title (k9s-style pane chrome).
///
/// Draws a single-line box-drawing border on the given [Rect] and optionally
/// a title on the top border. Focused panes get the `border.focus` color;
/// unfocused get `border`. This is the base of both the table and detail
/// panes.
library;

import '../term/screen_buffer.dart';
import '../term/strings.dart';
import '../term/theme.dart';
import 'rect.dart';

class Frame {
  final String title;
  final bool focused;
  final Rect rect;
  final ColorSlot? errorColor; // when non-null the border turns this color

  Frame({
    required this.rect,
    required this.title,
    this.focused = false,
    this.errorColor,
  });

  /// Inner buffer area (excludes the 1-cell border).
  Rect get inner => rect.inset(1);

  ColorSlot get _borderColor {
    if (errorColor != null) return errorColor!;
    return focused ? ColorSlot.borderFocus : ColorSlot.border;
  }

  void render(ScreenBuffer buf, Theme theme) {
    final b = theme.id(_borderColor);
    final t = theme.id(ColorSlot.borderTitle, bold: true);
    final tl = '┌', tr = '┐', bl = '└', br = '┘', h = '─', v = '│';

    // Horizontal edges
    for (var c = rect.x + 1; c < rect.right - 1; c++) {
      buf.set(rect.y, c, h, b);
      buf.set(rect.bottom - 1, c, h, b);
    }
    // Vertical edges
    for (var r = rect.y + 1; r < rect.bottom - 1; r++) {
      buf.set(r, rect.x, v, b);
      buf.set(r, rect.right - 1, v, b);
    }
    buf.set(rect.y, rect.x, tl, b);
    buf.set(rect.y, rect.right - 1, tr, b);
    buf.set(rect.bottom - 1, rect.x, bl, b);
    buf.set(rect.bottom - 1, rect.right - 1, br, b);

    if (title.isNotEmpty) {
      // Title sits on the top border, uppercase, 2 cells in.
      final text = title.toUpperCase();
      buf.write(rect.y, rect.x + 2, truncate(text, rect.width - 4), t);
    }
  }
}
