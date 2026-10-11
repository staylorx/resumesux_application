/// Real-terminal binding built on `dart_console`.
///
/// Owns raw mode, the alternate screen, cursor state and key reads. The app
/// shell drives [loopKey] synchronously inside a render loop. On exit the
/// terminal is always restored (normal screen, echo, cursor) so the user's
/// shell is left clean even on a crash path that unwinds through a
/// try/finally.
library;

import 'dart:io';

import 'package:dart_console/dart_console.dart' show Console, Key, ControlCharacter;

import 'ansi.dart';
import 'capabilities.dart';
import 'theme.dart';
import '../input/key_model.dart';
import '../input/mouse.dart';

/// A thin normalised key coming off the console/terminal. Keep the consumer
/// (widgets, keymap) decoupled from dart_console's [Key] so it is testable
/// without a real terminal.
class TermKey {
  final bool isControl;
  final String char;
  final Ctrl charCode; // one of [Ctrl]
  const TermKey({required this.isControl, required this.char, this.charCode = Ctrl.none});
}

/// A single input read off the terminal: either a key or a mouse event.
///
/// dart_console has no mouse support and its [Console.readKey] consumes raw
/// escape sequences, so a real SGR mouse byte stream would be corrupted by it.
/// The concrete terminal therefore reads raw bytes itself and emits
/// [TermMouse] directly; the headless fake terminals used by tests keep
/// [Terminal.readKey] so their key-driving loop is unchanged.
sealed class InputEvent {}

class TermKeyEvent extends InputEvent {
  final TermKey key;
  TermKeyEvent(this.key);
}

class TermMouseEvent extends InputEvent {
  final MouseEvent event;
  TermMouseEvent(this.event);
}

/// Abstraction the render loop depends on; a fake can drive tests headlessly.
abstract class Terminal {
  int get width;
  int get height;
  Capability get capability;
  void enter();
  void exit();
  void flush();
  void writeRaw(String s);
  TermKey? readKey();
  bool get hasKey; // whether a key is pending without blocking (best effort)

  /// Read the next input event (key or mouse). Default impl wraps [readKey];
  /// a mouse-capable terminal overrides this with a raw parser.
  InputEvent? readEvent() {
    final k = readKey();
    return k == null ? null : TermKeyEvent(k);
  }
}

/// Concrete terminal over dart_console's [Console].
class ConsoleTerminal implements Terminal {
  final Console console;
  final Theme theme;
  bool _entered = false;

  ConsoleTerminal(this.console, this.theme);

  @override
  Capability get capability => detectCapability();

  @override
  int get width {
    final w = console.windowWidth;
    return w > 0 ? w : 80;
  }

  @override
  int get height {
    final h = console.windowHeight;
    return h > 0 ? h : 24;
  }

  @override
  void enter() {
    if (_entered) return;
    _entered = true;
    console.rawMode = true;
    stdout.write(enterAltScreen);
    stdout.write(enableMouse);
    stdout.write(hideCursor);
    stdout.write(sgrReset);
    stdout.write('\x1b[2J');
    stdout.flush();
  }

  @override
  void exit() {
    if (!_entered) return;
    stdout.write(showCursor);
    stdout.write(disableMouse);
    stdout.write(leaveAltScreen);
    stdout.write(sgrReset);
    stdout.flush();
    console.rawMode = false;
    _entered = false;
  }

  @override
  void writeRaw(String s) => stdout.write(s);

  @override
  void flush() => stdout.flush();

  @override
  bool get hasKey => false; // dart_console has no non-blocking key peek

