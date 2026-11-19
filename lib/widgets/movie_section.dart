import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'movie_card.dart';

class MovieSection extends StatelessWidget {
  const MovieSection({
    required this.title,
    required this.movies,
    required this.onMovieTap,
    super.key,
  });
  final String title;
  final List<Movie> movies;
  final ValueChanged<Movie> onMovieTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const Text('Xem tất cả', style: TextStyle(color: Color(0xFFFFC107))),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 410,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: movies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) =>
              MovieCard(movie: movies[i], onTap: () => onMovieTap(movies[i])),
        ),
      ),
    ],
  );
}
