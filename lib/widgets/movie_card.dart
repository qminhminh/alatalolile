import 'package:flutter/material.dart';

import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({required this.movie, required this.onTap, super.key});
  final Movie movie;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 155,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                movie.poster,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Colors.white10),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(movie.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(
            '${movie.year} • ${movie.episode}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