  /// Raw, self-contained input decoder.
  ///
  /// dart_console has no mouse support, so once mouse reporting is enabled the
  /// app reads raw bytes itself. This parses every recognised key (arrows,
  /// page, home/end, tab, shift-tab, enter, esc, printable) and SGR mouse
  /// events END TO END, so it never desyncs with a buffered reader. All reads
  /// go through [_takeByte] so nothing is lost.
  @override
  InputEvent? readEvent() {
    final b = _takeByte();
    if (b < 0) return null;

    // Printable ASCII (and most UTF-8 single bytes) — pass through.
    if (b >= 0x20 && b < 0x7f) {
      return TermKeyEvent(TermKey(isControl: false, char: String.fromCharCode(b)));
    }
    // Control characters (Ctrl+A..Z, Enter, Tab, Esc...).
    if (b == 0x0d || b == 0x0a) {
      return TermKeyEvent(TermKey(isControl: true, char: '', charCode: Ctrl.enter));
    }
    if (b == 0x09) {
      return TermKeyEvent(TermKey(isControl: true, char: '', charCode: Ctrl.tab));
    }
    if (b == 0x1b) {
      return _readEscape();
    }
    if (b == 0x7f || b == 0x08) {
      return TermKeyEvent(TermKey(isControl: true, char: '', charCode: Ctrl.backspace));
    }
    if (b >= 0x01 && b <= 0x1a) {
      // Ctrl+A..Z.
      final code = _ctrlFrom(b);
      return TermKeyEvent(TermKey(isControl: true, char: '', charCode: code));
    }
    // High bytes / multi-byte UTF-8: read the remainder of the rune.
    final rune = <int>[b];
    if (b >= 0xc2) {
      final n = _utf8Len(b);
      for (var i = 1; i < n; i++) {
        final c = _takeByte();
        if (c < 0) break;
        rune.add(c);
      }
    }
    return TermKeyEvent(
      TermKey(isControl: false, char: String.fromCharCodes(rune)),
    );
  }

  Ctrl _ctrlFrom(int b) {
    switch (b) {
      case 0x03:
        return Ctrl.ctrlC;
      case 0x0c:
        return Ctrl.ctrlL;
      case 0x02:
        return Ctrl.ctrlB;
      case 0x06:
        return Ctrl.ctrlF;
      case 0x12:
        return Ctrl.ctrlR;
      case 0x15:
        return Ctrl.ctrlU;
      case 0x0e:
        return Ctrl.ctrlN;
      case 0x10:
        return Ctrl.ctrlP;
      default:
        return Ctrl.none;
    }
  }

  int _utf8Len(int first) {
    if (first >= 0xf0) return 4;
    if (first >= 0xe0) return 3;
    if (first >= 0xc0) return 2;
    return 1;
  }

  /// Decode an `ESC` sequence: arrows, page/home/end (`ESC [ ~`), shift-tab
  /// (`ESC [ Z`), XTerm-style keys (`ESC O`), and SGR mouse (`ESC [ <`).
  InputEvent? _readEscape() {
    final b2 = _takeByte();
    if (b2 == -1) {
      return TermKeyEvent(TermKey(isControl: true, char: '', charCode: Ctrl.esc));
    }
    // SGR mouse: ESC [ < cb ; x ; y M|m
    if (b2 == 0x5b) {
      final b3 = _takeByte();
      if (b3 == 0x3c) {
        final sb = StringBuffer()
          ..writeCharCode(0x1b)
          ..writeCharCode(0x5b)
          ..writeCharCode(0x3c);
        while (true) {
          final c = _takeByte();
          if (c < 0) break;
          sb.writeCharCode(c);
          if (c == 0x4d || c == 0x6d) break;
          if (c == 0x1b) break;
        }
        final ev = parseSgrMouse(sb.toString());
        return ev == null ? null : TermMouseEvent(ev);
      }
      // CSI key: read the parameter(s) then the final byte.
      final params = StringBuffer();
      while (true) {
        final c = _takeByte();
        if (c < 0) return TermKeyEvent(_esc());
        final ch = String.fromCharCode(c);
        if ((c >= 0x40 && c <= 0x7e)) {
          return _csiKey(ch, params.toString());
        }
        params.write(ch);
      }
    }
    if (b2 == 0x4f) {
      // ESC O X (application cursor mode keys).
      final c = _takeByte();
      if (c < 0) return TermKeyEvent(_esc());
      switch (String.fromCharCode(c)) {
        case 'A':
          return TermKeyEvent(_ctrl(Ctrl.up));
        case 'B':
          return TermKeyEvent(_ctrl(Ctrl.down));
        case 'C':
          return TermKeyEvent(_ctrl(Ctrl.right));
        case 'D':
          return TermKeyEvent(_ctrl(Ctrl.left));
        case 'H':
          return TermKeyEvent(_ctrl(Ctrl.home));
        case 'F':
          return TermKeyEvent(_ctrl(Ctrl.end));
        default:
          return TermKeyEvent(_esc());
      }
    }
    // ESC followed by a normal char: Alt+char or bare ESC.
    if (b2 >= 0x20 && b2 < 0x7f) {
      // Bare Esc then char: treat the char as literal (Alt semantics not
      // used in v1). Return the char key.
      return TermKeyEvent(TermKey(isControl: false, char: String.fromCharCode(b2)));
    }
    return TermKeyEvent(_esc());
  }

