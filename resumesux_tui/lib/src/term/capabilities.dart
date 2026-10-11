/// Terminal capability detection.
///
/// Decides at startup whether the terminal supports 24-bit truecolor or only
/// the 16-color ANSI palette. This is checked once (see task acceptance §7) and
/// cached per connection.
library;

import 'dart:io';

import 'theme.dart';

/// Detect the color capability from the process environment.
Capability detectCapability() {
  final colorterm = Platform.environment['COLORTERM']?.toLowerCase() ?? '';
  if (colorterm.contains('truecolor') || colorterm.contains('24bit')) {
    return Capability.truecolor;
  }
  final term = Platform.environment['TERM']?.toLowerCase() ?? '';
  if (term.contains('truecolor') || term.contains('direct')) {
    return Capability.truecolor;
  }
  return Capability.ansi16;
}
