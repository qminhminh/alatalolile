import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

class MovieRepository {
  MovieRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _baseUrl = 'https://phimapi.com';
  Future<List<Movie>> latest() => _fetch(Uri.parse('$_baseUrl/v1/api/home'));
  Future<List<Movie>> category(String slug, {int page = 1}) => _fetch(
    Uri.parse('$_baseUrl/v1/api/danh-sach/$slug')
        .replace(queryParameters: {'limit': '24', 'page': '$page'}),
  );
  Future<List<Movie>> search(String keyword) => _fetch(
    Uri.parse('$_baseUrl/v1/api/tim-kiem')
        .replace(queryParameters: {'keyword': keyword}),
  );
  Future<List<Map<String, String>>> options(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl/$path'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể tải bộ lọc');
    }
    final root = jsonDecode(response.body);
    final items = root is Map
        ? root['data'] is Map
              ? root['data']['items']
              : root['items']
        : root;
    return items is List
        ? items
              .whereType<Map>()
              .map(
                (item) => {
                  'name': '${item['name'] ?? ''}',
                  'slug': '${item['slug'] ?? ''}',
                },
              )
              .toList()
        : const [];
  }

  Future<List<Map<String, String>>> categories() => options('the-loai');
  Future<List<Map<String, String>>> countries() => options('quoc-gia');

  Future<List<Movie>> filtered({
    required String type,
    String? language,
    String? category,
    String? country,
    int? year,
    String sortField = 'modified.time',
    String sortType = 'desc',
    int page = 1,
  }) => _fetch(
    Uri.parse('$_baseUrl/v1/api/danh-sach/$type').replace(
      queryParameters: {
        'page': '$page',
        'limit': '24',
        'sort_field': sortField,
        'sort_type': sortType,
        if (language != null) 'sort_lang': language,
        if (category != null) 'category': category,
        if (country != null) 'country': country,
        if (year != null) 'year': '$year',
      },
    ),
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
