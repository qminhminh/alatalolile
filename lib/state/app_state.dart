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

  Future<void> loadLatest() async {
    loading = true;
    error = null;
    notifyListeners();
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

  Future<void> search(String keyword) =>
      _load(() => repository.search(keyword));

  Future<void> loadCategory(String title, String slug) async {
    activeTitle = title;
    await _load(() => repository.category(slug));
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
