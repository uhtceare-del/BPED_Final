import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../services/soft_delete_service.dart';

final _db = FirebaseFirestore.instance;
final _softDeleteService = SoftDeleteService();

final adminUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final db = ref.watch(firestoreProvider);
  final stream = db
      .collection('users')
      .snapshots()
      .map(
        (s) => s.docs
            .where(
              (d) =>
                  d.data()['isDeleted'] != true &&
                  d.data()['isDisabled'] != true,
            )
            .map((d) => {'id': d.id, ...d.data()})
            .toList(),
      );
  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <Map<String, dynamic>>[],
  );
});

final adminDisabledUsersProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final db = ref.watch(firestoreProvider);
  final stream = db
      .collection('users')
      .snapshots()
      .map(
        (s) => s.docs
            .where(
              (d) =>
                  d.data()['isDeleted'] != true &&
                  d.data()['isDisabled'] == true,
            )
            .map((d) => {'id': d.id, ...d.data()})
            .toList(),
      );
  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <Map<String, dynamic>>[],
  );
});

final adminDeletedUsersProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final service = SoftDeleteService(firestore: ref.watch(firestoreProvider));
  final stream = service
      .getTrash('users')
      .map((docs) => docs.map((d) => {'id': d.id, ...d.data()}).toList());
  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <Map<String, dynamic>>[],
  );
});

final adminSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  if (ref.watch(signOutInProgressProvider)) {
    return {'students': 0, 'classes': 0, 'tasks': 0, 'submissions': 0};
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return {'students': 0, 'classes': 0, 'tasks': 0, 'submissions': 0};
  }

  final db = ref.watch(firestoreProvider);
  return guardAuthTransitionFuture(
    ref,
    () async {
      final results = await Future.wait([
        db
            .collection('users')
            .where('role', isEqualTo: 'student')
            .count()
            .get(),
        db.collection('classes').count().get(),
        db.collection('tasks').count().get(),
        db.collection('submissions').count().get(),
      ]);

      return {
        'students': results[0].count ?? 0,
        'classes': results[1].count ?? 0,
        'tasks': results[2].count ?? 0,
        'submissions': results[3].count ?? 0,
      };
    },
    fallbackValue: {'students': 0, 'classes': 0, 'tasks': 0, 'submissions': 0},
  );
});

final adminLessonsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final db = ref.watch(firestoreProvider);
  final stream = db
      .collection('lessons')
      .snapshots()
      .map(
        (s) => s.docs
            .where((d) => d.data()['isDeleted'] != true)
            .map((d) => {'id': d.id, ...d.data()})
            .toList(),
      );
  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <Map<String, dynamic>>[],
  );
});

final adminReviewersProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final db = ref.watch(firestoreProvider);
  final stream = db
      .collection('reviewers')
      .snapshots()
      .map(
        (s) => s.docs
            .where((d) => d.data()['isDeleted'] != true)
            .map((d) => {'id': d.id, ...d.data()})
            .toList(),
      );
  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <Map<String, dynamic>>[],
  );
});

final adminTasksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  final db = ref.watch(firestoreProvider);
  final stream = db
      .collection('tasks')
      .snapshots()
      .map(
        (s) => s.docs
            .where((d) => d.data()['isDeleted'] != true)
            .map((d) => {'id': d.id, ...d.data()})
            .toList(),
      );
  return guardAuthTransitionStream(
    ref,
    stream,
    fallbackValue: const <Map<String, dynamic>>[],
  );
});

Future<void> adminCreateUser(Map<String, dynamic> data) async {
  final email = data['email'] as String;
  final password = (data['password'] as String?)?.trim();
  final role = (data['role'] as String?)?.trim() ?? 'student';

  if (password != null && password.isNotEmpty) {
    final appName = 'AdminSecondary_${DateTime.now().millisecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: Firebase.app().options,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final secondaryDb = FirebaseFirestore.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      await secondaryDb.collection('users').doc(uid).set({
        ...Map<String, dynamic>.from(data)..remove('password'),
        'uid': uid,
        'role': role,
        'avatarUrl': data['avatarUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': data['onboardingCompleted'] ?? true,
        'isDeleted': false,
        'isDisabled': false,
      });
      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
    return;
  }

  final ref = await _db.collection('users').add({
    ...Map<String, dynamic>.from(data)..remove('password'),
    'role': role,
    'avatarUrl': data['avatarUrl'] ?? '',
    'createdAt': FieldValue.serverTimestamp(),
    'onboardingCompleted': data['onboardingCompleted'] ?? true,
    'isDeleted': false,
    'isDisabled': false,
  });
  await ref.update({'uid': ref.id});
}

Future<void> adminUpdateUser(String uid, Map<String, dynamic> data) {
  return _db.collection('users').doc(uid).update(data);
}

Future<void> adminDisableUser(String uid, {String? disabledBy}) {
  final updates = <String, dynamic>{
    'isDisabled': true,
    'disabledAt': FieldValue.serverTimestamp(),
  };
  if (disabledBy != null) {
    updates['disabledBy'] = disabledBy;
  }
  return _db.collection('users').doc(uid).update(updates);
}

Future<void> adminEnableUser(String uid) {
  return _db.collection('users').doc(uid).update({
    'isDisabled': false,
    'disabledAt': FieldValue.delete(),
    'disabledBy': FieldValue.delete(),
  });
}

Future<void> adminDeleteUser(String uid, {String? deletedBy}) {
  return _softDeleteService.softDelete('users', uid, deletedBy: deletedBy);
}

Future<void> adminRestoreUser(String uid) {
  return _softDeleteService.restore('users', uid);
}

Future<void> adminUpdateLesson(String id, Map<String, dynamic> data) {
  return _db.collection('lessons').doc(id).update(data);
}

Future<void> adminUpdateReviewer(String id, Map<String, dynamic> data) {
  return _db.collection('reviewers').doc(id).update(data);
}

Future<void> adminUpdateTask(String id, Map<String, dynamic> data) {
  return _db.collection('tasks').doc(id).update(data);
}

Future<void> adminDeleteTask(String id, {String? deletedBy}) {
  return _softDeleteService.softDelete('tasks', id, deletedBy: deletedBy);
}

Future<void> adminDeleteLesson(String id, {String? deletedBy}) {
  return _softDeleteService.softDelete('lessons', id, deletedBy: deletedBy);
}

Future<void> adminDeleteReviewer(String id, {String? deletedBy}) {
  return _softDeleteService.softDelete('reviewers', id, deletedBy: deletedBy);
}
