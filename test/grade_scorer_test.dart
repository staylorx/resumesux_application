import 'package:resumesux_application/src/infrastructure/grade_scorer.dart';
import 'package:test/test.dart';

void main() {
  group('buildGradePrompt', () {
    test('includes required skills and the application body', () {
      final prompt = buildGradePrompt(
        content: 'I used Python to build a pipeline.',
        jobTitle: 'Data Scientist',
        requiredSkills: ['Python', 'SQL', 'statistics'],
      );
      expect(prompt, contains('Data Scientist'));
      expect(prompt, contains('REQUIRED SKILLS: Python, SQL, statistics'));
      expect(prompt, contains('I used Python to build a pipeline.'));
      expect(prompt, contains('Respond with ONLY a JSON object'));
    });
  });

  group('parseCoverage', () {
    test('marks covered and missing skills, computes fit', () {
      final report = parseCoverage(
        '{"covered": ["python", "statistics"], "missing": ["sql"]}',
        required: ['Python', 'SQL', 'statistics', 'ML'],
        jobTitle: 'Data Scientist',
      );
      expect(report.coveredCount, 2);
      expect(
        report.points.firstWhere((p) => p.skill == 'Python').covered,
        isTrue,
      );
      expect(
        report.points.firstWhere((p) => p.skill == 'SQL').covered,
        isFalse,
      );
      // 2 of 4 (< half) => not fit
      expect(report.fit, isFalse);
    });

    test('is lenient about case and derives missing from required', () {
      final report = parseCoverage(
        '{"covered": ["PYTHON"]}',
        required: ['Python', 'SQL'],
        jobTitle: 'X',
      );
      expect(report.coveredCount, 1);
      expect(
        report.points.firstWhere((p) => p.skill == 'Python').covered,
        isTrue,
      );
      expect(
        report.points.firstWhere((p) => p.skill == 'SQL').covered,
        isFalse,
      );
    });

    test('handles non-JSON output as no coverage', () {
      final report = parseCoverage(
        'The application covers everything well.',
        required: ['Python', 'SQL'],
        jobTitle: 'X',
      );
      expect(report.coveredCount, 0);
      expect(report.fit, isFalse);
    });
  });
}
