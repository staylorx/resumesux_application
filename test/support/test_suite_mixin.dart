import 'dart:io';
import 'package:path/path.dart' as path;

/// Configuration for suite directory handling.
class SuiteDirConfig {
  final SuiteDirType type;
  final String? basePath;
  final bool deleteOnTeardown;

  const SuiteDirConfig({
    required this.type,
    this.basePath,
    this.deleteOnTeardown = true,
  });
}

/// Enum for suite directory type.
enum SuiteDirType { temporary, persisted }

/// Mixin for managing test suites, including README generation and suite directory handling.
mixin TestSuiteMixin {
  String? suiteDir;
  late final String suiteName;
  late final SuiteDirConfig config;
  late final DateTime startTime;
  final List<String> groups = [];
  final Map<String, TestEntry> testEntries = {};
  final Map<String, List<TestEntry>> groupTests = {};
  String? currentGroup;

  /// Initializes the suite directory and README.md with suite information.
  void initialize() {
    if (config.type == SuiteDirType.temporary) {
      suiteDir =
          Directory.systemTemp.createTempSync('test_suite_${suiteName}_').path;
    } else {
      final base = config.basePath ?? path.join('build', 'output');
      suiteDir = path.join(base, suiteName);
    }
    Directory(suiteDir!).createSync(recursive: true);
    startTime = DateTime.now();
    _writeReadme();
  }

  /// Records the start of a test group.
  void startGroup(String groupName) {
    groups.add(groupName);
    currentGroup = groupName;
    groupTests[groupName] = [];
    _writeReadme();
  }

  /// Records the start of a test.
  void startTest(String testName) {
    final entry = TestEntry(
      name: testName,
      startTime: DateTime.now(),
      status: TestStatus.running,
    );
    testEntries[testName] = entry;
    if (currentGroup != null) {
      groupTests[currentGroup!]!.add(entry);
    } else {
      const defaultGroup = 'General';
      if (!groups.contains(defaultGroup)) {
        groups.add(defaultGroup);
        groupTests[defaultGroup] = [];
      }
      groupTests[defaultGroup]!.add(entry);
    }
    _writeReadme();
  }

  /// Records the end of a test with its status.
  void endTest(String testName, bool passed, {String? error}) {
    final entry = testEntries[testName];
    if (entry != null) {
      entry.endTime = DateTime.now();
      entry.status = passed ? TestStatus.passed : TestStatus.failed;
      entry.error = error;
      _writeReadme();
    }
  }

  /// Finalizes the README with summary.
  void finalize() {
    _writeReadme();
  }

  /// Disposes the suite, deleting the directory if configured to do so.
  void dispose() {
    if (suiteDir != null && config.deleteOnTeardown) {
      final dir = Directory(suiteDir!);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  }

  /// Copies a file to the suite directory for artifact collection.
  void collectArtifact(String sourcePath, {String? destName}) {
    if (suiteDir != null) {
      final file = File(sourcePath);
      if (file.existsSync()) {
        final name = destName ?? path.basename(sourcePath);
        final destPath = path.join(suiteDir!, name);
        file.copySync(destPath);
      }
    }
  }

  void _writeReadme() {
    if (suiteDir == null) return;
    final buffer = StringBuffer();

    buffer.writeln('# Test Suite: $suiteName - GROUPED');
    buffer.writeln('');
    buffer.writeln('Started: ${startTime.toIso8601String()}');
    buffer.writeln('Suite Directory: $suiteDir');
    buffer.writeln('');

    if (groups.isNotEmpty) {
      buffer.writeln('## Test Groups');
      for (final group in groups) {
        buffer.writeln('- $group');
      }
      buffer.writeln('');
    }

    if (testEntries.isNotEmpty) {
      for (final group in groups) {
        buffer.writeln('## $group');
        buffer.writeln('');
        final tests = groupTests[group] ?? [];
        if (tests.isNotEmpty) {
          buffer.writeln('| Test | Status | Duration | Error |');
          buffer.writeln('|------|--------|----------|-------|');

          for (final entry in tests) {
            final duration = entry.endTime != null
                ? '${entry.endTime!.difference(entry.startTime).inSeconds}s'
                : 'Running';
            final statusEmoji = entry.status == TestStatus.passed
                ? '✅'
                : entry.status == TestStatus.failed
                    ? '❌'
                    : '⏳';
            final error = entry.error ?? '';
            buffer.writeln(
              '| ${entry.name} | $statusEmoji ${entry.status.name} | $duration | $error |',
            );
          }
          buffer.writeln('');
        }
      }

      final passed =
          testEntries.values.where((e) => e.status == TestStatus.passed).length;
      final failed =
          testEntries.values.where((e) => e.status == TestStatus.failed).length;
      final running = testEntries.values
          .where((e) => e.status == TestStatus.running)
          .length;

      buffer.writeln('## Summary');
      buffer.writeln('- Total Tests: ${testEntries.length}');
      buffer.writeln('- Passed: $passed');
      buffer.writeln('- Failed: $failed');
      buffer.writeln('- Running: $running');
    }

    final readmePath = path.join(suiteDir!, 'README.md');
    File(readmePath).writeAsStringSync(buffer.toString());
  }
}

/// A tool class for managing test suites using the TestSuiteMixin.
class TestSuiteTool with TestSuiteMixin {
  TestSuiteTool({required SuiteDirConfig config, required String suiteName}) {
    this.config = config;
    this.suiteName = suiteName;
  }
}

/// Represents a test entry in the README.
class TestEntry {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  TestStatus status;
  String? error;

  TestEntry({
    required this.name,
    required this.startTime,
    required this.status,
  });
}

/// Enum for test status.
enum TestStatus { running, passed, failed }
