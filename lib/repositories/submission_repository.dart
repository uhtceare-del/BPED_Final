import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';
import '../core/app_exceptions.dart';
import 'repository_validators.dart';

class SubmissionRepository {
  final FirebaseFirestore firestore;
  SubmissionRepository(this.firestore);

  /// Create submission with validation and authorization
  Future<void> createSubmission(
    SubmissionModel submission, {
    required String currentUserId,
  }) async {
    try {
      // Validate user can only submit for themselves
      if (submission.studentId != currentUserId) {
        throw AuthException(
          'Cannot submit on behalf of another student',
          code: 'unauthorized-submission',
        );
      }

      final data = submission.toFirestore();
      RepositoryValidators.validateSubmissionData(data);

      await firestore.collection('submissions').add(data);
    } on ValidationException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to submit task', originalError: error);
    }
  }

  /// Update grade with validation - instructors only
  Future<void> updateGrade(
    String submissionId,
    num grade, {
    required String instructorRole,
  }) async {
    try {
      if (instructorRole != 'instructor' && instructorRole != 'admin') {
        throw AuthException(
          'Only instructors can grade submissions',
          code: 'insufficient-permissions',
        );
      }

      RepositoryValidators.validateGradeData({'grade': grade});

      await firestore.collection('submissions').doc(submissionId).update({
        'grade': grade,
        'gradedAt': FieldValue.serverTimestamp(),
      });
    } on ValidationException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to update grade', originalError: error);
    }
  }

  Stream<List<SubmissionModel>> getAllSubmissions() {
    return firestore
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubmissionModel.fromFirestore(doc))
              .toList(),
        )
        .handleError(
          (error) => throw DatabaseException(
            'Failed to fetch submissions',
            originalError: error,
          ),
        );
  }

  Stream<List<SubmissionModel>> getSubmissionsByTask(String taskId) {
    return firestore
        .collection('submissions')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubmissionModel.fromFirestore(doc))
              .toList(),
        )
        .handleError(
          (error) => throw DatabaseException(
            'Failed to fetch task submissions',
            originalError: error,
          ),
        );
  }

  Stream<List<SubmissionModel>> getSubmissionsByStudent(String studentId) {
    return firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubmissionModel.fromFirestore(doc))
              .toList(),
        )
        .handleError(
          (error) => throw DatabaseException(
            'Failed to fetch student submissions',
            originalError: error,
          ),
        );
  }
}
