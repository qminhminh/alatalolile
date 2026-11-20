import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/movie_repository.dart';
import '../models/movie.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);
  final MovieRepository repository;
  MovieApiSource get source => repository.source;
  List<Movie> movies = const [];
  Map<String, List<Movie>> sections = const {};
  bool loading = false;
  String? error;
  String activeTitle = 'Phim mới cập nhật';
  String? activeSlug;
  int currentPage = 1;
  int totalPages = 152;
  List<Map<String, String>> categories = const [];
  List<Map<String, String>> countries = const [];
  String sortField = 'modified.time';
  String sortType = 'desc';
  String? language, category, country;
  String searchKeyword = '';
  bool hasActiveFilters = false;
  int? year;
  final List<Movie> favorites = [];

  Future<void> switchSource(MovieApiSource value) async {
    repository.setSource(value);
    await loadFavorites();
    await loadLatest();
  }

  String get _favoritesKey => 'favorite_movies_${repository.source.name}';

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getStringList(_favoritesKey) ??
        (repository.source == MovieApiSource.kkphim
            ? prefs.getStringList('favorite_movies') ?? const []
            : const []);
    favorites
      ..clear()
      ..addAll(
        raw.map(
          (item) => Movie.fromJson(jsonDecode(item) as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  Future<void> toggleFavorite(Movie movie) async {
    final index = favorites.indexWhere((item) => item.slug == movie.slug);
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(movie);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      favorites
          .map(
            (item) => jsonEncode({
              'slug': item.slug,
              'name': item.name,
              'origin_name': item.original,
              'poster_url': item.poster,
              'thumb_url': item.thumb,
              'year': item.year,
              'episode_current': item.episode,
              'quality': item.quality,
              'time': item.time,
              'category': item.categories,
            }),
          )
          .toList(),
    );
    notifyListeners();
  }

  bool isFavorite(String slug) => favorites.any((item) => item.slug == slug);

  Future<void> selectFavorites() async {
    await loadFavorites();
    activeTitle = 'Phim yêu thích';
    activeSlug = null;
    movies = List.unmodifiable(favorites);
    notifyListeners();
  }

  Future<void> loadLatest() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final options = await Future.wait([
        repository.categories(),
        repository.countries(),
      ]);
      categories = options[0];
      countries = options[1];
    } catch (_) {}
    try {
      final results = await Future.wait([
        repository.latest(),
        repository.category('phim-le'),
        repository.category('phim-bo'),
        repository.category('tv-shows'),
        repository.category('hoat-hinh'),
        repository.category('phim-vietsub'),
        repository.category('phim-thuyet-minh'),
        repository.category('phim-long-tieng'),
      ]);
      movies = results.first;
      activeTitle = 'Phim mới cập nhật';
      sections = {
        'Phim mới cập nhật': results[0],
        'Phim lẻ': results[1],
        'Phim bộ': results[2],
        'TV Shows': results[3],
        'Hoạt hình': results[4],
        'Việt sub': results[5],
        'Thuyết minh': results[6],
        'Lồng tiếng': results[7],
      };
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    required String type,
    String? newLanguage,
    String? newCategory,
    String? newCountry,
    int? newYear,
    String newSortField = 'modified.time',
    String newSortType = 'desc',
  }) async {
    // A new filter is a new result set, so always start from its first page.
    currentPage = 1;
    language = newLanguage;
    category = newCategory;
    country = newCountry;
    year = newYear;
    hasActiveFilters =
        newLanguage != null ||
        newCategory != null ||
        newCountry != null ||
        newYear != null;
    sortField = newSortField;
    sortType = newSortType;
    activeSlug = type;
    await _load(
      () =>
          type == 'phim-moi-cap-nhat-v3' &&
              repository.source == MovieApiSource.kkphim &&
              newLanguage == null &&
              newCategory == null &&
              newCountry == null &&
              newYear == null
          ? repository.latest()
          : repository.filtered(
              type:
                  repository.source == MovieApiSource.vsmov &&
                      type == 'phim-moi-cap-nhat-v3'
                  ? 'phim-moi-cap-nhat'
                  : type,
              language: language,
              category: category,
              country: country,
              year: year,
              sortField: sortField,
              sortType: sortType,
            ),
    );
  }

  Future<void> search(String keyword, {int page = 1}) {
    searchKeyword = keyword;
    activeTitle = 'Kết quả tìm kiếm: $keyword';
    activeSlug = 'search';
    currentPage = page;
    return _load(() => repository.search(keyword, page: page));
  }

  Future<void> loadCategory(String title, String slug) async {
    activeTitle = title;
    activeSlug = slug;
    currentPage = 1;
    await _load(() => repository.category(slug));
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages) return;
    currentPage = page;
    if (activeSlug == 'search') {
      await search(searchKeyword, page: page);
    } else if (hasActiveFilters && activeSlug != null) {
      await _load(
        () => repository.filtered(
          type: activeSlug!,
          language: language,
          category: category,
          country: country,
          year: year,
          sortField: sortField,
          sortType: sortType,
          page: page,
        ),
      );
    } else if (activeSlug != null) {
      await _load(() => repository.category(activeSlug!, page: page));
    }
  }

  Future<void> _load(Future<List<Movie>> Function() request) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      movies = await request();
      totalPages = repository.lastTotalPages;
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
