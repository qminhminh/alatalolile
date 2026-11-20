import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

enum MovieApiSource { kkphim, vsmov }

class MovieRepository {
  MovieRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  MovieApiSource source = MovieApiSource.kkphim;
  int lastTotalPages = 152;
  String get _baseUrl => switch (source) {
    MovieApiSource.kkphim => 'https://phimapi.com',
    MovieApiSource.vsmov => 'https://vsmov.com/api',
  };

  void setSource(MovieApiSource value) => source = value;
  Future<List<Movie>> latest() async {
    lastTotalPages = 1;
    final path = switch (source) {
      MovieApiSource.kkphim => 'danh-sach/phim-moi-cap-nhat-v3',
      MovieApiSource.vsmov => 'danh-sach/phim-moi-cap-nhat',
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
    _updatePagination(root);
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

  Future<List<Movie>> search(String keyword, {int page = 1}) async {
    try {
      return await _fetch(
        Uri.parse(
          source == MovieApiSource.kkphim
              ? '$_baseUrl/v1/api/tim-kiem'
              : '$_baseUrl/tim-kiem',
        ).replace(
          queryParameters: {
            'keyword': keyword,
            if (source == MovieApiSource.vsmov) 'limit': '20',
            'page': '$page',
          },
        ),
      );
    } on Exception catch (error) {
      if ('$error'.contains('429')) return const [];
      rethrow;
    }
  }

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
  }) {
    if (source == MovieApiSource.vsmov) {
      final vsmovType = type == 'phim-moi-cap-nhat-v3'
          ? 'phim-moi-cap-nhat'
          : type;
      final path = category != null
          ? '$_baseUrl/the-loai/$category'
          : country != null
          ? '$_baseUrl/quoc-gia/$country'
          : year != null
          ? '$_baseUrl/nam/$year'
          : '$_baseUrl/danh-sach/$vsmovType';
      return _fetch(
        Uri.parse(path).replace(
          queryParameters: {
            'page': '$page',
            'limit': '20',
            if (type == 'phim-bo') 'type': 'series',
            if (type == 'phim-le') 'type': 'movie',
            ...?language == null ? null : {'lang': language},
          },
        ),
      );
    }
    return _fetch(
      Uri.parse('$_baseUrl/v1/api/danh-sach/$type').replace(
        queryParameters: {
          'page': '$page',
          'limit': '24',
          'sort_field': sortField,
          'sort_type': sortType,
          ...?language == null ? null : {'sort_lang': language},
          ...?category == null ? null : {'category': category},
          ...?country == null ? null : {'country': country},
          ...?year == null ? null : {'year': '$year'},
        },
      ),
    );
  }

  Future<MovieDetail> detail(String slug) async {
    final path = '$_baseUrl/phim/$slug';
    final response = await _client.get(
      Uri.parse(path),
      headers: const {'accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể tải chi tiết phim');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final pagination = root['pagination'];
    if (pagination is Map) {
      lastTotalPages =
          int.tryParse(
            '${pagination['totalPages'] ?? pagination['total_page'] ?? 152}',
          ) ??
          152;
    }
    final item = Map<String, dynamic>.from(root['movie'] as Map);
    final base = Movie.fromJson(item);
    final movieEpisodes = item['episodes'];
    final raw = root['episodes'] is List
        ? root['episodes'] as List
        : movieEpisodes is List
        ? movieEpisodes
        : const [];
    final servers = raw
        .whereType<Map<String, dynamic>>()
        .map((server) {
          if (server['server_data'] is List) return server;
          final items = server['items'];
          if (items is! List) return server;
          return {
            ...server,
            'server_data': items.whereType<Map>().map((item) {
              return {
                ...Map<String, dynamic>.from(item),
                'link_embed': item['link_embed'] ?? item['embed'],
                'link_m3u8': item['link_m3u8'] ?? item['m3u8'],
              };
            }).toList(),
          };
        })
        .map(EpisodeServer.fromJson)
        .toList();
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
      servers: servers,
    );
  }

  Future<List<Movie>> _fetch(Uri uri) async {
    lastTotalPages = 1;
    final response = await _client.get(
      uri,
      headers: const {'accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API request failed: ${response.statusCode}');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    _updatePagination(root);
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

  void _updatePagination(Map<String, dynamic> root) {
    final data = root['data'];
    final raw =
        root['pagination'] ??
        (data is Map
            ? data['pagination'] ??
                  (data['params'] is Map
                      ? (data['params'] as Map)['pagination']
                      : null)
            : null);
    if (raw is! Map) return;
    final value =
        raw['totalPages'] ??
        raw['total_pages'] ??
        raw['total_page'] ??
        raw['lastPage'] ??
        raw['last_page'];
    final parsed = int.tryParse('$value');
    if (parsed != null && parsed > 0) lastTotalPages = parsed;
  }
}
