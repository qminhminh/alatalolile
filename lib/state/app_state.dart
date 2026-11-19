import 'package:flutter/foundation.dart';

import '../data/movie_repository.dart';
import '../models/movie.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);
  final MovieRepository repository;
  List<Movie> movies = const [];
  Map<String, List<Movie>> sections = const {};
  bool loading = false;
  String? error;
  String activeTitle = 'Phim mới cập nhật';
  String? activeSlug;
  int currentPage = 1;
  final int totalPages = 152;
  List<Map<String, String>> categories = const [];
  List<Map<String, String>> countries = const [];
  String sortField = 'modified.time';
  String sortType = 'desc';
  String? language, category, country;
  int? year;

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
    language = newLanguage;
    category = newCategory;
    country = newCountry;
    year = newYear;
    sortField = newSortField;
    sortType = newSortType;
    activeSlug = type;
    await _load(
      () => type == 'phim-moi-cap-nhat-v3'
          ? repository.latest()
          : repository.filtered(
              type: type,
              language: language,
              category: category,
              country: country,
              year: year,
              sortField: sortField,
              sortType: sortType,
            ),
    );
  }

  Future<void> search(String keyword) =>
      _load(() => repository.search(keyword));

  Future<void> loadCategory(String title, String slug) async {
    activeTitle = title;
    activeSlug = slug;
    currentPage = 1;
    await _load(() => repository.category(slug));
  }

  Future<void> goToPage(int page) async {
    if (activeSlug == null || page < 1 || page > totalPages) return;
    currentPage = page;
    await _load(() => repository.category(activeSlug!, page: page));
  }

  Future<void> _load(Future<List<Movie>> Function() request) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      movies = await request();
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
