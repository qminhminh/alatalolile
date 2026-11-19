class Movie {
  const Movie({
    required this.slug,
    required this.name,
    required this.original,
    required this.poster,
    required this.thumb,
    required this.year,
    required this.episode,
    required this.quality,
    this.time = '',
    this.rating = 0,
    this.categories = const [],
  });
  final String slug, name, original, poster, thumb, episode, quality, time;
  final int year;
  final double rating;
  final List<String> categories;
  factory Movie.fromJson(Map<String, dynamic> json) {
    String image(Object? value) {
      final text = value?.toString() ?? '';
      return text.startsWith('http') ? text : 'https://phimimg.com/$text';
    }

    final raw = json['category'];
    final categories = raw is List
        ? raw
              .map((item) => item is Map ? '${item['name'] ?? ''}' : '$item')
              .where((item) => item.isNotEmpty)
              .toList()
        : const <String>[];
    final tmdb = json['tmdb'];
    final rating = tmdb is Map
        ? double.tryParse('${tmdb['vote_average'] ?? 0}') ?? 0.0
        : 0.0;
    return Movie(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không có tên',
      original: json['origin_name']?.toString() ?? '',
      poster: image(json['poster_url']),
      thumb: image(json['thumb_url']),
      year: int.tryParse('${json['year'] ?? ''}') ?? 0,
      episode: json['episode_current']?.toString() ?? '',
      quality: json['quality']?.toString() ?? 'HD',
      time: json['time']?.toString() ?? '',
      rating: rating,
      categories: categories,
    );
  }
}
