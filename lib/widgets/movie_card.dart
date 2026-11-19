import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({required this.movie, required this.onTap, super.key});
  final Movie movie;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 410,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF18181A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 230, child: _Poster(movie: movie)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: _Info(movie: movie),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.movie});
  final Movie movie;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Image.network(
          movie.poster,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.white10),
        ),
      ),
      const Positioned(
        top: 8,
        left: 8,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.black87,
          child: Icon(CupertinoIcons.heart, size: 17),
        ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              movie.quality.isEmpty ? 'FHD' : movie.quality,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.movie});
  final Movie movie;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        movie.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 3),
      Text(
        movie.original,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Text(
            '${movie.year}',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const Text('  •  ', style: TextStyle(color: Colors.white38)),
          Flexible(
            child: Text(
              movie.time.isEmpty ? movie.episode : movie.time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          if (movie.rating > 0) ...[
            const Spacer(),
            const Icon(
              CupertinoIcons.star_fill,
              color: Color(0xFFFFC107),
              size: 12,
            ),
            const SizedBox(width: 3),
            Text(
              movie.rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      if (movie.episode.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            movie.episode,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      if (movie.categories.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Wrap(
            spacing: 4,
            children: movie.categories
                .take(2)
                .map(
                  (category) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
    ],
  );
}
