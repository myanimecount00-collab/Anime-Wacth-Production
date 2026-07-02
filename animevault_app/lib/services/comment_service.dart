import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addComment({
    required String animeId,
    required int episode,
    required String userId,
    required String userName,
    required String userPhoto,
    required String message,
  }) async {
    await _db.collection('comments').add({
      'animeId': animeId,
      'episode': episode,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getComments(
    String animeId,
    int episode,
  ) {
    return _db
        .collection('comments')
        .where('animeId', isEqualTo: animeId)
        .where('episode', isEqualTo: episode)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}