/// SGR mouse-protocol parser.
///
/// dart_console has no mouse support and its [Console.readKey] swallows
/// `\x1b[` escape sequences, so SGR mouse bytes (`\x1b[<cb;col;row M|m`)
/// arriving on stdin would otherwise be corrupted. This module parses raw
/// SGR mouse sequences into a [MouseEvent], independent of any terminal
/// library, so it is unit-testable with plain strings.
///
/// The application enables mouse reporting with the ANSI sequence in
/// `term/ansi.dart` (`?1000;1006h`) and feeds raw input bytes here.
library;

/// Mouse button / motion code from an SGR event.
enum MouseButton {
  left,
  middle,
  right,
  release,
  wheelUp,
  wheelDown,
  none,
}

/// A parsed SGR mouse event: [col]/[row] are 0-based table coordinates.
class MouseEvent {
  final MouseButton button;
  final int col;
  final int row;
  final bool motion; // button held + moved (drag)
  final bool shift;
  final bool meta;
  final bool ctrl;

  const MouseEvent({
    required this.button,
    required this.col,
    required this.row,
    this.motion = false,
    this.shift = false,
    this.meta = false,
    this.ctrl = false,
  });
}

/// Returns true if [s] looks like an SGR mouse sequence start (`ESC[<`).
bool isSgrMouseStart(String s) =>
    s.length >= 2 && s.codeUnitAt(0) == 0x1b && s.codeUnitAt(1) == 0x5b;

/// Parse an SGR mouse sequence such as `\x1b[<0;5;10M` or `\x1b[<64;5;10M`
/// (wheel up adds 64, wheel down 65). Trailing `M` = press, `m` = release.
/// Returns null if the sequence is malformed.
MouseEvent? parseSgrMouse(String s) {
  if (!isSgrMouseStart(s)) return null;
  // Strip the leading ESC [ < ; then read "cb;x;y" then the final char.
  var i = 2; // past ESC and [
  if (i >= s.length || s[i] != '<') return null;
  i++;

  int? readInt() {
    if (i >= s.length) return null;
    final start = i;
    while (i < s.length && s[i] != ';' && s[i] != 'M' && s[i] != 'm') {
      i++;
    }
    if (i == start) return null;
    final v = int.tryParse(s.substring(start, i));
    return v;
  }

  final cb = readInt();
  if (cb == null || i >= s.length || s[i] != ';') return null;
  i++; // consume ';'
  final x = readInt();
  if (x == null || i >= s.length || s[i] != ';') return null;
  i++; // consume ';'
  final y = readInt();
  if (y == null || i >= s.length) return null;
  final kind = s[i]; // 'M' press, 'm' release

  // Decode modifier bits (32 = shift, 8 = meta/alt, 4 = ctrl).
  final shift = (cb & 32) != 0;
  final meta = (cb & 8) != 0;
  final ctrl = (cb & 4) != 0;

  // Motion bit 32 is shared with shift in the press codes; motion-only
  // events use cb & 32 as the motion flag (button 0..2 + 32 = drag move).
  final motion = (cb & 32) != 0 && (cb & 0x03) <= 2;

  final base = cb & 0x43; // mask to button + wheel bits (0..2, 64, 65, 66, 67)
  MouseButton button;
  if (kind == 'm') {
    button = MouseButton.release;
  } else if (base == 64) {
    button = MouseButton.wheelUp;
  } else if (base == 65) {
    button = MouseButton.wheelDown;
  } else {
    switch (cb & 0x03) {
      case 0:
        button = MouseButton.left;
        break;
      case 1:
        button = MouseButton.middle;
        break;
      case 2:
        button = MouseButton.right;
        break;
      default:
        button = MouseButton.none;
    }
  }

  // Coordinates are 1-based in the protocol.
  return MouseEvent(
    button: button,
    col: x - 1,
    row: y - 1,
    motion: motion,
    shift: shift,
    meta: meta,
    ctrl: ctrl,
  );
}
