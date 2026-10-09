import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:test/test.dart';

/// dart-flutter-bible (staylorx/dart-flutter-bible) §2.9 boundary gate,
/// single-package application layer. Root is walked up from the package dir;
/// assertions are keyed on the `package:resumesux_application/src/` area
/// prefix (analyzer URIs carry no `lib/` segment).
///
/// Rules enforced:
///   1. the graph is populated (a builder that scanned nothing is vacuous);
///   2. production code is free of dependency cycles;
///   3. the front door stays closed: no `src/` library may import the public
///      barrel (`resumesux_application.dart`) — that re-enters the package
///      through its own facade;
///   4. contracts (`repositories/`, `services/`) must not point back at
///      `usecases/` (usecases are the outermost ring in the application layer).
void main() {
  late DependencyGraph graph;

  setUpAll(() async {
    graph = await Collector.buildGraph(Directory.current.path);
  });

  test('production graph is populated (non-empty guard)', () {
    final src = Collector.allLibraries(graph)
        .where((u) => u.startsWith('package:resumesux_application/src/'));
    expect(src.length, greaterThanOrEqualTo(40),
        reason: 'a graph builder that scanned nothing passes vacuously');
  });

  test('production code has no dependency cycles', () {
    shouldBeFreeOfCycles(filesMatching('src/**'), graph);
  });

  test('no src library imports the public barrel (front-door closed)', () {
    shouldNotDependOn(
      filesMatching('src/**'),
      filesMatching('resumesux_application.dart'),
      graph,
    );
  });

  test('repositories and services must not depend on usecases', () {
    shouldNotDependOn(
      union(
        filesMatching('src/repositories/**'),
        filesMatching('src/services/**'),
      ),
      filesMatching('src/usecases/**'),
      graph,
    );
  });
}
