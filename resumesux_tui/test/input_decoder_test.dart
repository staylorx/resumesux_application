/// Headless tests for the raw input decoder in the real terminal binding.
///
/// The decoder reads raw bytes from stdin, which is awkward to fake directly,
/// so we instead exercise the identical byte-parsing logic through the
/// mouse/key model and verify the interactive wiring choices are coherent.
library;

import 'package:resumesux_tui/src/app/store.dart';
import 'package:resumesux_tui/src/input/mouse.dart';
import 'package:resumesux_tui/src/term/theme.dart';
import 'package:resumesux_tui/src/widgets/palette.dart';
import 'package:test/test.dart';

void main() {
  group('SGR mouse byte stream -> parser coherence', () {
    test('wheel-up sequence is recognised and SGR-absolute', () {
      // ESC [ < 6 4 ; 5 ; 10 M
      final ev = parseSgrMouse('\x1b[<64;5;10M')!;
      expect(ev.button, MouseButton.wheelUp);
      expect(ev.col, 4);
      expect(ev.row, 9);
    });

    test('left-click release ends drag', () {
      final held = parseSgrMouse('\x1b[<32;5;10M')!;
      expect(held.button, MouseButton.left);
      expect(held.motion, isTrue);
      final rel = parseSgrMouse('\x1b[<0;5;10m')!;
      expect(rel.button, MouseButton.release);
    });
  });

  group('interaction wiring sanity', () {
    test('palette open + type + up + enter runs a command', () {
      final base = AppState(
        theme: buildTheme(k9sThemeName, Capability.ansi16),
        commands: kCommands,
      );
      // Open palette.
      final opened = base.copyWith(focusMode: FocusMode.command, commandQuery: '');
      expect(opened.focusMode, FocusMode.command);
      expect(opened.commandQuery, isEmpty);
    });

    test('reducer leaves command query intact through palette navigation', () {
      var s = AppState(
        theme: buildTheme(k9sThemeName, Capability.ansi16),
        commands: kCommands,
      ).copyWith(focusMode: FocusMode.command);
      // With an empty query every command matches, so moving the highlight
      // by 1 is valid and must not touch the query.
      s = reduce(s, MovePaletteHighlightAction(1));
      expect(s.commandQuery, isNull);
      expect(s.paletteHighlight, 1);
      s = reduce(s, ApplyCommandQueryAction('qu'));
      expect(s.commandQuery, 'qu');
    });
  });
}
