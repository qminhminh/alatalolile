import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

enum MovieApiSource { kkphim, nguonc, vsmov, tophim }

class MovieRepository {
  MovieRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  MovieApiSource source = MovieApiSource.kkphim;
  String get _baseUrl => switch (source) {
    MovieApiSource.kkphim => 'https://phimapi.com',
    MovieApiSource.nguonc => 'https://phim.nguonc.com/api',
    MovieApiSource.vsmov => 'https://vsmov.com/api',
    MovieApiSource.tophim => 'https://tophim.top',
  };

  void setSource(MovieApiSource value) => source = value;
  Future<List<Movie>> latest() async {
    final path = switch (source) {
      MovieApiSource.kkphim => 'danh-sach/phim-moi-cap-nhat-v3',
      MovieApiSource.vsmov => 'danh-sach/phim-moi-cap-nhat',
      MovieApiSource.nguonc => 'films/phim-moi-cap-nhat',
      MovieApiSource.tophim => 'danh-sach/phim-moi-cap-nhat',
    };
    final response = await _client.get(
      Uri.parse('$_baseUrl/$path')
          .replace(queryParameters: {'page': '1', 'limit': '24'}),
      headers: const {'accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể tải phim mới');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final items = root['items'];
    return items is List
        ? items
              .whereType<Map>()
              .map(
                (item) => Movie.fromJson(
                  _normalizeVsmovItem(Map<String, dynamic>.from(item)),
                ),
              )
              .toList()
        : const [];
  }

  Future<List<Movie>> category(String slug, {int page = 1}) {
    if (source == MovieApiSource.vsmov &&
        !{'phim-le', 'phim-bo'}.contains(slug)) {
      return Future.value(const []);
    }
    return _fetch(
      Uri.parse(
        source == MovieApiSource.kkphim
            ? '$_baseUrl/v1/api/danh-sach/$slug'
            : '$_baseUrl/danh-sach/$slug',
      ).replace(queryParameters: {'limit': '24', 'page': '$page'}),
    );
  }

  Future<List<Movie>> search(String keyword) => _fetch(
    Uri.parse(
      source == MovieApiSource.kkphim
          ? '$_baseUrl/v1/api/tim-kiem'
          : '$_baseUrl/tim-kiem',
    ).replace(
      queryParameters: {
        'keyword': keyword,
        if (source == MovieApiSource.vsmov) 'limit': '20',
        if (source == MovieApiSource.vsmov) 'page': '1',
      },
    ),
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
    Uri.parse(
      source == MovieApiSource.kkphim
          ? '$_baseUrl/v1/api/danh-sach/$type'
          : '$_baseUrl/danh-sach/$type',
    ).replace(
      queryParameters: {
        'page': '$page',
        'limit': '24',
        'sort_field': sortField,
        'sort_type': sortType,
        ...?language == null ? null : {'sort_lang': language},
        ...?category == null ? null : {'category': category},
        ...?country == null ? null : {'country': country},
        if (year != null) 'year': '$year',
      },
    ),
  );

  Future<MovieDetail> detail(String slug) async {
    final response = await _client.get(Uri.parse('$_baseUrl/phim/$slug'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể tải chi tiết phim');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final item = Map<String, dynamic>.from(root['movie'] as Map);
    final base = Movie.fromJson(item);
    final raw = root['episodes'] is List ? root['episodes'] as List : const [];
    return MovieDetail(
      slug: base.slug,
      name: base.name,
      original: base.original,
      poster: base.poster,
      thumb: base.thumb,
      year: base.year,
      episode: base.episode,
      quality: base.quality,
      time: base.time,
      rating: base.rating,
      categories: base.categories,
      countries: base.countries,
      directors: base.directors,
      actors: base.actors,
      language: base.language,
      content: base.content,
      servers: raw
          .whereType<Map<String, dynamic>>()
          .map(EpisodeServer.fromJson)
          .toList(),
    );
  }

  Future<List<Movie>> _fetch(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API request failed: ${response.statusCode}');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = root['data'];
    final items =
        root['items'] ?? (data is Map<String, dynamic> ? data['items'] : data);
    return items is List
        ? items
              .whereType<Map>()
              .map(
                (item) => Movie.fromJson(
                  _normalizeVsmovItem(Map<String, dynamic>.from(item)),
                ),
              )
              .toList()
        : const [];
  }

  Map<String, dynamic> _normalizeVsmovItem(Map<String, dynamic> item) {
    if (source != MovieApiSource.vsmov) return item;
    return {
      ...item,
      'poster_url': item['poster_url'] ?? item['poster'] ?? item['image'],
      'thumb_url': item['thumb_url'] ?? item['thumb'] ?? item['poster_url'],
      'origin_name': item['origin_name'] ?? item['original_name'],
      'episode_current': item['episode_current'] ?? item['episode'],
    };
  }
}
