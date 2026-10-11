/// Full-screen help view (`?`).
///
/// A two-column table of key → action, grouped by section, with `help.kbd`
/// keycap chips. Replaces the main content; `esc` returns without losing any
/// state (stored in [AppState], not here).
library;

import '../app/store.dart';
import '../term/screen_buffer.dart';
import '../term/strings.dart';
import '../term/theme.dart';
import 'rect.dart';

class HelpSection {
  final String name;
  final Map<String, String> keys;
  const HelpSection(this.name, this.keys);
}

const List<HelpSection> kHelpSections = [
  HelpSection('Navigation', {
    '↑/k ↓/j': 'move cursor',
    'PgUp/PgDn': 'page up/down',
    'g / G': 'first / last row',
    'Tab / Shift+Tab': 'next / previous pane',
    'Enter': 'open + focus detail',
    'Esc': 'back / close',
  }),
  HelpSection('Actions', {
    's': 'cycle sort (score)',
    'r': 'refresh / retry',
    'c': 'generate for selected',
    'd': 'delete selected (confirm)',
    'a': 'add (stub)',
  }),
  HelpSection('Command bar', {
    ':': 'open command palette',
    ':quit': 'quit',
    ':theme light': 'switch theme',
    ':applicants': 'switch to applicants',
  }),
  HelpSection('Mouse', {
    'click row': 'select',
    'wheel': 'scroll pane',
    'click pane': 'focus pane',
  }),
  HelpSection('Help', {
    '?': 'toggle this help',
    'q / Ctrl+C': 'quit',
  }),
];

class Help {
  final Rect rect;
  final AppState state;
  Help(this.rect, this.state);

  void render(ScreenBuffer buf, Theme theme) {
    // Full-content background.
    final bg = theme.id(ColorSlot.fg, bg: ColorSlot.appBg);
    buf.fillRect(rect.y, rect.x, rect.bottom - 1, rect.right - 1, ' ', bg);

    final keyFg = theme.id(ColorSlot.fgAccent);
    final actionFg = theme.id(ColorSlot.fgDim);
    final hdrStyle = theme.id(ColorSlot.fgTitle, bold: true);

    var y = rect.y + 1;
    final xKey = rect.x + 2;
    final xAction = rect.x + 26;

    for (final section in kHelpSections) {
      buf.write(y, xKey, section.name.toUpperCase(), hdrStyle);
      y += 2;
      for (final e in section.keys.entries) {
        if (y >= rect.bottom - 1) break;
        final key = truncate(e.key, 22);
        buf.write(y, xKey, padRight(key, 22), keyFg);
        buf.write(y, xAction, truncate(e.value, rect.right - xAction - 1), actionFg);
        y++;
      }
      y++;
    }
  }
}
