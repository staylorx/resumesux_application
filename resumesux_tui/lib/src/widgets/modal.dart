/// Modal dialog over a dimmed overlay.
///
/// Rounded-corner box (`╭╮╰╯`), `modal.bg` fill, a dimming overlay under it
/// made of reduced-intensity copies of the underlying glyphs (`fg.faint`),
/// then a title, wrapped message body and a button row. Focus moves into the
/// modal; only it is interactive while up.
library;

import '../app/store.dart';
import '../term/screen_buffer.dart';
import '../term/strings.dart';
import '../term/theme.dart';
import 'rect.dart';

class ModalWidget {
  final Rect full; // whole screen (for overlay)
  final Modal modal;
  final int width;
  final int focusedButton; // index of the focused button (state.modalButton)
  ModalWidget(this.full, this.modal, this.width, {this.focusedButton = 0});

  void render(ScreenBuffer buf, Theme theme) {
    // Dim overlay: reduce every styled, non-space cell to fg.faint.
    final faint = theme.id(ColorSlot.fgFaint);
    for (var r = 0; r < full.height; r++) {
      for (var c = 0; c < full.width; c++) {
        final cell = buf.cellAt(r, c);
        if (cell.char != ' ') {
          buf.set(r, c, cell.char, faint);
        }
      }
    }

    // Modal box: centered, rounded corners.
    final w = width.clamp(20, full.width - 4);
    final h = 9;
    final x = (full.width - w) ~/ 2;
    final y = (full.height - h) ~/ 2;

    final b = theme.id(ColorSlot.modalBorder);
    final bg = theme.id(ColorSlot.fg, bg: ColorSlot.modalBg);
    final titleStyle = theme.id(ColorSlot.fgTitle, bold: true);
    final bodyStyle = theme.id(ColorSlot.fg);
    final btnStyle = theme.id(ColorSlot.modalBorder);
    final btnFocus = theme.id(ColorSlot.selectFg, bg: ColorSlot.select);
    final hintStyle = theme.id(ColorSlot.fgDim);

    buf.fillRect(y, x, y + h - 1, x + w - 1, ' ', bg);
    // borders
    for (var c = x + 1; c < x + w - 1; c++) {
      buf.set(y, c, '─', b);
      buf.set(y + h - 1, c, '─', b);
    }
    for (var r = y + 1; r < y + h - 1; r++) {
      buf.set(r, x, '│', b);
      buf.set(r, x + w - 1, '│', b);
    }
    buf.set(y, x, '╭', b);
    buf.set(y, x + w - 1, '╮', b);
    buf.set(y + h - 1, x, '╰', b);
    buf.set(y + h - 1, x + w - 1, '╯', b);

    // title
    if (modal.title.isNotEmpty) {
      buf.write(y + 1, x + 2, truncate(modal.title.toUpperCase(), w - 4), titleStyle);
    }
    // message (wrapped across 2 lines)
    final msg = modal.message;
    buf.write(y + 3, x + 2, truncate(msg, w - 4), bodyStyle);

    // buttons row
    var bx = x + 2;
    final bw = 12;
    for (var i = 0; i < modal.buttons.length; i++) {
      final label = '[ ${modal.buttons[i]} ]';
      final focused = i == focusedButton;
      buf.write(y + 5, bx, label, focused ? btnFocus : btnStyle);
      bx += bw;
    }
    // hint
    buf.write(y + 7, x + 2, 'enter confirm · esc cancel', hintStyle);
  }
}
