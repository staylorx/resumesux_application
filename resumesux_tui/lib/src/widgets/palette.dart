/// Command palette: the `:` command bar line plus the fuzzy match overlay
/// drawn above it. Fuzzy match over [kCommands]; the top match is highlighted;
/// enter runs it, esc closes. Empty query shows the full list (max 8).
library;

import '../app/store.dart';
import '../term/screen_buffer.dart';
import '../term/strings.dart';
import '../term/theme.dart';
import 'rect.dart';

/// Global command registry (v1, from spec §9.3).
const List<Command> kCommands = [
  Command('applicants', ['app'], 'switch view to Applicants'),
  Command('jobreqs', ['jobs'], 'switch view to JobReqs'),
  Command('applications', ['apps'], 'switch view to Applications'),
  Command('gigs', ['g'], 'switch view to Gigs'),
  Command('assets', ['a'], 'switch view to Assets'),
  Command('generate', ['gen'], 'generate resume for selected'),
  Command('filter <q>', ['f'], 'set filter query'),
  Command('help', ['h', '?'], 'open help view'),
  Command('quit', ['q'], 'quit app'),
  Command('theme <k9s|light>', ['th'], 'switch theme'),
  Command('clear', [], 'clear current filter'),
];

/// Fuzzy-subsequence match: returns a score (>= 0 means match) — higher is
/// better. Character order must be preserved.
int fuzzyScore(String query, String candidate) {
  if (query.isEmpty) return 0;
  var qi = 0;
  var bonus = 0;
  for (var i = 0; i < candidate.length && qi < query.length; i++) {
    if (candidate[i].toLowerCase() == query[qi].toLowerCase()) {
      bonus += 1;
      qi++;
    }
  }
  return qi == query.length ? bonus : -1;
}

class CommandPalette {
  final Rect rect; // the command bar region (bottom row)
  final AppState state;
  CommandPalette(this.rect, this.state);

  int get width => rect.width;

  /// Commands matching the current query, best first — delegated to the
  /// store's single source of truth so widget + keymap never disagree.
  List<Command> matches() => paletteMatches(state);

  void render(ScreenBuffer buf, Theme theme) {
    // Command bar line (height 1 at rect.y).
    final barBg = theme.id(ColorSlot.cmdFg, bg: ColorSlot.cmdBg);
    buf.fillRect(rect.y, rect.x, rect.y, rect.right - 1, ' ', barBg);

    final prompt = theme.id(ColorSlot.cmdPrompt, bg: ColorSlot.cmdBg);
    final input = theme.id(ColorSlot.cmdFg, bg: ColorSlot.cmdBg);
    buf.write(rect.y, rect.x + 1, ':', prompt);
    final shown = state.commandQuery ?? '';
    buf.write(rect.y, rect.x + 3, truncate(shown, width - 8), input);

    // Match overlay drawn above the bar.
    final matched = matches();
    final n = matched.length < 8 ? matched.length : 8;
    final oy0 = rect.y - (1 + n + 1);
    final ox0 = rect.x + 2;
    final ow = (42).clamp(20, width);

    // draw list boxes (simple lines). The highlighted row is driven by
    // state.paletteHighlight (moved with j/k, Ctrl+Up/Down).
    for (var i = 0; i < n; i++) {
      final row = oy0 + 1 + i;
      final m = matched[i];
      final sel = i == state.paletteHighlight;
      final s = sel
          ? theme.id(ColorSlot.selectFg, bg: ColorSlot.select)
          : theme.id(ColorSlot.fg);
      final label = truncate('${m.name}   ${m.hint}', ow - 4);
      buf.write(row, ox0 + 1, label, s);
    }
    // hint line on the right of the bar
    final hint = 'enter run · esc close · j/k';
    buf.write(rect.y, rect.right - hint.length - 1, hint, prompt);
  }
}
