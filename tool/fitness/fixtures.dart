/// Test assets for the persona->job fitness evaluation.
///
/// Each [PersonaFixture] carries the persona's demonstrable skills (derived
/// from experience/education). Each [JobFixture] carries the role's required
/// skills and the set of persona names expected to be a good fit. Ground truth
/// is deliberately crisp: clear matches (diagonal) and clear mismatches,
/// including the heavy-equipment-operator <-> data-scientist cross.
library;

/// A persona with a name and demonstrable skills.
class PersonaFixture {
  /// The persona's name (also used as the expected-fit key).
  final String name;

  /// Demonstrable skills the persona can point to.
  final List<String> skills;

  /// Creates a [PersonaFixture].
  const PersonaFixture({required this.name, required this.skills});
}

/// A job with a title, required skills, and the expected-fit persona names.
class JobFixture {
  /// The job title.
  final String title;

  /// The skills the role requires.
  final List<String> requires;

  /// Names of personas expected to be a good fit for this job.
  final List<String> bestFitPersonas;

  /// Creates a [JobFixture].
  const JobFixture({
    required this.title,
    required this.requires,
    required this.bestFitPersonas,
  });
}

final List<PersonaFixture> personas = const [
  PersonaFixture(
    name: 'Data Scientist',
    skills: [
      'Python',
      'SQL',
      'statistics',
      'machine learning',
      'data cleaning',
      'pandas',
    ],
  ),
  PersonaFixture(
    name: 'Heavy Equipment Operator',
    skills: [
      'CDL',
      'excavator operation',
      'crane operation',
      'crane rigging',
      'forklift operation',
      'site safety',
      'heavy machinery maintenance',
    ],
  ),
  PersonaFixture(
    name: 'Line Cook',
    skills: [
      'food preparation',
      'knife handling',
      'recipe execution',
      'kitchen hygiene',
      'expediting',
    ],
  ),
  PersonaFixture(
    name: 'Critical Care Nurse',
    skills: [
      'patient assessment',
      'IV administration',
      'ventilator management',
      'ACLS',
      'medication administration',
      'ICU monitoring',
    ],
  ),
  PersonaFixture(
    name: 'Backend Engineer',
    skills: [
      'Python',
      'REST APIs',
      'PostgreSQL',
      'Docker',
      'Linux',
      'CI/CD',
      'distributed systems',
    ],
  ),
  PersonaFixture(
    name: 'Elementary Teacher',
    skills: [
      'lesson planning',
      'classroom management',
      'literacy instruction',
      'child development',
      'differentiated instruction',
    ],
  ),
  PersonaFixture(
    name: 'ML Bootcamp Grad',
    skills: [
      'basic Python',
      'basic SQL',
      'Excel',
      'entry-level ML coursework',
      'Jupyter notebooks',
    ],
  ),
  PersonaFixture(
    name: 'Data Science Enthusiast',
    skills: [
      'read ML blog posts',
      'used ChatGPT',
      'made charts in Excel',
      'managed social media accounts',
    ],
  ),
];

final List<JobFixture> jobs = const [
  JobFixture(
    title: 'Data Scientist',
    requires: [
      'Python',
      'SQL',
      'statistics',
      'machine learning',
      'data visualization',
    ],
    bestFitPersonas: ['Data Scientist'],
  ),
  JobFixture(
    title: 'Heavy Equipment Operator',
    requires: [
      'CDL',
      'excavator operation',
      'crane rigging',
      'site safety',
      'equipment maintenance',
    ],
    bestFitPersonas: ['Heavy Equipment Operator'],
  ),
  JobFixture(
    title: 'Line Cook',
    requires: [
      'food preparation',
      'knife handling',
      'recipe execution',
      'kitchen hygiene',
      'fast-paced expediting',
    ],
    bestFitPersonas: ['Line Cook'],
  ),
  JobFixture(
    title: 'Critical Care Nurse',
    requires: [
      'RN license',
      'ICU experience',
      'ventilator support',
      'ACLS',
      'patient monitoring',
    ],
    bestFitPersonas: ['Critical Care Nurse'],
  ),
  JobFixture(
    title: 'Backend / Platform Engineer',
    requires: ['Python', 'Linux', 'Docker', 'CI/CD', 'system administration'],
    bestFitPersonas: ['Backend Engineer'],
  ),
  JobFixture(
    title: 'Elementary Teacher',
    requires: [
      'teaching certification',
      'lesson planning',
      'classroom management',
      'literacy',
      'child development',
    ],
    bestFitPersonas: ['Elementary Teacher'],
  ),
];
