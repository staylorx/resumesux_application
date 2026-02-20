import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

// Parameters to control feedback generation:
// - tone: Controls the tone of feedback (0.0 = brutal feedback, 1.0 = enthusiastic feedback)
// - length: Controls the length of feedback (0.0 = brief, 1.0 = detailed)

/// Use case for generating feedback on an application.
class GenerateFeedbackUsecase {
  final AiService aiService;
  final JobReqRepository jobReqRepository;
  final GigRepository gigRepository;
  final AssetRepository assetRepository;
  final FeedbackRepository? feedbackRepository;

  /// Creates a new instance of [GenerateFeedbackUsecase].
  GenerateFeedbackUsecase({
    required this.aiService,
    required this.jobReqRepository,
    required this.gigRepository,
    required this.assetRepository,
    this.feedbackRepository,
  });

  /// Generates feedback for the given job requirement, resume, cover letter, and applicant.
  ///
  /// Parameters:
  /// - [jobReq]: The job requirement.
  /// - [resume]: The generated resume.
  /// - [coverLetter]: The generated cover letter (optional).
  /// - [prompt]: The prompt for AI generation.
  /// - [applicant]: The applicant information.
  /// - [tone]: Controls the tone of feedback (0.0 = brutal feedback, 1.0 = enthusiastic feedback). Default is 0.5.
  /// - [length]: Controls the length of feedback (0.0 = brief, 1.0 = detailed). Default is 0.5.
  ///
  /// Returns: [TaskEither<Failure, Feedback>] the generated feedback or a failure.
  TaskEither<Failure, Feedback> call({
    required JobReq jobReq,
    required Resume resume,
    CoverLetter? coverLetter,
    required String prompt,
    required Applicant applicant,
    double tone = 0.5,
    double length = 0.5,
  }) {
    // Retrieve AI responses
    final jobReqAiResponse = jobReqRepository.getLastAiResponseJson();
    final gigAiResponses = gigRepository.getLastAiResponsesJson();
    final assetAiResponses = assetRepository.getLastAiResponsesJson();

    final fullPrompt = _buildFeedbackPrompt(
      jobReq: jobReq.content,
      resume: resume.content,
      coverLetter: coverLetter?.content ?? '',
      customPrompt: prompt,
      applicant: applicant,
      jobReqEntity: jobReq,
      jobReqAiResponse: jobReqAiResponse,
      gigAiResponses: gigAiResponses,
      assetAiResponses: assetAiResponses,
      tone: tone,
      length: length,
    );

    return aiService.generateContent(prompt: fullPrompt).map((content) {
      final feedback = Feedback(content: content);
      feedbackRepository?.setLastAiResponse({
        'content': feedback.content,
      });
      return feedback;
    });
  }

  String _getToneInstruction({required double tone}) {
    if (tone <= 0.2) {
      return 'Be brutally honest and critical, pointing out all flaws harshly without sugarcoating.';
    } else if (tone <= 0.4) {
      return 'Be direct and critical, focusing on weaknesses while offering minimal constructive input.';
    } else if (tone <= 0.6) {
      return 'Provide constructive feedback with a balanced approach, addressing both strengths and areas for improvement.';
    } else if (tone <= 0.8) {
      return 'Be encouraging with constructive suggestions, emphasizing potential and positive aspects.';
    } else {
      return 'Be enthusiastic and kind, focusing on strengths, highlighting achievements, and providing supportive guidance.';
    }
  }

  String _getLengthInstruction({required double length}) {
    if (length <= 0.2) {
      return 'Provide a very brief summary, focusing only on the most critical points.';
    } else if (length <= 0.4) {
      return 'Provide a short overview, covering key aspects concisely.';
    } else if (length <= 0.6) {
      return 'Provide balanced feedback with moderate detail on important elements.';
    } else if (length <= 0.8) {
      return 'Provide detailed feedback, elaborating on multiple aspects.';
    } else {
      return 'Provide a comprehensive and detailed analysis, covering all relevant areas thoroughly.';
    }
  }

  String _buildFeedbackPrompt({
    required String jobReq,
    required String resume,
    required String coverLetter,
    required String customPrompt,
    required Applicant applicant,
    required JobReq jobReqEntity,
    String? jobReqAiResponse,
    String? gigAiResponses,
    String? assetAiResponses,
    required double tone,
    required double length,
  }) {
    final toneInstruction = _getToneInstruction(tone: tone);
    final lengthInstruction = _getLengthInstruction(length: length);

    final applicantSummary = '''
Applicant Information:
- Name: ${applicant.name}
- Preferred Name: ${applicant.preferredName ?? 'N/A'}
- Email: ${applicant.email}
- Address: ${applicant.address?.toString() ?? 'N/A'}
- Phone: ${applicant.phone ?? 'N/A'}
- LinkedIn: ${applicant.linkedin ?? 'N/A'}
- GitHub: ${applicant.github ?? 'N/A'}
- Portfolio: ${applicant.portfolio ?? 'N/A'}
''';

    final jobReqSummary = '''
Job Requirement Information:
- Title: ${jobReqEntity.title}
- Location: ${jobReqEntity.location ?? 'N/A'}
- Salary: ${jobReqEntity.salary ?? 'N/A'}
- Company: ${jobReqEntity.concern?.name ?? 'N/A'}
''';

    final aiResponses = '''
Extracted AI Responses:
- Job Req AI Response: ${jobReqAiResponse ?? 'N/A'}
- Gig AI Responses: ${gigAiResponses ?? 'N/A'}
- Asset AI Responses: ${assetAiResponses ?? 'N/A'}
''';

    return '''
$customPrompt

Always start with a summary paragraph titled "### Summary Paragraph" that summarizes who the applicant is, what job they are applying for, and where the job is located if available. Use the provided applicant information, job requirement information, and extracted AI responses to build this summary.

$applicantSummary

$jobReqSummary

$aiResponses

Job Requirements:
$jobReq'

Generated Resume:
$resume

Generated Cover Letter:
$coverLetter

$toneInstruction $lengthInstruction Include suggestions for improvement on how well this application matches the job requirements.

Do not include the generated job requirements, resume, or cover letter content in your response. The only exception is the summary paragraph which tells us who applied for what. Provide only the feedback analysis in markdown format.
Output only the plain markdown content without any code blocks, backticks, or additional explanatory text.
Add a section at the end that summarizes an opinion of a hiring manager reviewing this application: qualified, not qualified, maybe, yes, no, or needs more information. Add this as "tl;dr" for a quick view.
If there are hidden ideas or biases that a hiring manager might pick up on, put them down here also.
Do not be afraid to be direct and honest in this section. If you think you're being polite in the main feedback, this is the place to be candid including avoiding overly "politically correct" language.
Respect the tone and length instructions provided.
''';
  }
}
