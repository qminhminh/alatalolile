import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

class MovieRepository {
  MovieRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _baseUrl = 'https://phimapi.com';
  Future<List<Movie>> latest() => _fetch(Uri.parse('$_baseUrl/v1/api/home'));
  Future<List<Movie>> category(String slug) => _fetch(
    Uri.parse('$_baseUrl/v1/api/danh-sach/$slug')
        .replace(queryParameters: {'limit': '12'}),
  );
  Future<List<Movie>> search(String keyword) => _fetch(
    Uri.parse('$_baseUrl/v1/api/tim-kiem')
        .replace(queryParameters: {'keyword': keyword}),
  );
  Future<List<Movie>> _fetch(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API request failed: ${response.statusCode}');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = root['data'];
    final items = data is Map<String, dynamic> ? data['items'] : null;
    return items is List
        ? items.whereType<Map<String, dynamic>>().map(Movie.fromJson).toList()
        : const [];
  }
}
