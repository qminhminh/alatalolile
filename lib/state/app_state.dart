import 'package:flutter/foundation.dart';

import '../data/movie_repository.dart';
import '../models/movie.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);
  final MovieRepository repository;
  List<Movie> movies = const [];
  bool loading = false;
  String? error;

  Future<void> loadLatest() => _load(repository.latest);
  Future<void> search(String keyword) =>
      _load(() => repository.search(keyword));

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
