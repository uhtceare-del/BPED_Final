import 'package:cloud_firestore/cloud_firestore.dart';

class SoftDeleteService {
  SoftDeleteService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> softDelete(
    String collection,
    String docId, {
    String? deletedBy,
  }) async {
    final updates = <String, Object?>{
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    };
    if (deletedBy != null) {
      updates['deletedBy'] = deletedBy;
    }
    await _db.collection(collection).doc(docId).update(updates);
  }

  Future<void> restore(String collection, String docId) async {
    await _db.collection(collection).doc(docId).update({
      'isDeleted': false,
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
    });
  }

  Future<void> hardDelete(String collection, String docId) {
    return _db.collection(collection).doc(docId).delete();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getTrash(
    String collection,
  ) {
    return _db
        .collection(collection)
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs);
  }
}
