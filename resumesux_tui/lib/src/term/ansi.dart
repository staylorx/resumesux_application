/// ANSI escape building helpers.
///
/// All output goes through these builders so the rest of the app never embeds
/// a raw escape sequence. The renderer (see [ScreenBuffer]) emits runs of
/// identically-styled cells as a single escape; these helpers produce the
/// primitives that run is made of.
library;

/// An SGR (Select Graphic Rendition) attribute key used to key style runs.
///
/// Values are chosen so that equal (fg,bg,bold,faint) tuples collide to the
/// same key. We avoid relying on object identity by folding the four fields
/// into a single int.
typedef StyleKey = int;

/// Cursor-position escape: moves the cursor to 1-based [row]/[col].
String cursorPos(int row, int col) => '\x1b[${row + 1};${col + 1}H';

/// Hide / show the terminal cursor.
const String hideCursor = '\x1b[?25l';
const String showCursor = '\x1b[?25h';

/// Enter / leave the alternate screen buffer.
const String enterAltScreen = '\x1b[?1049h';
const String leaveAltScreen = '\x1b[?1049l';

/// Reset all SGR attributes (color, bold, faint, ...).
const String sgrReset = '\x1b[m';

/// Classic 3/4-bit foreground color base (used as the low bits of a color id).
const int fgBase = 30;
const int bgBase = 40;

/// Enables SGR mouse so wheel/click coords are absolute (works in tmux).
const String enableMouse = '\x1b[?1000;1006h';
const String disableMouse = '\x1b[?1000;1006l';
