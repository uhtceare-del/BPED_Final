import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'bped_curriculum_service.dart';

const _seedSource = 'production_report_demo_v1';

class ProductionSeedResult {
  const ProductionSeedResult({
    required this.usersCreated,
    required this.instructorsCreated,
    required this.studentsCreated,
    required this.classesCreated,
    required this.lessonsCreated,
    required this.reviewersCreated,
    required this.tasksCreated,
    required this.submissionsCreated,
  });

  final int usersCreated;
  final int instructorsCreated;
  final int studentsCreated;
  final int classesCreated;
  final int lessonsCreated;
  final int reviewersCreated;
  final int tasksCreated;
  final int submissionsCreated;
}

class _SeedUser {
  const _SeedUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.yearLevel,
    required this.section,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String yearLevel;
  final String section;
  final DateTime createdAt;
}

class _SeedClass {
  const _SeedClass({
    required this.id,
    required this.className,
    required this.subject,
    required this.schedule,
    required this.classCode,
    required this.semesterLabel,
    required this.instructorId,
    required this.yearLevel,
    required this.section,
    required this.students,
  });

  final String id;
  final String className;
  final String subject;
  final String schedule;
  final String classCode;
  final String semesterLabel;
  final String instructorId;
  final String yearLevel;
  final String section;
  final List<_SeedUser> students;
}

