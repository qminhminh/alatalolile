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
    this.countries = const [],
    this.directors = const [],
    this.actors = const [],
    this.language = '',
    this.content = '',
  });
  final String slug, name, original, poster, thumb, episode, quality, time;
  final int year;
  final double rating;
  final List<String> categories;
  final List<String> countries, directors, actors;
  final String language, content;
  factory Movie.fromJson(Map<String, dynamic> json) {
    String image(Object? value) {
      if (value is Map || value == null) return '';
      final text = value.toString();
      if (text.isEmpty || text == '{}') return '';
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
    List<String> names(Object? value) => value is List
        ? value
              .map((item) => item is Map ? '${item['name'] ?? ''}' : '$item')
              .where((item) => item.isNotEmpty)
              .toList()
        : const [];
    final cleanContent = (json['content']?.toString() ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
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
      countries: names(json['country']),
      directors: names(json['director']),
      actors: names(json['actor']),
      language: json['lang']?.toString() ?? '',
      content: cleanContent,
    );
  }
}

class Episode {
  const Episode({
    required this.name,
    required this.slug,
    required this.m3u8,
    required this.embed,
  });
  final String name, slug, m3u8, embed;
  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    name: '${json['name'] ?? ''}',
    slug: '${json['slug'] ?? ''}',
    m3u8: '${json['link_m3u8'] ?? ''}',
    embed: '${json['link_embed'] ?? ''}',
  );
}

class EpisodeServer {
  const EpisodeServer({required this.name, required this.episodes});
  final String name;
  final List<Episode> episodes;
  factory EpisodeServer.fromJson(Map<String, dynamic> json) => EpisodeServer(
    name: '${json['server_name'] ?? ''}',
    episodes:
        (json['server_data'] is List ? json['server_data'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(Episode.fromJson)
            .toList(),
  );
}

class MovieDetail extends Movie {
  const MovieDetail({
    required super.slug,
    required super.name,
    required super.original,
    required super.poster,
    required super.thumb,
    required super.year,
    required super.episode,
    required super.quality,
    super.time,
    super.rating,
    super.categories,
    super.countries,
    super.directors,
    super.actors,
    super.language,
    super.content,
    required this.servers,
  });
  final List<EpisodeServer> servers;
}
