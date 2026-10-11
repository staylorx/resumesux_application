/// Theme tokens and ANSI style resolution.
///
/// Every widget references semantic [ColorSlot]s, never raw ANSI values, so a
/// theme swap is a data-only change. Two themes ship: [k9s] (default) and
/// [light]. Each token has a 16-color-safe ANSI value and a truecolor RGB
/// value; the active [Capability] decides which is emitted.
library;

import 'ansi.dart';

/// Terminal color capability.
enum Capability {
  /// Classic 4-bit ANSI (16 colors). Always safe.
  ansi16,

  /// 24-bit truecolor (COLORTERM=truecolor or TERM mentions truecolor).
  truecolor,
}

/// Semantic color roles. Widgets reference these by name (never raw ANSI).
enum ColorSlot {
  fg,
  fgDim,
  fgFaint,
  fgAccent,
  fgTitle,
  headerBg,
  headerFg,
  border,
  borderFocus,
  borderTitle,
  select,
  selectFg,
  cursor,
  statusOk,
  statusWarn,
  statusErr,
  statusInfo,
  cmdBg,
  cmdFg,
  cmdPrompt,
  modalBg,
  modalBorder,
  helpKbd,
  helpKbdFg,
  tagBg,
  tagFg,
  progressBar,
  progressTrack,
  spin,
  scrollbar,
  appBg,
}

/// A token color: a 4-bit ANSI index (0..15, foreground numbering) plus RGB.
class TokenColor {
  final int ansiIndex;
  final String rgb;

  const TokenColor(this.ansiIndex, this.rgb);

  bool get isBright => ansiIndex >= 8;

  String fgSeq() {
    if (!isBright) return '\x1b[${fgBase + ansiIndex}m';
    return '\x1b[${fgBase + 60 + (ansiIndex - 8)}m';
  }

  String bgSeq() {
    if (!isBright) return '\x1b[${bgBase + ansiIndex}m';
    return '\x1b[${bgBase + 60 + (ansiIndex - 8)}m';
  }

  String rgbFgSeq() {
    final r = _hex(rgb, 1);
    final g = _hex(rgb, 3);
    final b = _hex(rgb, 5);
    return '\x1b[38;2;$r;$g;${b}m';
  }

  String rgbBgSeq() {
    final r = _hex(rgb, 1);
    final g = _hex(rgb, 3);
    final b = _hex(rgb, 5);
    return '\x1b[48;2;$r;$g;${b}m';
  }

  static int _hex(String s, int start) =>
      int.parse(s.substring(start, start + 2), radix: 16);
}

class TokenColorPair {
  final TokenColor fg;
  final TokenColor bg;
  const TokenColorPair(this.fg, this.bg);
  const TokenColorPair.mono(TokenColor c)
      : fg = c,
        bg = const TokenColor(0, '#000000');
}

/// Style id encoding: low 2 bits = attrs, next 5 = bg index (+1, 0=none),
/// next ~8 = fg slot. Deterministic so identical styles collide.
const int _attrsBits = 2;
const int _bgBits = 5;
const int _bgMul = 1 << _attrsBits;
const int _fgMul = 1 << (_attrsBits + _bgBits);

/// A resolved, lazily-cached style set.
class Theme {
  final String name;
  final Capability cap;
  final Map<ColorSlot, TokenColorPair> colors;
  final Map<int, String> _seqCache = {};

  Theme._(this.name, this.cap, this.colors);

  TokenColorPair pair(ColorSlot s) => colors[s]!;

  String _seqFor(ColorSlot fg, ColorSlot? bg, bool bold, bool dim) {
    final fp = pair(fg);
    final f = cap == Capability.truecolor ? fp.fg.rgbFgSeq() : fp.fg.fgSeq();
    var s = f;
    if (bg != null) {
      final bp = pair(bg);
      s += cap == Capability.truecolor ? bp.bg.rgbBgSeq() : bp.bg.bgSeq();
    }
    if (bold) s += '\x1b[1m';
    if (dim) s += '\x1b[2m';
    return s;
  }

  /// Deterministic style id.
  int id(ColorSlot fg, {ColorSlot? bg, bool bold = false, bool dim = false}) {
    final attrs = (bold ? 1 : 0) | (dim ? 2 : 0);
    final bgi = (bg?.index ?? -1) + 1;
    final fgi = fg.index;
    final id = fgi * _fgMul + bgi * _bgMul + attrs;
    _seqCache.putIfAbsent(id, () => _seqFor(fg, bg, bold, dim));
    return id;
  }

  int get plainId => id(ColorSlot.fg);

  String seqFor(int id) => _seqCache[id] ?? sgrReset;
}

const int _c1 = 1, _c2 = 2, _c3 = 3, _c6 = 6, _c7 = 7, _c8 = 8, _c12 = 12,
    _c14 = 14, _c15 = 15;

