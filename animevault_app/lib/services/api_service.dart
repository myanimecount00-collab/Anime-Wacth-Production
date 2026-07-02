import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/widgets/anime_detail_model.dart';
import '../models/widgets/stream_result.dart';

class ApiService {
  final String baseUrl = 'http://192.168.0.22:3000';

  Future<List<dynamic>> getTerbaru() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/terbaru'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Gagal mengambil data terbaru. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<AnimeDetailModel> getDetail(String url) async {
    try {
      final start = DateTime.now();
      final response = await http.get(
        Uri.parse('$baseUrl/api/detail?url=${Uri.encodeComponent(url)}'),
      );
      debugPrint(
        "API DETAIL: ${DateTime.now().difference(start).inMilliseconds} ms",
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return AnimeDetailModel.fromJson(json);
      } else {
        throw Exception(
          'Gagal mengambil detail anime. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getHomeGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/home'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Gagal mengambil data genre. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // 🔁 Method getStream sekarang mengembalikan StreamResult
  Future<StreamResult> getStream(String episodeUrl) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/stream?url=${Uri.encodeComponent(episodeUrl)}',
        ),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return StreamResult.fromJson(json);
      } else {
        throw Exception(
          'Gagal mengambil stream. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}