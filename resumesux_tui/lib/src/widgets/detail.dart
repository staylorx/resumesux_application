/// Right-hand detail pane (k9s info-view analogue).
///
/// Renders key/value groups for the selected row of a table. Section headers
/// are uppercase, `fg.accent`, preceded by a blank line. Keys are padded to a
/// consistent label column and drawn in `fg.dim`; long values hard-wrap with
/// continuation lines aligned to the value column. Independently scrollable.
library;

import '../term/screen_buffer.dart';
import '../term/strings.dart';
import '../term/theme.dart';
import 'frame.dart';
import 'rect.dart';

/// One key/value group in the detail pane.
class DetailSection {
  final String header;
  final List<DetailEntry> entries;
  const DetailSection(this.header, this.entries);
}

class DetailEntry {
  final String label;
  final String value;
  final ColorSlot? valueColor;
  const DetailEntry(this.label, this.value, {this.valueColor});
}

class Detail {
  final Rect rect;
  final bool focused;
  final List<DetailSection> sections;
  final int scrollTop; // lines scrolled (scrollbar)
  final String? emptyMessage;

  Detail({
    required this.rect,
    required this.focused,
    required this.sections,
    this.scrollTop = 0,
    this.emptyMessage,
  });

  void render(ScreenBuffer buf, Theme theme) {
    final labelW = 14;
    final valueX = rect.x + 1 + 2 + labelW; // panel.pad(1) + padding(2) + label
    final contentW = (rect.right - 1) - valueX;

    Frame(rect: rect, title: '', focused: focused).render(buf, theme);

    if (sections.isEmpty) {
      final dim = theme.id(ColorSlot.fgDim);
      final msg = emptyMessage ?? 'nothing selected';
      buf.write(rect.y + 2, valueX, msg, dim);
      return;
    }

    final keyStyle = theme.id(ColorSlot.fgDim);
    final hdrStyle = theme.id(ColorSlot.fgAccent, bold: true);

    // Lay lines out with wrapping; the first line of a wrapped value aligns
    // at valueX, continuation lines as well (no hanging indent).
    final lines = <_Line>[];
    for (final s in sections) {
      lines.add(_Line(hdrStyle, s.header, isHeader: true));
      lines.add(_Line(theme.id(ColorSlot.appBg), '', isSpacer: true));
      for (final e in s.entries) {
        final wrapped = _wrap(e.value, contentW);
        final valueStyleId = theme.id(e.valueColor ?? ColorSlot.fg);
        if (wrapped.isEmpty) {
          lines.add(_Line(keyStyle, e.label, labelWidth: labelW, value: '', valueStyle: valueStyleId));
          continue;
        }
        lines.add(_Line(
          keyStyle,
          e.label,
          labelWidth: labelW,
          value: wrapped[0],
          valueStyle: valueStyleId,
        ));
        for (var i = 1; i < wrapped.length; i++) {
          lines.add(_Line(
            keyStyle,
            '',
            labelWidth: 0,
            value: wrapped[i],
            valueStyle: valueStyleId,
            continuation: true,
          ));
        }
      }
    }

    final top = rect.y + 1; // inside top border
    final bottom = rect.bottom - 1;
    final pageH = (bottom - top).clamp(0, 1 << 30);
    var line = top - scrollTop;
    for (final l in lines) {
      if (line >= bottom) break;
      if (line >= top) {
        _drawLine(buf, theme, line, l, rect.x + 1 + 1, valueX, contentW, labelW);
      }
      line++;
    }

    // Scrollbar if content overflows.
    if (lines.length > pageH) {
      _drawScrollbar(buf, theme, top, bottom, lines.length, pageH);
    }
  }

  void _drawLine(buf, theme, row, _Line l, int panelX, int valueX, int contentW, int labelW) {
    if (l.isHeader) {
      buf.write(row, panelX, l.label, l.style);
      return;
    }
    if (l.isSpacer) return; // blank line leaves app bg
    // key column (only on first line of a value)
    if (!l.continuation && l.value != null) {
      final key = truncate(padRight(l.label, labelW), labelW);
      buf.write(row, panelX, key, l.style);
      buf.write(row, valueX, truncate(l.value!, contentW), l.valueStyle!);
    } else if (l.continuation) {
      buf.write(row, valueX, truncate(l.value!, contentW), l.valueStyle!);
    }
  }

  void _drawScrollbar(buf, theme, top, bottom, totalLines, pageH) {
    final thumbStyle = theme.id(ColorSlot.scrollbar);
    final col = rect.right - 1;
    final track = pageH;
    final thumbH = (track * track / totalLines).ceil().clamp(1, track);
    final maxscroll = (totalLines - track).clamp(0, totalLines);
    final scrolled = scrollTop.clamp(0, maxscroll);
    final start = maxscroll == 0
        ? top
        : top + ((track - thumbH) * scrolled / maxscroll).floor();
    for (var r = top; r < bottom; r++) {
      if (r >= start && r < start + thumbH) buf.set(r, col, '█', thumbStyle);
    }
  }

  List<String> _wrap(String s, int width) {
    if (width <= 0) return const [];
    if (s.length <= width) return [s];
    final out = <String>[];
    var rest = s;
    while (rest.length > width) {
      // wrap on a space near the boundary if possible
      var cut = rest.lastIndexOf(' ', width);
      if (cut < width ~/ 2) cut = width;
      out.add(rest.substring(0, cut).trimRight());
      rest = rest.substring(cut).trimLeft();
    }
    if (rest.isNotEmpty) out.add(rest);
    return out;
  }
}

class _Line {
  final int style;
  final String label;
  final int labelWidth;
  final String? value;
  final int? valueStyle;
  final bool isHeader;
  final bool isSpacer;
  final bool continuation;
  _Line(this.style, this.label, {this.labelWidth = 0, this.value, this.valueStyle, this.isHeader = false, this.isSpacer = false, this.continuation = false});
}
