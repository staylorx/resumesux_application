/// Header bar (height 1, full-width).
///
/// `header.bg` fill across the full width. Contents left-to-right: app title
/// in `fg.title` bold, breadcrumb in `fg.accent` (uppercase), context count in
/// `fg.dim`, optional selected detail id, and a right-aligned active-op/cluster.
library;

import '../app/store.dart';
import '../term/screen_buffer.dart';
import '../term/theme.dart';

class Header {
  final int width;
  final AppState state;
  Header(this.width, this.state);

  void render(ScreenBuffer buf, Theme theme) {
    final bg = theme.id(ColorSlot.headerFg, bg: ColorSlot.headerBg);
    buf.fillRect(0, 0, 0, width - 1, ' ', bg);

    final titleStyle = theme.id(ColorSlot.fgTitle, bold: true);
    final accent = theme.id(ColorSlot.fgAccent, bg: ColorSlot.headerBg);
    final dim = theme.id(ColorSlot.fgDim, bg: ColorSlot.headerBg);

    var x = 1;
    const title = 'resumesux';
    buf.write(0, x, title, titleStyle);
    x += title.length + 2;

    // breadcrumb
    final crumb = '${state.current.title} / matched';
    buf.write(0, x, crumb, accent);
    x += crumb.length + 2;

    // context count (filtered)
    final total = state.currentView.filteredRows.length;
    final ctx = '($total)';
    buf.write(0, x, ctx, dim);
    x += ctx.length + 2;

    // selected detail id
    final frows = state.currentView.filteredRows;
    if (frows.isNotEmpty) {
      final sel = frows[state.currentView.cursor];
      final id = sel.cells.isNotEmpty ? sel.cells.first.text : '';
      buf.write(0, x, '· $id', dim);
      x += id.length + 2;
    }

    // right-aligned active op cluster
    if (state.status == StatusLevel.working) {
      final right = 'generating…';
      buf.write(0, width - right.length - 1, right, accent);
    }
  }
}
