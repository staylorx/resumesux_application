/// Normalised input model shared by the keymap and widgets.
///
/// Kept framework-agnostic so parsing and routing are testable without a real
/// terminal.
library;

/// Semantic control keys (a subset; see [TermKey]).
enum Ctrl {
  none,
  up,
  down,
  left,
  right,
  pageUp,
  pageDown,
  home,
  end,
  esc,
  enter,
  tab,
  shiftTab,
  backspace,
  delete,
  ctrlC,
  ctrlL,
  ctrlB,
  ctrlF,
  ctrlR,
  ctrlU,
  ctrlN,
  ctrlP,
}

/// A key read from the terminal: either a printable [char] or a [Ctrl] code.
class InputKey {
  final bool isControl;
  final String char;
  final Ctrl code;
  const InputKey.printable(this.char)
      : isControl = false,
        code = Ctrl.none;
  const InputKey.control(this.code)
      : isControl = true,
        char = '';

  bool get isEsc => isControl && code == Ctrl.esc;
  bool get isEnter => isControl && code == Ctrl.enter;
  bool get isTab => isControl && code == Ctrl.tab;
  bool get isBackspace =>
      isControl && (code == Ctrl.backspace || code == Ctrl.delete);
}
