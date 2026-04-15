import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore firestore;

  UserRepository(this.firestore);

  // Stream all students
  Stream<List<AppUser>> getAllStudents() {
    return firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<AppUser?> getUserById(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }
      return AppUser.fromFirestore(data, doc.id);
    });
  }

  // Create or update user
  Future<void> createUser(AppUser user) async {
    await firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }
}