  /// Map a CSI key `ESC [ params + final` to a [TermKeyEvent].
  TermKeyEvent? _csiKey(String fin, String params) {
    switch (fin) {
      case 'A':
        return TermKeyEvent(_ctrl(Ctrl.up));
      case 'B':
        return TermKeyEvent(_ctrl(Ctrl.down));
      case 'C':
        return TermKeyEvent(_ctrl(Ctrl.right));
      case 'D':
        return TermKeyEvent(_ctrl(Ctrl.left));
      case 'H':
        return TermKeyEvent(_ctrl(Ctrl.home));
      case 'F':
        return TermKeyEvent(_ctrl(Ctrl.end));
      case 'Z':
        return TermKeyEvent(_ctrl(Ctrl.shiftTab));
      case '~':
        switch (params) {
          case '1':
          case '7':
            return TermKeyEvent(_ctrl(Ctrl.home));
          case '3':
            return TermKeyEvent(_ctrl(Ctrl.delete));
          case '4':
          case '8':
            return TermKeyEvent(_ctrl(Ctrl.end));
          case '5':
            return TermKeyEvent(_ctrl(Ctrl.pageUp));
          case '6':
            return TermKeyEvent(_ctrl(Ctrl.pageDown));
          default:
            return null;
        }
      default:
        return null;
    }
  }

  TermKey _esc() => TermKey(isControl: true, char: '', charCode: Ctrl.esc);
  TermKey _ctrl(Ctrl c) => TermKey(isControl: true, char: '', charCode: c);

  /// Read a byte from stdin (raw mode), or -1 on EOF/error.
  int _readByte() {
    try {
      return stdin.readByteSync();
    } catch (_) {
      return -1;
    }
  }

  int _takeByte() => _readByte();

  @override
  TermKey? readKey() {
    Key key;
    try {
      key = console.readKey();
    } catch (_) {
      return null;
    }
    if (key.isControl) {
      return TermKey(isControl: true, char: '', charCode: _mapControl(key.controlChar));
    }
    return TermKey(isControl: false, char: key.char);
  }

  Ctrl _mapControl(ControlCharacter c) {
    switch (c) {
      case ControlCharacter.arrowUp:
        return Ctrl.up;
      case ControlCharacter.arrowDown:
        return Ctrl.down;
      case ControlCharacter.arrowLeft:
        return Ctrl.left;
      case ControlCharacter.arrowRight:
        return Ctrl.right;
      case ControlCharacter.pageUp:
        return Ctrl.pageUp;
      case ControlCharacter.pageDown:
        return Ctrl.pageDown;
      case ControlCharacter.home:
        return Ctrl.home;
      case ControlCharacter.end:
        return Ctrl.end;
      case ControlCharacter.escape:
        return Ctrl.esc;
      case ControlCharacter.enter:
        return Ctrl.enter;
      case ControlCharacter.tab:
        return Ctrl.tab;
      case ControlCharacter.ctrlC:
        return Ctrl.ctrlC;
      case ControlCharacter.ctrlL:
        return Ctrl.ctrlL;
      case ControlCharacter.backspace:
        return Ctrl.backspace;
      case ControlCharacter.delete:
        return Ctrl.delete;
      default:
        return Ctrl.none;
    }
  }
}
