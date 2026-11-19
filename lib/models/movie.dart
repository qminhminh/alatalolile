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
  });
  final String slug, name, original, poster, thumb, episode, quality;
  final int year;
  factory Movie.fromJson(Map<String, dynamic> json) {
    String image(Object? value) {
      final text = value?.toString() ?? '';
      return text.startsWith('http') ? text : 'https://phimimg.com/$text';
    }

    return Movie(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không có tên',
      original: json['origin_name']?.toString() ?? '',
      poster: image(json['poster_url']),
      thumb: image(json['thumb_url']),
      year: int.tryParse('${json['year'] ?? ''}') ?? 0,
      episode: json['episode_current']?.toString() ?? '',
      quality: json['quality']?.toString() ?? 'HD',
    );
  }
}
