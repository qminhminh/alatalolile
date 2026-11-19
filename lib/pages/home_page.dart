import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../state/app_state.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/movie_section.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_filter.dart';
import '../data/movie_repository.dart';
import 'watch_page.dart';

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
                    ? Column(
                        children: [
                          if (selected >= 3)
                            MovieFilter(type: _typeForIndex(selected)),
                          Expanded(
                            child: _Results(
                              showAll: selected == 0,
                              onTap: (movie) => setState(() => detail = movie),
                            ),
                          ),
                        ],
                      )
                    : _Details(
                        movie: detail!,
                        repository: context.read<AppState>().repository,
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

  String _typeForIndex(int index) {
    const types = [
      '',
      '',
      '',
      'phim-le',
      'phim-bo',
      'tv-shows',
      'hoat-hinh',
      'phim-vietsub',
      'phim-thuyet-minh',
      'phim-long-tieng',
    ];
    return types[index];
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
        prefixIcon: Icon(CupertinoIcons.search),
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
              maxCrossAxisExtent: 165,
              mainAxisExtent: 410,
              crossAxisSpacing: 18,
              mainAxisSpacing: 24,
            ),
          ),
        ),
        if (!showAll && state.activeSlug != null)
          SliverToBoxAdapter(
            child: _Pagination(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              onPageChanged: context.read<AppState>().goToPage,
            ),
          ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  @override
  Widget build(BuildContext context) {
    final pages = <int>{1, 2, totalPages - 1, totalPages};
    if (currentPage <= 3) {
      pages.add(3);
    } else if (currentPage >= totalPages - 2) {
      pages.add(totalPages - 2);
    } else {
      pages.addAll([currentPage - 1, currentPage, currentPage + 1]);
    }
    final orderedPages = pages.where((p) => p >= 1 && p <= totalPages).toList()
      ..sort();
    final children = <Widget>[
      _button(
        '‹  Trước',
        currentPage > 1,
        () => onPageChanged(currentPage - 1),
      ),
    ];
    for (var i = 0; i < orderedPages.length; i++) {
      if (i > 0 && orderedPages[i] - orderedPages[i - 1] > 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('…'),
          ),
        );
      }
      final page = orderedPages[i];
      children.add(
        _button(
          '$page',
          true,
          () => onPageChanged(page),
          active: page == currentPage,
        ),
      );
    }
    children.add(
      _button(
        'Tiếp  ›',
        currentPage < totalPages,
        () => onPageChanged(currentPage + 1),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _button(
    String label,
    bool enabled,
    VoidCallback onPressed, {
    bool active = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: active
            ? const Color(0xFFFFC107)
            : const Color(0xFF242426),
        foregroundColor: active ? Colors.black : Colors.white70,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      child: Text(label),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.movie,
    required this.repository,
    required this.onBack,
  });
  final Movie movie;
  final MovieRepository repository;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext c) => FutureBuilder<MovieDetail>(
    future: repository.detail(movie.slug),
    builder: (context, snapshot) {
      final detail = snapshot.data;
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (detail == null) {
        return const Center(child: Text('Không thể tải chi tiết phim'));
      }
      return ListView(
        padding: const EdgeInsets.all(30),
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(CupertinoIcons.back),
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
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 16,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            CupertinoIcons.heart,
                            color: Color(0xFFFFC107),
                          ),
                          label: const Text('Yêu thích'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFC107),
                            side: const BorderSide(color: Color(0xFFFFC107)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              detail.servers.isEmpty ||
                                  detail.servers.first.episodes.isEmpty
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WatchPage(
                                      movie: detail,
                                      episode:
                                          detail.servers.first.episodes.first,
                                    ),
                                  ),
                                ),
                          icon: const Icon(CupertinoIcons.play_circle),
                          label: const Text('Xem Ngay'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      detail.content,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: [
                        Text('Năm: ${detail.year}'),
                        Text('Thời lượng: ${detail.time}'),
                        Text('Tình trạng: ${detail.episode}'),
                        Text(
                          'Chất lượng: ${detail.quality} - ${detail.language}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Quốc gia: ${detail.countries.join(', ')}'),
                    const SizedBox(height: 8),
                    Text('Thể loại: ${detail.categories.join(', ')}'),
                    const SizedBox(height: 8),
                    Text('Đạo diễn: ${detail.directors.join(', ')}'),
                    const SizedBox(height: 8),
                    Text(
                      'Diễn viên: ${detail.actors.join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Danh sách tập',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...detail.servers.map(
            (server) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: const TextStyle(
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: server.episodes
                        .map(
                          (episode) => OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WatchPage(movie: detail, episode: episode),
                              ),
                            ),
                            child: Text(episode.name),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
