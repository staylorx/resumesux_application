/// String helpers for cell-accurate layout: truncation with ellipsis,
/// padding, and right-alignment. Everything operates on single-width cells.
library;

/// Truncate [s] to at most [max] cells, appending an ellipsis '…' when it
/// doesn't fit in full. The result is always <= [max] cells.
String truncate(String s, int max) {
  if (max <= 0) return '';
  if (s.length <= max) return s;
  if (max == 1) return '…';
  // Leave room for the ellipsis.
  return '${s.substring(0, max - 1)}…';
}

/// Pad [s] (already truncated if needed) to exactly [width] cells. If [s] can
/// be wider it is left as-is (caller should truncate first).
String padRight(String s, int width) {
  if (s.length >= width) return s;
  return s + ' ' * (width - s.length);
}

/// Pad [s] to exactly [width] cells, right-aligned.
String padLeft(String s, int width) {
  if (s.length >= width) return s;
  return ' ' * (width - s.length) + s;
}
