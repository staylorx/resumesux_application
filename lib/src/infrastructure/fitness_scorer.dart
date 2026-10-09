import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/services/ai_service.dart';

/// A parsed fitness verdict returned by an LLM, or the raw output when the
/// model failed to produce a usable verdict.
class FitVerdict {
  /// Whether the candidate fits the job, or null when unparsable/inconclusive.
  final bool? fit;

  /// The model's one-sentence reason, when present.
  final String? reason;

  /// The raw model output that was parsed.
  final String raw;

  /// Creates a [FitVerdict].
  const FitVerdict({this.fit, this.reason, required this.raw});

  /// Whether a usable boolean verdict was extracted.
  bool get isConclusive => fit != null;
}

/// Scores a candidate's fit for a job using the injected [AiService].
///
/// The AI is asked a strict binary classification over explicit skill lists
/// (rather than open-ended judgment), which the locally-hosted models handle
/// much more reliably.
class FitnessScorer {
  /// The AI service used to produce a verdict.
  final AiService aiService;

  /// Creates a [FitnessScorer] backed by [aiService].
  FitnessScorer({required this.aiService});

  /// Returns a [FitVerdict] for [candidateName] against [jobTitle].
  ///
  /// [candidateSkills] is the persona's demonstrable skills; [jobRequired] is
  /// the role's required skills.
  TaskEither<Failure, FitVerdict> score({
    required String candidateName,
    required Iterable<String> candidateSkills,
    required String jobTitle,
    required Iterable<String> jobRequired,
  }) {
    final prompt = buildFitPrompt(
      candidateName: candidateName,
      candidateSkills: candidateSkills,
      jobTitle: jobTitle,
      jobRequired: jobRequired,
    );
    return aiService.generateContent(prompt: prompt).map(parseFitVerdict);
  }
}

/// Builds a sharp, small footprint prompt for a weak model.
///
/// The prompt reduces fitness to explicit set-overlap, gives strict rules and
/// few-shot examples, and demands a bare JSON verdict. Skill lists are joined
/// with commas; skills that look empty are dropped so "no skills" does not
/// accidentally become a single-vowel token.
String buildFitPrompt({
  required String candidateName,
  required Iterable<String> candidateSkills,
  required String jobTitle,
  required Iterable<String> jobRequired,
}) {
  final skills = _cleanList(candidateSkills);
  final required = _cleanList(jobRequired);
  final skillsText = skills.isEmpty ? '(no listed skills)' : skills.join(', ');
  final requiredText = required.isEmpty ? '(none listed)' : required.join(', ');

  return '''
You are a strict applicant-screening classifier. Decide whether the CANDIDATE is a good fit for the JOB by comparing the CANDIDATE's skills against the JOB's REQUIRED skills.

Rules:
- Good fit means the candidate's skills clearly cover MOST (more than half) of the REQUIRED skills.
- If the candidate lacks several required skills, answer fit=false.
- Base the answer ONLY on the listed skills, never on the job title or the candidate's name.
- Be strict. When in doubt, answer false.

Examples:
candidate skills: Python, SQL, Statistics, ML; required: Python, SQL, ML -> {"fit": true, "reason": "Covers the core data stack"}
candidate skills: Crane operation, Welding; required: Python, SQL, ML -> {"fit": false, "reason": "No overlap with required skills"}

CANDIDATE: $candidateName
CANDIDATE'S SKILLS: $skillsText

JOB TITLE: $jobTitle
REQUIRED SKILLS: $requiredText

Output ONLY a JSON object, with no other text:
{"fit": true_or_false, "reason": "one short sentence"}
''';
}

/// Leniently extracts a [FitVerdict] from raw model output.
///
/// Tolerates markdown fences, surrounding prose, and `fit` expressed as a
/// bool, `"true"/"false"` string, or `1`/`0`. Returns an inconclusive verdict
/// (fit == null) when no usable boolean can be extracted.
FitVerdict parseFitVerdict(String raw) {
  final json = _extractJsonObject(raw);
  if (json == null) {
    return FitVerdict(fit: null, raw: raw);
  }
  try {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final fit = _asBool(decoded['fit']);
    final reason = decoded['reason'];
    return FitVerdict(
      fit: fit,
      reason: reason is String ? reason : null,
      raw: raw,
    );
  } catch (_) {
    return FitVerdict(fit: null, raw: raw);
  }
}

List<String> _cleanList(Iterable<String> items) => items
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList(growable: false);

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == 'yes' || v == 'fit') return true;
    if (v == 'false' || v == 'no' || v == 'not') return false;
  }
  return null;
}

/// Returns the first brace-balanced `{ ... }` substring, or null. Tolerates
/// fences like ```` ```json ```` and trailing prose.
String? _extractJsonObject(String raw) {
  final start = raw.indexOf('{');
  if (start == -1) return null;
  var depth = 0;
  for (var i = start; i < raw.length; i++) {
    final c = raw[i];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) {
        return raw.substring(start, i + 1);
      }
    }
  }
  return null;
}
