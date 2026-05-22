class BpedCurriculumSubject {
  const BpedCurriculumSubject({
    required this.yearLevel,
    required this.semesterLabel,
    required this.code,
    required this.title,
  });

  final int yearLevel;
  final String semesterLabel;
  final String code;
  final String title;

  String get label => '$code - $title';

  bool matches(String value) {
    final normalizedValue = BpedCurriculumService._normalize(value);
    return normalizedValue == BpedCurriculumService._normalize(label) ||
        normalizedValue == BpedCurriculumService._normalize(title) ||
        normalizedValue == BpedCurriculumService._normalize(code);
  }
}

class BpedCurriculumService {
  static const List<BpedCurriculumSubject> subjects = [
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'PEd 1',
      title:
          'Philosophical and Socio-anthropological Foundations of Physical Education and Sports',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'PEd 2',
      title: 'Anatomy and Physiology of Human Movement',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'PEd 3',
      title:
          'Principles of Motor Control and Learning of Exercise, Sports and Dance',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'Fil. 1',
      title: 'Kontekstwalisadong Komunikasyon sa Filipino',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'GE 1',
      title: 'Understanding the Self',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'GE 2',
      title: 'Contemporary World',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'GE 3',
      title: 'Purposive Communication',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'GE 4',
      title: 'Mathematics in the Modern World',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'PE 1',
      title: 'Movement Enhancement',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '1st Semester',
      code: 'NSTP 1',
      title: 'National Service Training Program',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'PEd 4',
      title:
          'Applied Motor Control and Learning of Exercises, Sports and Dance',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'PEd 5',
      title: 'Physiology of Exercise and Physical Activity',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'PEd 6',
      title: 'Emergency Preparedness and Safety Management',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'Educ. 1',
      title: 'The Child and Adolescent Learners and Learning Principles',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'GE 5',
      title: 'Ethics',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'GE 6',
      title: 'Science, Technology and Society',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'GE 7',
      title: 'Art Appreciation',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'PE 2',
      title: 'Fitness Exercises',
    ),
    BpedCurriculumSubject(
      yearLevel: 1,
      semesterLabel: '2nd Semester',
      code: 'NSTP 2',
      title: 'National Service Training Program',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'PEd 7',
      title: 'Arts in the K to 12 Curriculum',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'PEd 8',
      title: 'Movement Education',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'PEd 9',
      title: 'Philippine Traditional Dances',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'Educ. 2',
      title: 'The Teaching Profession',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'Educ. 4',
      title: 'Foundation of Special and Inclusive Education',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'Lit',
      title: 'Philippine Literature',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'Fil. 2',
      title: "Filipino sa Iba't Ibang Disiplina",
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'GE 8',
      title: 'Reading in Philippine History',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'GE 9',
      title: 'Life and Works of Rizal',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '1st Semester',
      code: 'PE 3',
      title: 'Physical Activities towards Health and Fitness (PATH-Fit) 1',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'PEd 10',
      title: 'Swimming and Aquatics',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'PEd 11',
      title: 'International Dance and other Forms',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'PEd 12',
      title:
          'Individual and Dual Sports (Racket Sports, Athletics, Martial Arts)',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'PEd 13',
      title: 'Philippine Traditional Games',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'PEd 14',
      title: 'Coordinated School Health Program',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'Educ. 3',
      title:
          'The Teacher and the Community, School Culture and Organizational Leadership',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'Educ. 8',
      title: 'Technology for Teaching and Learning 1',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'GE Elec 1',
      title: 'Living in the IT Era',
    ),
    BpedCurriculumSubject(
      yearLevel: 2,
      semesterLabel: '2nd Semester',
      code: 'PE 4',
      title: 'Physical Activities towards Health and Fitness (PATH-Fit) 2',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'PEd 15',
      title: 'Personal, Community and Environmental Health',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'PEd 16',
      title:
          'Curriculum and Assessment for Physical Education and Health Education for K to 12',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'PEd 17',
      title: 'Process of Teaching PE and Health Education',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'PEd 18',
      title: 'Research in Physical Education 1',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'PEd 19',
      title:
          'Team Sports (Soccer/Football, Basketball, Volleyball, Baseball, Softball, Non-Traditional: Ultimate Handball, Floorball, Futsal, Sepak Takraw)',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'PEd 20',
      title: 'Sports and Exercise Psychology',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'Educ. 5',
      title: 'Facilitating Learner-Centered Teaching',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'Educ. 6',
      title: 'Assessment in Learning 1',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '1st Semester',
      code: 'GE Elec 2',
      title: 'Gender and Society',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'PEd 21',
      title: 'Drug Education, Consumer Health and Healthy Eating',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'PEd 22',
      title: 'Technology Application in Teaching PE and Health Education',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'PEd 23',
      title: 'Music in K to 12 Curriculum',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'PEd 24',
      title:
          'Administration and Management of Physical Education and Health Education Programs',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'PEd 25',
      title: 'Research in Physical Education 2',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'Educ. 7',
      title: 'Assessment in Learning 2',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'Educ. 9',
      title: 'The Teacher and the School Curriculum',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'Educ. 10',
      title: 'Building and Enhancing New Literacies Across the Curriculum',
    ),
    BpedCurriculumSubject(
      yearLevel: 3,
      semesterLabel: '2nd Semester',
      code: 'GE Elec 3',
      title: 'Indigenous Creative Crafts',
    ),
    BpedCurriculumSubject(
      yearLevel: 4,
      semesterLabel: '1st Semester',
      code: 'FS 1',
      title: 'Field Study 1',
    ),
    BpedCurriculumSubject(
      yearLevel: 4,
      semesterLabel: '1st Semester',
      code: 'FS 2',
      title: 'Field Study 2',
    ),
    BpedCurriculumSubject(
      yearLevel: 4,
      semesterLabel: '1st Semester',
      code: 'Educ. 11',
      title: "Management of Students' Behavior and Wellness",
    ),
    BpedCurriculumSubject(
      yearLevel: 4,
      semesterLabel: '1st Semester',
      code: 'Educ. 12',
      title: 'Special Topics in Education',
    ),
    BpedCurriculumSubject(
      yearLevel: 4,
      semesterLabel: '2nd Semester',
      code: 'Educ. 13',
      title: 'Teaching Internship',
    ),
    BpedCurriculumSubject(
      yearLevel: 4,
      semesterLabel: '2nd Semester',
      code: 'Educ. 14',
      title: 'Comprehensive Examination',
    ),
  ];

  static List<BpedCurriculumSubject> subjectsFor({
    int? yearLevel,
    String? semesterLabel,
  }) {
    final normalizedSemester = normalizeSemesterLabel(semesterLabel);
    return subjects
        .where((subject) {
          final matchesYear =
              yearLevel == null || subject.yearLevel == yearLevel;
          final matchesSemester =
              normalizedSemester == null ||
              subject.semesterLabel == normalizedSemester;
          return matchesYear && matchesSemester;
        })
        .toList(growable: false);
  }

  static List<String> subjectOptions({int? yearLevel, String? semesterLabel}) {
    return subjectsFor(
      yearLevel: yearLevel,
      semesterLabel: semesterLabel,
    ).map((subject) => subject.label).toList(growable: false);
  }

  static String? normalizeSemesterLabel(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('2')) {
      return '2nd Semester';
    }
    if (normalized.startsWith('1')) {
      return '1st Semester';
    }
    return null;
  }

  static int? normalizeYearLevel(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value >= 1 && value <= 4 ? value : null;
    }

    final raw = value.toString().trim().toLowerCase();
    if (raw.isEmpty) {
      return null;
    }

    final digitMatch = RegExp(r'\b([1-4])(?:st|nd|rd|th)?\b').firstMatch(raw);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(1)!);
    }

    if (raw.contains('first')) {
      return 1;
    }
    if (raw.contains('second')) {
      return 2;
    }
    if (raw.contains('third')) {
      return 3;
    }
    if (raw.contains('fourth')) {
      return 4;
    }

    return null;
  }

  static int? inferYearLevel(String value) {
    return normalizeYearLevel(value);
  }

  static String formatYearLevel(int yearLevel) {
    switch (yearLevel) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      default:
        return '${yearLevel}th Year';
    }
  }

  static String? resolveSubjectSelection({
    String? currentValue,
    int? yearLevel,
    String? semesterLabel,
    String? preferredValue,
  }) {
    final candidates = subjectsFor(
      yearLevel: yearLevel,
      semesterLabel: semesterLabel,
    );
    String? fallback;

    for (final candidate in [preferredValue?.trim(), currentValue?.trim()]) {
      if (candidate == null || candidate.isEmpty) {
        continue;
      }
      fallback ??= candidate;
      for (final subject in candidates) {
        if (subject.matches(candidate)) {
          return subject.label;
        }
      }
    }

    if (candidates.isNotEmpty) {
      return candidates.first.label;
    }

    return fallback;
  }

  static String normalizeStoredSubject(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    for (final subject in subjects) {
      if (subject.matches(trimmed)) {
        return subject.label;
      }
    }

    return trimmed;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
