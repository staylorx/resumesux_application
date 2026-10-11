/// Headless tests for responsive layout / resize handling in the shell.
///
/// The shell rereads the terminal size on every frame and the diff renderer
/// issues a full repaint whenever the buffer dimensions change, so a resize
/// must relayout cleanly with no state loss and no crash. These run without a
/// real terminal.
library;

import 'package:resumesux_tui/resumesux_tui.dart';
import 'package:test/test.dart';

/// A fake [Terminal] whose reported size can be changed after construction,
/// and which returns a scripted list of keys.
class ResizableFakeTerm extends Terminal {
  ResizableFakeTerm(this._keys) : _w = 120, _h = 32;
  int _w, _h;
  final List<InputKey> _keys;
  final _out = StringBuffer();

  set size(List<int> wh) {
    _w = wh[0];
    _h = wh[1];
  }

  @override
  int get width => _w;
  @override
  int get height => _h;
  @override
  Capability get capability => Capability.ansi16;
  @override
  void enter() {}
  @override
  void exit() {}
  @override
  void flush() {}
  @override
  void writeRaw(String s) => _out.write(s);
  @override
  bool get hasKey => false;
  @override
  TermKey? readKey() {
    if (_keys.isEmpty) return null;
    final k = _keys.removeAt(0);
    if (k.isControl) return TermKey(isControl: true, char: '', charCode: k.code);
    return TermKey(isControl: false, char: k.char);
  }
}

void main() {
  test('too-small terminal renders the resize notice and does not crash', () {
    final term = ResizableFakeTerm([const InputKey.control(Ctrl.ctrlC)]);
    term.size = [60, 12]; // below the 100x24 floor
    AppShell(term: term, demo: true).run();
    final out = term._out.toString();
    expect(out, contains('resize'));
    // No panic/exception propagates out of run().
  });

  test('viable terminal renders table + detail panes (wireframe layout)', () {
    final term = ResizableFakeTerm([const InputKey.control(Ctrl.ctrlC)]);
    term.size = [110, 32];
    AppShell(term: term, demo: true).run();
    final out = term._out.toString();
    // Table frame title and the detail pane's first section both render.
    expect(out, contains('APPLICANTS'));
    expect(out, contains('identity'));
  });

  test('resize grows a small terminal and recovers to full layout', () {
    // A fake that reports 60x12 on the first size query, then 120x32.
    final term = _GrowTerm();
    AppShell(term: term, demo: true).run();
    expect(term._out.toString(), contains('APPLICANTS'));
  });
}

/// Reports a too-small size only for the very first read, then a normal size.
class _GrowTerm extends Terminal {
  final _out = StringBuffer();
  bool _first = true;
  @override
  int get width => _first ? 60 : 120;
  @override
  int get height => _first ? 12 : 32;
  @override
  Capability get capability => Capability.ansi16;
  @override
  void enter() {}
  @override
  void exit() {}
  @override
  void flush() {}
  @override
  void writeRaw(String s) => _out.write(s);
  @override
  bool get hasKey => false;
  @override
  TermKey? readKey() {
    _first = false; // after the first paint the terminal has "grown"
    return TermKey(isControl: true, char: '', charCode: Ctrl.ctrlC);
  }
}
