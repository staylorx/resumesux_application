/// A rectangle in buffer coordinates (top-left inclusive, bottom-right
/// exclusive).
library;

class Rect {
  final int x, y, width, height;
  const Rect(this.x, this.y, this.width, this.height);

  int get right => x + width;
  int get bottom => y + height;

  /// Inner rect with [pad] cells of margin on every side.
  Rect inset(int pad) =>
      Rect(x + pad, y + pad, width - 2 * pad, height - 2 * pad);

  bool contains(int col, int row) =>
      col >= x && col < right && row >= y && row < bottom;
}
