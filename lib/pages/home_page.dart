import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../state/app_state.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/movie_section.dart';
import '../widgets/movie_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final search = TextEditingController();
  Movie? detail;
  int selected = 0;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void submit() {
    final value = search.text.trim();
    setState(() => selected = value.isEmpty ? 0 : 1);
    final state = context.read<AppState>();
    value.isEmpty ? state.loadLatest() : state.search(value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        AppSidebar(selected: selected, onSelected: _selectSection),
        Expanded(
          child: Column(
            children: [
              _TopBar(controller: search, onSubmit: submit),
              Expanded(
                child: detail == null
                    ? _Results(
                        showAll: selected == 0,
                        onTap: (movie) => setState(() => detail = movie),
                      )
                    : _Details(
                        movie: detail!,
                        onBack: () => setState(() => detail = null),
                      ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _selectSection(int index) {
    setState(() => selected = index);
    const sections = <(String, String)>[
      ('Trang chủ', ''),
      ('Tìm kiếm', ''),
      ('Phim mới', ''),
      ('Phim lẻ', 'phim-le'),
      ('Phim bộ', 'phim-bo'),
      ('TV Shows', 'tv-shows'),
      ('Hoạt hình', 'hoat-hinh'),
      ('Việt sub', 'phim-vietsub'),
      ('Thuyết minh', 'phim-thuyet-minh'),
      ('Lồng tiếng', 'phim-long-tieng'),
    ];
    final (title, slug) = sections[index];
    final state = context.read<AppState>();
    if (slug.isEmpty) {
      state.loadLatest();
    } else {
      state.loadCategory(title, slug);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.all(20),
    child: TextField(
      controller: controller,
      onSubmitted: (_) => onSubmit(),
      decoration: const InputDecoration(
        hintText: 'Tìm kiếm phim...',
        prefixIcon: Icon(Icons.search),
      ),
    ),
  );
}

class _Results extends StatelessWidget {
  const _Results({required this.showAll, required this.onTap});
  final bool showAll;
  final ValueChanged<Movie> onTap;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text(state.error!));
    }
    if (state.movies.isEmpty) {
      return const Center(child: Text('Không tìm thấy phim'));
    }
    if (showAll) {
      return ListView(
        padding: const EdgeInsets.all(30),
        children: state.sections.entries
            .where((entry) => entry.value.isNotEmpty)
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: MovieSection(
                  title: entry.key,
                  movies: entry.value,
                  onMovieTap: onTap,
                ),
              ),
            )
            .toList(),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 14),
          sliver: SliverToBoxAdapter(
            child: Text(
              state.activeTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 36),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, index) => MovieCard(
                movie: state.movies[index],
                onTap: () => onTap(state.movies[index]),
              ),
              childCount: state.movies.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisExtent: 278,
              crossAxisSpacing: 18,
              mainAxisSpacing: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.movie, required this.onBack});
  final Movie movie;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.all(30),
    children: [
      TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
        label: const Text('Quay lại'),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 230,
            height: 330,
            child: Image.network(movie.poster, fit: BoxFit.cover),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.name,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(movie.original),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Phát phim'),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}
