import 'package:resumesux_application/src/infrastructure/fitness_scorer.dart';
import 'package:test/test.dart';

void main() {
  group('buildFitPrompt', () {
    test('lays out candidate, skills, required, and JSON-only instruction', () {
      final prompt = buildFitPrompt(
        candidateName: 'Pat',
        candidateSkills: ['Python', 'SQL', 'statistics'],
        jobTitle: 'Data Scientist',
        jobRequired: ['Python', 'SQL', 'machine learning'],
      );
      expect(prompt, contains('CANDIDATE: Pat'));
      expect(prompt, contains('CANDIDATE\'S SKILLS: Python, SQL, statistics'));
      expect(prompt, contains('JOB TITLE: Data Scientist'));
      expect(
        prompt,
        contains('REQUIRED SKILLS: Python, SQL, machine learning'),
      );
      expect(prompt, contains('Output ONLY a JSON object'));
    });

    test('drops empty/blank skills so lists stay clean', () {
      final prompt = buildFitPrompt(
        candidateName: 'Pat',
        candidateSkills: ['', '  ', 'Lift operator'],
        jobTitle: 'Operator',
        jobRequired: <String>[''],
      );
      expect(prompt, contains('CANDIDATE\'S SKILLS: Lift operator'));
      expect(prompt, contains('REQUIRED SKILLS: (none listed)'));
    });

    test('carries the strict weak-qualifier rule', () {
      final prompt = buildFitPrompt(
        candidateName: 'ML Bootcamp Grad',
        candidateSkills: ['basic Python', 'entry-level ML coursework'],
        jobTitle: 'Data Scientist',
        jobRequired: ['Python', 'SQL', 'statistics'],
      );
      expect(prompt, contains('Weak qualifiers do not count as real skills'));
      expect(prompt, contains('is NOT a fit even when the names overlap'));
    });
  });

  group('parseFitVerdict', () {
    test('parses a bare JSON object', () {
      final v = parseFitVerdict('{"fit": true, "reason": "Great match"}');
      expect(v.fit, isTrue);
      expect(v.reason, 'Great match');
      expect(v.isConclusive, isTrue);
    });

    test('parses a fenced json block', () {
      final v = parseFitVerdict('```json\n{"fit": false}\n```');
      expect(v.fit, isFalse);
    });

    test('parses fit expressed as a string and as a number', () {
      expect(parseFitVerdict('{"fit": "true"}').fit, isTrue);
      expect(parseFitVerdict('{"fit": 0}').fit, isFalse);
    });

    test('extracts the object from surrounding prose', () {
      final v = parseFitVerdict(
        'Here you go: {"fit": true, "reason": "ok"} thanks',
      );
      expect(v.fit, isTrue);
    });

    test('returns inconclusive for non-JSON output', () {
      final v = parseFitVerdict('I think they are a great fit for this job.');
      expect(v.fit, isNull);
      expect(v.isConclusive, isFalse);
    });

    test('returns inconclusive for malformed JSON fit field', () {
      final v = parseFitVerdict('{"fit": maybe}');
      expect(v.fit, isNull);
    });
  });
}
