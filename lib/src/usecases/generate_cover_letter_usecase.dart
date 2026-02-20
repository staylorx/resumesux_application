import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for generating a cover letter.
class GenerateCoverLetterUsecase {
  final AiService aiService;
  final CoverLetterRepository? coverLetterRepository;

  /// Creates a new instance of [GenerateCoverLetterUsecase].
  GenerateCoverLetterUsecase({
    required this.aiService,
    this.coverLetterRepository,
  });

  /// Generates a cover letter for the given job requirement, resume, and applicant.
  ///
  /// Parameters:
  /// - [jobReq]: The job requirement.
  /// - [resume]: The generated resume.
  /// - [applicant]: The applicant information.
  /// - [prompt]: The prompt for AI generation.
  ///
  /// Returns: [TaskEither<Failure, CoverLetter>] the generated cover letter or a failure.
  TaskEither<Failure, CoverLetter> call({
    required JobReq jobReq,
    required Resume resume,
    required Applicant applicant,
    required String prompt,
  }) {
    final gigsContent = applicant.gigs
        .map(
          (gig) =>
              '${gig.concern} - ${gig.title}\n${gig.achievements?.join('\n') ?? ''}',
        )
        .toList();
    final assetsContent =
        applicant.assets.map((asset) => asset.content).toList();

    final fullPrompt = _buildCoverLetterPrompt(
      jobReq: jobReq.content,
      resume: resume.content,
      gigs: gigsContent,
      assets: assetsContent,
      customPromise: prompt,
      applicant: applicant,
    );

    return aiService.generateContent(prompt: fullPrompt).map((content) {
      coverLetterRepository?.setLastAiResponse({'content': content});
      return CoverLetter(content: content);
    });
  }

  String _buildCoverLetterPrompt({
    required String jobReq,
    required String resume,
    required List<String> gigs,
    required List<String> assets,
    required String customPromise,
    required Applicant applicant,
  }) {
    final header = _buildApplicantHeader(applicant: applicant);
    return '''
$header

Generate a professional cover letter. $customPromise

Job Requirements:
$jobReq'

Generated Resume:
$resume

Work Experience (Gigs):
${gigs.join('\n\n')}

Assets (Education, Skills, etc.):
${assets.join('\n\n')}

Please generate a professional cover letter in markdown format.
Do not hallucinate any information. Use only the provided data.
Include all provided work experiences and qualifications. Do not add any skills, experiences, or qualifications not explicitly provided in the Work Experience and Assets sections. If the provided data does not match the job requirements, still use only the provided data without modification or addition. Keep the cover letter concise, under 250 words, with 3-4 paragraphs and bullet points for specific achievements. Avoid repetition.
Output only the plain markdown content without any code blocks, backticks, or additional explanatory text.
''';
  }

  String _buildApplicantHeader({required Applicant applicant}) {
    return '''
Applicant Information:
Name: ${applicant.name}
Preferred Name: ${applicant.preferredName ?? ''}
Email: ${applicant.email}
Phone: ${applicant.phone ?? ''}
${applicant.address != null ? 'Address: ${applicant.address!.street1}${applicant.address!.street2 != null ? ', ${applicant.address!.street2}' : ''}, ${applicant.address!.city}, ${applicant.address!.state} ${applicant.address!.zip}' : ''}
LinkedIn: ${applicant.linkedin ?? ''}
GitHub: ${applicant.github ?? ''}
Portfolio: ${applicant.portfolio ?? ''}
''';
  }
}
