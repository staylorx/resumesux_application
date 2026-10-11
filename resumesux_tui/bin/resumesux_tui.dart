/// ResumesUX TUI entry point.
///
/// Launches the k9s-style alternate-screen shell. `--demo` fills every screen
/// with seed rows (no network). Extra flags:
///
/// ```sh
/// dart run bin/resumesux_tui.dart --demo
/// dart run bin/resumesux_tui.dart --demo --state=empty|error
/// dart run bin/resumesux_tui.dart --demo --theme=light|k9s
/// ```
library;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart' show Console;
import 'package:resumesux_tui/resumesux_tui.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('demo', negatable: false, help: 'Run with seed data (no network).')
    ..addOption('state', allowed: ['loaded', 'empty', 'error'], help: 'Demo data state.')
    ..addOption('theme', defaultsTo: k9sThemeName, help: 'Initial theme (k9s|light).')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');
  final parsed = parser.parse(args);
  if (parsed['help'] as bool) {
    stdout.writeln('ResumesUX TUI — k9s-style terminal app for resumesux.');
    stdout.writeln();
    stdout.writeln(parser.usage);
    return;
  }

  final Console console = Console();
  final theme = buildTheme(parsed['theme'] as String, detectCapability());
  final term = ConsoleTerminal(console, theme);

  final shell = AppShell(
    term: term,
    demo: parsed['demo'] as bool,
    demoState: parsed['state'] as String?,
    initialThemeName: parsed['theme'] as String,
  );

  try {
    shell.run();
  } catch (e) {
    // Restore the normal screen before surfacing a hard error.
    term.exit();
    stderr.writeln('error: $e');
    exitCode = 1;
  }
}
