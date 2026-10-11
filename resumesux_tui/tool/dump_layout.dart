/// Renders the applicants screen to a plain-text dump so the layout can be
/// visually inspected (strips ANSI, keeps spaces) — useful to confirm the
/// wireframe matches the spec. Not part of the shipped app.
library;

// ignore_for_file: avoid_print

import 'package:resumesux_tui/resumesux_tui.dart';

void main() {
  final w = 110, h = 26;
  final theme = buildTheme('k9s', Capability.ansi16);
  var state = AppState(theme: theme);
  state = reduce(
    state,
    DataLoadedAction(ScreenId.applicants, demoRows(ScreenId.applicants, null)),
  );
  state = state.copyWith(views: {...state.views, ScreenId.applicants: state.view(ScreenId.applicants).copyWith(load: LoadState.loaded)});

  final buf = ScreenBuffer(w, h);
  final appBg = theme.id(ColorSlot.fg, bg: ColorSlot.appBg);
  buf.fillRect(0, 0, h - 1, w - 1, ' ', appBg);

  Header(w, state).render(buf, theme);
  final vs = state.view(ScreenId.applicants);

  // main split: table 40%, gutter 1
  final tableW = (w * 0.4).round();
  final gutter = 1;
  final detailX = tableW + gutter;
  final detailW = w - detailX;
  final mainTop = 1, mainH = h - 1 - 1;

  Table(
    rect: Rect(0, mainTop, tableW, mainH),
    title: 'APPLICANTS',
    focused: true,
    view: vs,
    columns: const [
      ColumnDef('name', width: 20),
      ColumnDef('status', width: 10),
      ColumnDef('score', width: 8),
      ColumnDef('age'),
    ],
  ).render(buf, theme);

  final sel = vs.rows[vs.cursor];
  Detail(
    rect: Rect(detailX, mainTop, detailW, mainH),
    focused: false,
    sections: demoDetail(ScreenId.applicants, sel),
  ).render(buf, theme);

  Header(w, state).render(buf, theme);
  StatusBar(w, state, row: h - 1).render(buf, theme);

  // dump as text
  final sb = StringBuffer();
  for (var r = 0; r < h; r++) {
    final line = StringBuffer();
    for (var c = 0; c < w; c++) {
      final cell = buf.cellAt(r, c);
      // replace styled-cells marker with plain char
      line.write(cell.char == ' ' ? ' ' : cell.char);
    }
    final s = line.toString().replaceAll(RegExp(r'\s+$'), '');
    sb.writeln(s.isEmpty ? '·' : s);
  }
  print(sb.toString());
}
