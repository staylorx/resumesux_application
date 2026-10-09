import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/services/ai_service.dart';

/// One required skill and whether the generated application demonstrates it.
class CoveragePoint {
  /// The required skill under review.
  final String skill;

  /// Whether the application gives concrete evidence for [skill].
  final bool covered;

  /// Creates a [CoveragePoint].
  const CoveragePoint({required this.skill, required this.covered});
}

/// Result of grading a generated application against a job's required skills.
class CoverageReport {
  /// The job title the application targets.
  final String jobTitle;

  /// Every required skill and its coverage flag.
  final List<CoveragePoint> points;

  /// The raw model output that was parsed.
  final String raw;

  /// Creates a [CoverageReport].
  const CoverageReport({
    required this.jobTitle,
    required this.points,
    required this.raw,
  });

  /// Number of required skills with concrete evidence.
  int get coveredCount => points.where((p) => p.covered).length;

  /// Whether the application covers most (a strict majority, i.e. > half) of
  /// the required skills.
  bool get fit {
    final total = points.length;
    if (total == 0) return false;
    return coveredCount * 2 > total;
  }
}

/// Grades an AI-generated application by scoring whether it provides concrete
/// evidence for each of a job's required skills (a generation-quality check,
/// distinct from persona screening).
class GradeScorer {
  /// The AI service used to judge coverage.
  final AiService aiService;

  /// Creates a [GradeScorer] backed by [aiService].
  GradeScorer({required this.aiService});

  /// Grades [content] against [requiredSkills] for [jobTitle].
  TaskEither<Failure, CoverageReport> grade({
    required String content,
    required String jobTitle,
    required Iterable<String> requiredSkills,
  }) {
    final prompt = buildGradePrompt(
      content: content,
      jobTitle: jobTitle,
      requiredSkills: requiredSkills,
    );
    return aiService
        .generateContent(prompt: prompt)
        .map(
          (raw) =>
              parseCoverage(raw, required: requiredSkills, jobTitle: jobTitle),
        );
  }
}

/// Builds the strict, JSON-only coverage prompt for [content].
String buildGradePrompt({
  required String content,
  required String jobTitle,
  required Iterable<String> requiredSkills,
}) {
  final requiredText = requiredSkills
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(', ');
  return '''
You are grading whether an AI-generated application genuinely addresses a job's required skills.

Rules:
- For each required skill, judge whether the application provides concrete, specific evidence for it — not merely the keyword appearing once.
- Be strict. If a skill is only mentioned in passing with no evidence, treat it as NOT covered.

JOB TITLE: $jobTitle
REQUIRED SKILLS: $requiredText

APPLICATION:
$content

Respond with ONLY a JSON object, with no other text:
{"covered": ["skills with evidence"], "missing": ["skills without evidence"], "fit": true_or_false}
"fit" is true only if MOST (more than half) of the required skills are covered.
''';
}

/// Leniently parses a [CoverageReport] from [raw], using [required] to
/// normalize the covered/missing lists.
CoverageReport parseCoverage(
  String raw, {
  required Iterable<String> required,
  required String jobTitle,
}) {
  final requiredSkills = required
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final json = _extractJsonObject(raw);
  final covered = <String>{};

  if (json != null) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        final c = decoded['covered'];
        final m = decoded['missing'];
        final coveredExplicit = c is List
            ? c.map((e) => e.toString().toLowerCase()).toSet()
            : <String>{};
        // Prefer the explicit `covered` list; only derive from `missing` when
        // the model gave no covered list at all.
        if (coveredExplicit.isNotEmpty) {
          covered.addAll(coveredExplicit);
        } else if (m is List && m.isNotEmpty) {
          covered.addAll(
            requiredSkills
                .where((s) => !m.contains(s))
                .map((s) => s.toLowerCase()),
          );
        }
      }
    } catch (_) {
      // fall through to empty coverage
    }
  }

  final points = requiredSkills
      .map(
        (skill) => CoveragePoint(
          skill: skill,
          covered:
              covered.contains(skill.toLowerCase()) ||
              covered.any((c) => skill.toLowerCase().contains(c)),
        ),
      )
      .toList();

  return CoverageReport(jobTitle: jobTitle, points: points, raw: raw);
}

/// Returns the first brace-balanced `{ ... }` substring, or null.
String? _extractJsonObject(String raw) {
  final start = raw.indexOf('{');
  if (start == -1) return null;
  var depth = 0;
  for (var i = start; i < raw.length; i++) {
    if (raw[i] == '{') {
      depth++;
    } else if (raw[i] == '}') {
      depth--;
      if (depth == 0) return raw.substring(start, i + 1);
    }
  }
  return null;
}