class _SeedLesson {
  const _SeedLesson({
    required this.id,
    required this.classId,
    required this.instructorId,
    required this.subject,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.pdfUrl,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String classId;
  final String instructorId;
  final String subject;
  final String title;
  final String description;
  final String videoUrl;
  final String pdfUrl;
  final String category;
  final DateTime createdAt;
}

class _SeedTask {
  const _SeedTask({
    required this.id,
    required this.classId,
    required this.instructorId,
    required this.lessonId,
    required this.title,
    required this.description,
    required this.maxScore,
    required this.deadline,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String classId;
  final String instructorId;
  final String lessonId;
  final String title;
  final String description;
  final int maxScore;
  final DateTime deadline;
  final String kind;
  final DateTime createdAt;
}

class _BatchedWriter {
  _BatchedWriter(this.firestore);

  final FirebaseFirestore firestore;
  WriteBatch? _batch;
  int _ops = 0;

  Future<void> set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    final batch = _ensureBatch();
    batch.set(ref, data);
    _ops += 1;
    await _flushIfNeeded();
  }

  Future<void> delete(DocumentReference<Map<String, dynamic>> ref) async {
    final batch = _ensureBatch();
    batch.delete(ref);
    _ops += 1;
    await _flushIfNeeded();
  }

  Future<void> flush() async {
    final batch = _batch;
    if (batch == null || _ops == 0) {
      return;
    }

    _batch = null;
    _ops = 0;
    await batch.commit();
  }

  WriteBatch _ensureBatch() {
    return _batch ??= firestore.batch();
  }

  Future<void> _flushIfNeeded() async {
    if (_ops >= 400) {
      await flush();
    }
  }
}

Future<void> seedUsers() async {
  await seedProductionDataset();
}

Future<ProductionSeedResult> seedProductionDataset({
  int totalUsers = 200,
  int instructorCount = 12,
  int classCount = 16,
  int lessonsPerClass = 2,
  int tasksPerClass = 3,
  int reviewersPerClass = 1,
}) async {
  if (totalUsers < 40) {
    throw Exception('Use at least 40 users for a meaningful production demo.');
  }
  if (instructorCount < 4) {
    throw Exception('Use at least 4 instructors.');
  }
  if (classCount < 4) {
    throw Exception('Use at least 4 classes.');
  }
  if (classCount > 16) {
    throw Exception('The production demo currently supports up to 16 classes.');
  }
  if (totalUsers <= instructorCount) {
    throw Exception('Total users must be greater than instructor count.');
  }

  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final random = Random(42);

  await _clearPriorSeedDataset(firestore);

  final instructors = _buildInstructors(
    firestore: firestore,
    count: instructorCount,
    now: now,
    random: random,
  );
  final classes = _buildClasses(
    firestore: firestore,
    instructors: instructors,
    classCount: classCount,
  );
  final students = _buildStudents(
    firestore: firestore,
    totalStudents: totalUsers - instructorCount,
    classes: classes,
    now: now,
    random: random,
  );
  final classesWithStudents = _attachStudentsToClasses(
    classes: classes,
    students: students,
  );
  final lessons = _buildLessons(
    firestore: firestore,
    classes: classesWithStudents,
    lessonsPerClass: lessonsPerClass,
    now: now,
  );
  final tasks = _buildTasks(
    firestore: firestore,
    classes: classesWithStudents,
    lessons: lessons,
    tasksPerClass: tasksPerClass,
    now: now,
  );
  final reviewers = _buildReviewers(
    firestore: firestore,
    classes: classesWithStudents,
    reviewersPerClass: reviewersPerClass,
    now: now,
  );
  final submissions = _buildSubmissions(
    firestore: firestore,
    classes: classesWithStudents,
    tasks: tasks,
    now: now,
    random: random,
  );

  final writer = _BatchedWriter(firestore);

  for (final instructor in instructors) {
    final ref = firestore.collection('users').doc(instructor.id);
    await writer.set(ref, {
      'uid': instructor.id,
      'fullName': instructor.fullName,
      'email': instructor.email,
      'role': instructor.role,
      'avatarUrl': '',
      'createdAt': Timestamp.fromDate(instructor.createdAt),
      'section': '',
      'yearLevel': '',
      'onboardingCompleted': true,
      'isDeleted': false,
      'isDisabled': false,
      'seedSource': _seedSource,
    });
  }

  for (final student in students) {
    final ref = firestore.collection('users').doc(student.id);
    await writer.set(ref, {
      'uid': student.id,
      'fullName': student.fullName,
      'email': student.email,
      'role': student.role,
      'avatarUrl': '',
      'createdAt': Timestamp.fromDate(student.createdAt),
      'section': student.section,
      'yearLevel': student.yearLevel,
      'onboardingCompleted': true,
      'isDeleted': false,
      'isDisabled': false,
      'seedSource': _seedSource,
    });
  }

  for (final cls in classesWithStudents) {
    final ref = firestore.collection('classes').doc(cls.id);
    await writer.set(ref, {
      'className': cls.className,
      'yearLevel': cls.yearLevel,
      'subject': cls.subject,
      'schedule': cls.schedule,
      'classCode': cls.classCode,
      'semesterLabel': cls.semesterLabel,
      'instructorId': cls.instructorId,
      'enrolledStudentIds': cls.students.map((student) => student.id).toList(),
      'createdAt': Timestamp.fromDate(now.subtract(Duration(days: 90))),
      'seedSource': _seedSource,
    });
  }

  for (final lesson in lessons) {
    final ref = firestore.collection('lessons').doc(lesson.id);
    await writer.set(ref, {
      'courseId': 'BPED',
      'classId': lesson.classId,
      'subject': lesson.subject,
      'title': lesson.title,
      'description': lesson.description,
      'videoUrl': lesson.videoUrl,
      'pdfUrl': lesson.pdfUrl,
      'category': lesson.category,
      'instructorId': lesson.instructorId,
      'createdAt': Timestamp.fromDate(lesson.createdAt),
      'isDeleted': false,
      'seedSource': _seedSource,
    });
  }

  for (final reviewer in reviewers) {
    await writer.set(reviewer.$1, reviewer.$2);
  }

  for (final task in tasks) {
    final ref = firestore.collection('tasks').doc(task.id);
    await writer.set(ref, {
      'lessonId': task.lessonId,
      'title': task.title,
      'description': task.description,
      'maxScore': task.maxScore,
      'deadline': Timestamp.fromDate(task.deadline),
      'instructorId': task.instructorId,
      'classId': task.classId,
      'kind': task.kind,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'isDeleted': false,
      'seedSource': _seedSource,
    });
  }

  for (final submission in submissions) {
    await writer.set(submission.$1, submission.$2);
  }

  await writer.flush();

  return ProductionSeedResult(
    usersCreated: instructors.length + students.length,
    instructorsCreated: instructors.length,
    studentsCreated: students.length,
    classesCreated: classesWithStudents.length,
    lessonsCreated: lessons.length,
    reviewersCreated: reviewers.length,
    tasksCreated: tasks.length,
    submissionsCreated: submissions.length,
  );
}

Future<void> _clearPriorSeedDataset(FirebaseFirestore firestore) async {
  const collections = [
    'submissions',
    'tasks',
    'reviewers',
    'lessons',
    'classes',
    'users',
  ];

  for (final collection in collections) {
    final snapshot = await firestore
        .collection(collection)
        .where('seedSource', isEqualTo: _seedSource)
        .get();

    final writer = _BatchedWriter(firestore);
    for (final doc in snapshot.docs) {
      await writer.delete(doc.reference);
    }
    await writer.flush();
  }
}

List<_SeedUser> _buildInstructors({
  required FirebaseFirestore firestore,
  required int count,
  required DateTime now,
  required Random random,
}) {
  return List.generate(count, (index) {
    final ref = firestore.collection('users').doc();
    return _SeedUser(
      id: ref.id,
      fullName: _buildFullName(index, role: 'Instructor'),
      email: 'instructor.${index + 1}@demo.bped.local',
      role: 'instructor',
      yearLevel: '',
      section: '',
      createdAt: now.subtract(Duration(days: 120 + random.nextInt(280))),
    );
  });
}

List<_SeedClass> _buildClasses({
  required FirebaseFirestore firestore,
  required List<_SeedUser> instructors,
  required int classCount,
}) {
  const sectionLetters = ['A', 'B', 'C', 'D'];
  const schedules = [
    'Mon/Wed 8:00AM',
    'Mon/Wed 1:00PM',
    'Tue/Thu 9:30AM',
    'Tue/Thu 2:30PM',
    'Fri 8:00AM',
    'Fri 1:00PM',
  ];

  final classes = <_SeedClass>[];
  var index = 0;

  for (var year = 1; year <= 4 && classes.length < classCount; year++) {
    for (
      var sectionIndex = 0;
      sectionIndex < sectionLetters.length && classes.length < classCount;
      sectionIndex++
    ) {
      final ref = firestore.collection('classes').doc();
      final yearKey = '$year';
      final semesterLabel = sectionIndex.isEven
          ? '1st Semester'
          : '2nd Semester';
      final subjectOptions = BpedCurriculumService.subjectOptions(
        yearLevel: year,
        semesterLabel: semesterLabel,
      );
      final subjectIndex = (sectionIndex ~/ 2) % subjectOptions.length;
      classes.add(
        _SeedClass(
          id: ref.id,
          className: 'BPED $year-${sectionLetters[sectionIndex]}',
          subject: subjectOptions[subjectIndex],
          schedule: schedules[index % schedules.length],
          classCode: 'DMO$year${sectionIndex + 1}${index + 10}',
          semesterLabel: semesterLabel,
          instructorId: instructors[index % instructors.length].id,
          yearLevel: yearKey,
          section: 'PE-$year${sectionIndex + 1}',
          students: const [],
        ),
      );
      index += 1;
    }
  }

  return classes;
}

List<_SeedUser> _buildStudents({
  required FirebaseFirestore firestore,
  required int totalStudents,
  required List<_SeedClass> classes,
  required DateTime now,
  required Random random,
}) {
  final classSizes = _allocateClassSizes(
    totalStudents: totalStudents,
    classCount: classes.length,
    random: random,
  );
  final students = <_SeedUser>[];
  var runningIndex = 0;

  for (var classIndex = 0; classIndex < classes.length; classIndex++) {
    final cls = classes[classIndex];
    for (var i = 0; i < classSizes[classIndex]; i++) {
      final ref = firestore.collection('users').doc();
      final studentNumber = runningIndex + 1;
      students.add(
        _SeedUser(
          id: ref.id,
          fullName: _buildFullName(studentNumber, role: 'Student'),
          email: 'student.$studentNumber@demo.bped.local',
          role: 'student',
          yearLevel: cls.yearLevel,
          section: cls.section,
          createdAt: now.subtract(Duration(days: 20 + random.nextInt(360))),
        ),
      );
      runningIndex += 1;
    }
  }

  return students;
}

List<_SeedClass> _attachStudentsToClasses({
  required List<_SeedClass> classes,
  required List<_SeedUser> students,
}) {
  final queue = [...students];
  final classesWithStudents = <_SeedClass>[];

  for (final cls in classes) {
    final classStudents = queue
        .where(
          (student) =>
              student.yearLevel == cls.yearLevel &&
              student.section == cls.section,
        )
        .toList();
    queue.removeWhere(
      (student) =>
          student.yearLevel == cls.yearLevel && student.section == cls.section,
    );

    classesWithStudents.add(
      _SeedClass(
        id: cls.id,
        className: cls.className,
        subject: cls.subject,
        schedule: cls.schedule,
        classCode: cls.classCode,
        semesterLabel: cls.semesterLabel,
        instructorId: cls.instructorId,
        yearLevel: cls.yearLevel,
        section: cls.section,
        students: classStudents,
      ),
    );
  }

  return classesWithStudents;
}

List<_SeedLesson> _buildLessons({
  required FirebaseFirestore firestore,
  required List<_SeedClass> classes,
  required int lessonsPerClass,
  required DateTime now,
}) {
  const categories = ['Technique', 'Assessment', 'Wellness', 'Strategy'];
  const titles = [
    'Module Overview',
    'Applied Practice',
    'Performance Lab',
    'Skill Development',
  ];

  final lessons = <_SeedLesson>[];

  for (final cls in classes) {
    for (var i = 0; i < lessonsPerClass; i++) {
      final ref = firestore.collection('lessons').doc();
      lessons.add(
        _SeedLesson(
          id: ref.id,
          classId: cls.id,
          instructorId: cls.instructorId,
          subject: cls.subject,
          title: '${titles[i % titles.length]}: ${cls.subject}',
          description:
              'Production demo content for ${cls.className} focused on ${cls.subject.toLowerCase()}.',
          videoUrl: i.isEven
              ? 'https://example.com/videos/${cls.id}_lesson_$i.mp4'
              : '',
          pdfUrl: 'https://example.com/handouts/${cls.id}_lesson_$i.pdf',
          category: categories[i % categories.length],
          createdAt: now.subtract(Duration(days: 45 - (i * 6))),
        ),
      );
    }
  }

  return lessons;
}

List<_SeedTask> _buildTasks({
  required FirebaseFirestore firestore,
  required List<_SeedClass> classes,
  required List<_SeedLesson> lessons,
  required int tasksPerClass,
  required DateTime now,
}) {
  const taskTitles = [
    'Skill demonstration',
    'Reflection journal',
    'Midterm checkpoint',
    'Peer analysis',
  ];
  final lessonsByClass = <String, List<_SeedLesson>>{};
  for (final lesson in lessons) {
    lessonsByClass.putIfAbsent(lesson.classId, () => []).add(lesson);
  }

  final tasks = <_SeedTask>[];

  for (final cls in classes) {
    final classLessons = lessonsByClass[cls.id] ?? const <_SeedLesson>[];
    for (var i = 0; i < tasksPerClass; i++) {
      final ref = firestore.collection('tasks').doc();
      final deadline = switch (i % 3) {
        0 => now.subtract(Duration(days: 18 + (cls.students.length % 4))),
        1 => now.subtract(Duration(days: 3 + (cls.students.length % 2))),
        _ => now.add(Duration(days: 9 + (cls.students.length % 5))),
      };

      tasks.add(
        _SeedTask(
          id: ref.id,
          classId: cls.id,
          instructorId: cls.instructorId,
          lessonId: classLessons.isEmpty
              ? ''
              : classLessons[i % classLessons.length].id,
          title: '${taskTitles[i % taskTitles.length]} - ${cls.className}',
          description:
              'Seeded production-style task for ${cls.subject} in ${cls.className}.',
          maxScore: i == tasksPerClass - 1 ? 50 : 100,
          deadline: deadline,
          kind: i == tasksPerClass - 1 ? 'quiz' : 'task',
          createdAt: deadline.subtract(const Duration(days: 7)).isAfter(now)
              ? now.subtract(const Duration(days: 1))
              : deadline.subtract(const Duration(days: 7)),
        ),
      );
    }
  }

  return tasks;
}

List<(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>
_buildReviewers({
  required FirebaseFirestore firestore,
  required List<_SeedClass> classes,
  required int reviewersPerClass,
  required DateTime now,
}) {
  final reviewers =
      <(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>[];

  for (final cls in classes) {
    for (var i = 0; i < reviewersPerClass; i++) {
      final ref = firestore.collection('reviewers').doc();
      reviewers.add((
        ref,
        {
          'title': 'Reviewer ${i + 1} - ${cls.className}',
          'fileUrl': 'https://example.com/reviewers/${cls.id}_$i.pdf',
          'category': i.isEven ? 'Practical' : 'Lecture',
          'subject': cls.subject,
          'uploadedAt': Timestamp.fromDate(
            now.subtract(Duration(days: 30 - (i * 3))),
          ),
          'instructorId': cls.instructorId,
          'classId': cls.id,
          'isDeleted': false,
          'seedSource': _seedSource,
        },
      ));
    }
  }

  return reviewers;
}

List<(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>
_buildSubmissions({
  required FirebaseFirestore firestore,
  required List<_SeedClass> classes,
  required List<_SeedTask> tasks,
  required DateTime now,
  required Random random,
}) {
  final classesById = {for (final cls in classes) cls.id: cls};
  final submissions =
      <(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>[];

  for (final task in tasks) {
    final cls = classesById[task.classId];
    if (cls == null) {
      continue;
    }

    final isPastDeadline = task.deadline.isBefore(now);
    final submissionChance = isPastDeadline ? 0.78 : 0.42;

    for (final student in cls.students) {
      if (random.nextDouble() > submissionChance) {
        continue;
      }

      final lateChance = isPastDeadline ? 0.22 : 0.0;
      final isLate = random.nextDouble() < lateChance;
      final submittedAt = isPastDeadline
          ? (isLate
                ? task.deadline.add(Duration(hours: 4 + random.nextInt(72)))
                : task.deadline.subtract(
                    Duration(hours: 5 + random.nextInt(96)),
                  ))
          : now.subtract(Duration(hours: 8 + random.nextInt(96)));
      final graded = isPastDeadline && random.nextDouble() < 0.63;

      final ref = firestore.collection('submissions').doc();
      submissions.add((
        ref,
        {
          'taskId': task.id,
          'studentId': student.id,
          'studentEmail': student.email,
          'fileUrl':
              'https://example.com/submissions/${task.id}_${student.id}.pdf',
          'submittedAt': Timestamp.fromDate(submittedAt),
          'grade': graded ? '${65 + random.nextInt(31)}' : null,
          'instructorId': task.instructorId,
          'seedSource': _seedSource,
        },
      ));
    }
  }

  return submissions;
}

List<int> _allocateClassSizes({
  required int totalStudents,
  required int classCount,
  required Random random,
}) {
  final sizes = List<int>.filled(classCount, 8);
  var remaining = totalStudents - (classCount * 8);

  if (remaining < 0) {
    throw Exception('Not enough students to seed each class realistically.');
  }

  while (remaining > 0) {
    final index = random.nextInt(classCount);
    if (sizes[index] >= 18) {
      continue;
    }
    sizes[index] += 1;
    remaining -= 1;
  }

  return sizes;
}

String _buildFullName(int index, {required String role}) {
  const firstNames = [
    'Alex',
    'Bianca',
    'Carlo',
    'Diane',
    'Ethan',
    'Faith',
    'Gian',
    'Hannah',
    'Ivan',
    'Janelle',
    'Kyle',
    'Lara',
    'Marcus',
    'Nica',
    'Owen',
    'Paula',
    'Quinn',
    'Rafael',
    'Sofia',
    'Tristan',
    'Una',
    'Vince',
    'Wendy',
    'Xavier',
    'Yasmin',
    'Zion',
  ];
  const lastNames = [
    'Santos',
    'Reyes',
    'Cruz',
    'Garcia',
    'Mendoza',
    'Torres',
    'Flores',
    'Aquino',
    'Navarro',
    'Bautista',
    'Lopez',
    'Ramos',
    'Villanueva',
    'Castillo',
    'Fernandez',
    'Morales',
    'Domingo',
    'Salazar',
    'Valdez',
    'Pineda',
  ];

  final first = firstNames[index % firstNames.length];
  final last = lastNames[(index ~/ firstNames.length) % lastNames.length];
  final suffix = index >= (firstNames.length * lastNames.length)
      ? ' ${index + 1}'
      : '';

  return role == 'Instructor'
      ? '$first $last$suffix, MAPEH'
      : '$first $last$suffix';
}
