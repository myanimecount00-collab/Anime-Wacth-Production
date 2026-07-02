import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/widgets/watch_history.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper: membangun collection reference untuk user tertentu
  CollectionReference<Map<String, dynamic>> _historyCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('history');
  }

  // ──────────────────────── HISTORY ────────────────────────

  Future<void> saveHistory(WatchHistory history) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _historyCollection(uid)
        .doc(Uri.encodeComponent(history.link))
        .set({
      'title': history.title,
      'thumb': history.thumb,
      'link': history.link,
      'currentEpisode': history.currentEpisode,
      'totalEpisodes': history.totalEpisodes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Jaga maksimal 20 entri
    final snapshot = await _historyCollection(uid)
        .orderBy('updatedAt', descending: true)
        .get();

    if (snapshot.docs.length > 20) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs.sublist(20)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<List<WatchHistory>> loadHistory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _historyCollection(uid)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return WatchHistory(
        title: data['title'] ?? '',
        thumb: data['thumb'] ?? '',
        link: data['link'] ?? '',
        currentEpisode: data['currentEpisode'] ?? 0,
        totalEpisodes: data['totalEpisodes'] ?? 0,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  Future<void> deleteHistory(String link) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _historyCollection(uid)
        .doc(Uri.encodeComponent(link))
        .delete();
  }

  /// Menyimpan banyak entri history sekaligus dalam satu batch
  Future<void> saveAllHistory(List<WatchHistory> historyList) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = _firestore.batch();

    for (final history in historyList) {
      final doc = _historyCollection(uid).doc(
        Uri.encodeComponent(history.link),
      );

      batch.set(doc, {
        'title': history.title,
        'thumb': history.thumb,
        'link': history.link,
        'currentEpisode': history.currentEpisode,
        'totalEpisodes': history.totalEpisodes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ──────────────────── USER PROFILE ───────────────────────

  /// Membuat dokumen user di `users/{uid}` jika belum ada
  Future<void> createUserIfNotExists() async {
    try {
      print("STEP USER 1");

      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print("USER NULL");
        return;
      }

print("PROJECT = ${FirebaseFirestore.instance.app.options.projectId}");
print("UID = ${_auth.currentUser?.uid}");

      final userDoc = _firestore.collection('users').doc(uid);
      final snapshot = await userDoc.get();

      print("EXISTS = ${snapshot.exists}");

      if (!snapshot.exists) {
        await userDoc.set({
          'uid': uid,
          'email': _auth.currentUser?.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("USER CREATED");
      }
    } catch (e, s) {
      print("FIRESTORE ERROR");
      print(e);
      print(s);
    }
  }
}