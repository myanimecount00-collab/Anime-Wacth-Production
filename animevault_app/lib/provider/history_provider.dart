import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/widgets/watch_history.dart';
import '../models/widgets/anime_model.dart';
import '../services/firestore_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<WatchHistory> _history = [];
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<User?>? _authSubscription;

  List<WatchHistory> get history => _history;

  // ──────────────────────── ADD & SAVE ────────────────────────
  Future<void> addHistory(AnimeModel anime) async {
    final entry = WatchHistory(
      title: anime.title,
      thumb: anime.thumb,
      link: anime.link,
      currentEpisode: 0,
      totalEpisodes: 0,
      updatedAt: DateTime.now(),
    );
    _history.removeWhere((e) => e.link == entry.link);
    _history.insert(0, entry);
    if (_history.length > 20) {
      _history.removeLast();
    }
    await saveHistory();
    await _firestoreService.saveHistory(_history.first);
    notifyListeners();
  }

  Future<void> saveWatchHistory({
    required String title,
    required String thumb,
    required String link,
    required int currentEpisode,
    required int totalEpisodes,
  }) async {
    final entry = WatchHistory(
      title: title,
      thumb: thumb,
      link: link,
      currentEpisode: currentEpisode,
      totalEpisodes: totalEpisodes,
      updatedAt: DateTime.now(),
    );
    _history.removeWhere((e) => e.link == link);
    _history.insert(0, entry);
    if (_history.length > 20) {
      _history.removeLast();
    }
    await saveHistory();
    await _firestoreService.saveHistory(_history.first);
    notifyListeners();
  }

  // ──────────────────── LOCAL STORAGE ─────────────────────────
  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'watch_history',
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('watch_history');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _history = decoded.map((e) => WatchHistory.fromJson(e)).toList();
    }
    notifyListeners();
  }

  // ──────────────────── INISIALISASI ──────────────────────────
  Future<void> initialize() async {
    await loadHistory();
    await mergeHistory();

    // Pantau perubahan login/logout
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await mergeHistory();
      }
    });
  }

  // ──────────────────── MERGE CLOUD & LOCAL ───────────────────
  Future<void> mergeHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudHistory = await _firestoreService.loadHistory();

    final Map<String, WatchHistory> merged = {};

    // Masukkan semua history lokal ke dalam Map
    for (final item in _history) {
      merged[item.link] = item;
    }

    // Proses data cloud
    for (final cloud in cloudHistory) {
      if (!merged.containsKey(cloud.link)) {
        merged[cloud.link] = cloud;
      } else {
        final local = merged[cloud.link]!;

        // Bandingkan episode dan timestamp
        if (cloud.currentEpisode > local.currentEpisode) {
          merged[cloud.link] = cloud;
        } else if (cloud.currentEpisode == local.currentEpisode) {
          final cloudTime = cloud.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final localTime = local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (cloudTime.isAfter(localTime)) {
            merged[cloud.link] = cloud;
          }
        }
      }
    }

    // Konversi Map ke List
    _history = merged.values.toList();

    // Urutkan berdasarkan updatedAt terbaru
    _history.sort((a, b) {
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    // Jaga maksimal 20 entri
    if (_history.length > 20) {
      _history = _history.sublist(0, 20);
    }

    // Simpan ke lokal dan cloud
    await saveHistory();
    await _firestoreService.saveAllHistory(_history);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}