List<TokenColorPair> _k9s() => [
      const TokenColorPair.mono(TokenColor(_c7, '#d8d8d8')), // fg
      const TokenColorPair.mono(TokenColor(_c8, '#8f96a0')), // fgDim
      const TokenColorPair.mono(TokenColor(_c8, '#5f6670')), // fgFaint
      const TokenColorPair.mono(TokenColor(_c6, '#56b6c2')), // fgAccent
      const TokenColorPair.mono(TokenColor(_c15, '#eeeeee')), // fgTitle
      const TokenColorPair(TokenColor(_c15, '#f0f1f3'), TokenColor(4, '#3e4a61')), // headerBg
      const TokenColorPair.mono(TokenColor(_c7, '#f0f1f3')), // headerFg
      const TokenColorPair.mono(TokenColor(_c8, '#6b7280')), // border
      const TokenColorPair.mono(TokenColor(_c6, '#56b6c2')), // borderFocus
      const TokenColorPair.mono(TokenColor(_c15, '#dfe3e8')), // borderTitle
      const TokenColorPair(TokenColor(_c15, '#ffffff'), TokenColor(6, '#264f5c')), // select
      const TokenColorPair.mono(TokenColor(_c15, '#ffffff')), // selectFg
      const TokenColorPair.mono(TokenColor(_c14, '#7fdbca')), // cursor
      const TokenColorPair.mono(TokenColor(_c2, '#89ca78')), // statusOk
      const TokenColorPair.mono(TokenColor(_c3, '#e5c07b')), // statusWarn
      const TokenColorPair.mono(TokenColor(_c1, '#e06c75')), // statusErr
      const TokenColorPair.mono(TokenColor(_c12, '#61afef')), // statusInfo
      const TokenColorPair(TokenColor(_c15, '#e6e6e6'), TokenColor(0, '#1e2730')), // cmdBg
      const TokenColorPair.mono(TokenColor(_c15, '#e6e6e6')), // cmdFg
      const TokenColorPair.mono(TokenColor(_c6, '#56b6c2')), // cmdPrompt
      const TokenColorPair(TokenColor(_c15, '#cfd4da'), TokenColor(0, '#1b242e')), // modalBg
      const TokenColorPair.mono(TokenColor(_c15, '#cfd4da')), // modalBorder
      const TokenColorPair(TokenColor(_c15, '#ffffff'), TokenColor(8, '#3a4450')), // helpKbd
      const TokenColorPair.mono(TokenColor(_c15, '#ffffff')), // helpKbdFg
      const TokenColorPair(TokenColor(_c7, '#e8eaed'), TokenColor(4, '#3e4a61')), // tagBg
      const TokenColorPair.mono(TokenColor(_c7, '#e8eaed')), // tagFg
      const TokenColorPair.mono(TokenColor(_c6, '#56b6c2')), // progressBar
      const TokenColorPair.mono(TokenColor(_c8, '#3a4450')), // progressTrack
      const TokenColorPair.mono(TokenColor(_c6, '#56b6c2')), // spin
      const TokenColorPair.mono(TokenColor(_c8, '#4b5563')), // scrollbar
      const TokenColorPair.mono(TokenColor(0, '#10151c')), // appBg
    ];

List<TokenColorPair> _light() {
  final map = List<TokenColorPair>.of(_k9s());
  TokenColorPair mono(int i, String rgb) => TokenColorPair.mono(TokenColor(i, rgb));
  map[ColorSlot.fg.index] = mono(0, '#1f2328');
  map[ColorSlot.fgDim.index] = mono(0, '#57606a');
  map[ColorSlot.fgFaint.index] = mono(7, '#6e7781');
  map[ColorSlot.fgAccent.index] = mono(4, '#0969da');
  map[ColorSlot.fgTitle.index] = mono(0, '#111111');
  map[ColorSlot.headerBg.index] = const TokenColorPair(TokenColor(0, '#1f2328'), TokenColor(7, '#eaeef2'));
  map[ColorSlot.headerFg.index] = mono(0, '#1f2328');
  map[ColorSlot.border.index] = mono(7, '#d0d7de');
  map[ColorSlot.borderFocus.index] = mono(4, '#0969da');
  map[ColorSlot.borderTitle.index] = mono(0, '#1f2328');
  map[ColorSlot.select.index] = const TokenColorPair(TokenColor(0, '#ffffff'), TokenColor(4, '#b6d3ff'));
  map[ColorSlot.selectFg.index] = mono(0, '#0b3a82');
  map[ColorSlot.cursor.index] = mono(4, '#0969da');
  map[ColorSlot.statusOk.index] = mono(2, '#1a7f37');
  map[ColorSlot.statusWarn.index] = mono(3, '#9a6700');
  map[ColorSlot.statusErr.index] = mono(1, '#cf222e');
  map[ColorSlot.statusInfo.index] = mono(4, '#0969da');
  map[ColorSlot.cmdBg.index] = const TokenColorPair(TokenColor(0, '#1f2328'), TokenColor(7, '#f6f8fa'));
  map[ColorSlot.cmdFg.index] = mono(0, '#1f2328');
  map[ColorSlot.cmdPrompt.index] = mono(4, '#0969da');
  map[ColorSlot.modalBg.index] = const TokenColorPair(TokenColor(0, '#1f2328'), TokenColor(15, '#ffffff'));
  map[ColorSlot.modalBorder.index] = mono(0, '#6e7781');
  map[ColorSlot.helpKbd.index] = const TokenColorPair(TokenColor(0, '#1f2328'), TokenColor(7, '#eaeef2'));
  map[ColorSlot.helpKbdFg.index] = mono(0, '#1f2328');
  map[ColorSlot.tagBg.index] = const TokenColorPair(TokenColor(0, '#1f2328'), TokenColor(7, '#ddf4ff'));
  map[ColorSlot.tagFg.index] = mono(4, '#0969da');
  map[ColorSlot.progressBar.index] = mono(4, '#0969da');
  map[ColorSlot.progressTrack.index] = mono(7, '#afb8c1');
  map[ColorSlot.spin.index] = mono(4, '#0969da');
  map[ColorSlot.scrollbar.index] = mono(7, '#afb8c1');
  map[ColorSlot.appBg.index] = mono(15, '#ffffff');
  return map;
}

/// Build a [Theme] from a name ('k9s' or 'light') and a terminal [Capability].
Theme buildTheme(String name, Capability cap) {
  final pairs = name == 'light' ? _light() : _k9s();
  return Theme._(name, cap, {
    for (var i = 0; i < ColorSlot.values.length; i++) ColorSlot.values[i]: pairs[i],
  });
}

const k9sThemeName = 'k9s';
