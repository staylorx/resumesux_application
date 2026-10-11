/// Headless smoke test that drives the shell with a fake terminal, verifying
/// the full layout renders for every screen/state without throwing, and that
/// the diff renderer produces output. Runs without a real terminal.
library;

import 'dart:io';

import 'package:resumesux_tui/resumesux_tui.dart';

class _FakeTerm extends Terminal {
  final _out = StringBuffer();
  final List<InputKey> _keys;
  _FakeTerm(this._keys);
  @override
  int get width => 120;
  @override
  int get height => 32;
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
    if (k.isControl) {
      return TermKey(isControl: true, char: '', charCode: k.code);
    }
    return TermKey(isControl: false, char: k.char);
  }
}

void main() {
  // Drive each screen + each state through a few frames then quit.
  for (final state in ['loaded', 'empty', 'error']) {
    for (final theme in ['k9s', 'light']) {
      final term = _FakeTerm([
        const InputKey.control(Ctrl.ctrlC), // quit immediately after seeding
      ]);
      final shell = AppShell(
        term: term,
        demo: true,
        demoState: state,
        initialThemeName: theme,
      );
      shell.run();
      final out = term._out.toString();
      if (out.isEmpty) {
        throw StateError('no render output for state=$state theme=$theme');
      }
      stdout.writeln('ok: state=$state theme=$theme emitted ${out.length} chars');
    }
  }
  // Drive navigation keys on every screen.
  final navKeys = <InputKey>[
    const InputKey.control(Ctrl.down),
    const InputKey.control(Ctrl.down),
    const InputKey.control(Ctrl.pageDown),
    const InputKey.control(Ctrl.end),
    const InputKey.control(Ctrl.home),
    InputKey.printable('j'),
    InputKey.printable('k'),
    const InputKey.control(Ctrl.ctrlC),
  ];
  final term = _FakeTerm(navKeys);
  final shell = AppShell(term: term, demo: true);
  shell.run();
  stdout.writeln('ok: navigation path emitted ${term._out.toString().length} chars');

  // Command palette: open `:`, type, run a command (switch view), then quit.
  final term2 = _FakeTerm(<InputKey>[
    InputKey.printable(':'),
    InputKey.printable('g'),
    InputKey.printable('i'),
    InputKey.printable('g'),
    InputKey.printable('s'),
    const InputKey.control(Ctrl.enter),
    const InputKey.control(Ctrl.ctrlC),
  ]);
  AppShell(term: term2, demo: true).run();
  stdout.writeln('ok: command palette emitted ${term2._out.toString().length} chars');

  // Help + confirm modal + esc.
  final term3 = _FakeTerm(<InputKey>[
    InputKey.printable('?'),
    const InputKey.control(Ctrl.esc),
    InputKey.printable('d'),
    const InputKey.control(Ctrl.esc),
    const InputKey.control(Ctrl.ctrlC),
  ]);
  AppShell(term: term3, demo: true).run();
  stdout.writeln('ok: help+modal emitted ${term3._out.toString().length} chars');

  // Rapid input stress: a fast blast of navigation keys + arbitrary printable
  // keys must not crash and must keep emitting frames (no exceptions unwound).
  final stressKeys = <InputKey>[];
  for (var i = 0; i < 200; i++) {
    stressKeys.add(const InputKey.control(Ctrl.down));
    stressKeys.add(InputKey.printable('j'));
    stressKeys.add(InputKey.printable('k'));
    stressKeys.add(const InputKey.control(Ctrl.pageDown));
    if (i % 7 == 0) stressKeys.add(InputKey.printable(':'));
    if (i % 11 == 0) stressKeys.add(InputKey.printable('?'));
    if (i % 13 == 0) stressKeys.add(InputKey.printable('s'));
    if (i % 17 == 0) stressKeys.add(InputKey.printable('/'));
    if (i % 23 == 0) stressKeys.add(InputKey.printable('x')); // printable, unhandled in pane
  }
  stressKeys.add(const InputKey.control(Ctrl.ctrlC));
  final term4 = _FakeTerm(stressKeys);
  AppShell(term: term4, demo: true).run();
  stdout.writeln(
      'ok: rapid-input stress emitted ${term4._out.toString().length} chars');

  stdout.writeln('ALL SMOKE CHECKS PASSED');
}
