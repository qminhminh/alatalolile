import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../state/app_state.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/movie_section.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_filter.dart';
import '../widgets/skeleton.dart';
import '../data/movie_repository.dart';
import 'watch_page.dart';

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onMenu, this.onBack});
  final VoidCallback onMenu;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: const Color(0xFF121214),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack ?? onMenu,
          icon: Icon(
            onBack == null
                ? CupertinoIcons.line_horizontal_3
                : CupertinoIcons.chevron_left,
          ),
        ),
        const Text(
          'ALATALOLILE',
          style: TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final search = TextEditingController();
  Timer? searchDebounce;
  int searchGeneration = 0;
  Movie? detail;
  List<Movie> suggestions = const [];
  int selected = 0;
  bool showFilter = false;
  @override
  void dispose() {
    search.dispose();
    searchDebounce?.cancel();
    super.dispose();
  }

  void submit() {
    searchGeneration++;
    searchDebounce?.cancel();
    final value = search.text.trim();
    setState(() => selected = value.isEmpty ? 0 : 1);
    final state = context.read<AppState>();
    setState(() => suggestions = const []);
    value.isEmpty ? state.loadLatest() : state.search(value);
  }

  Future<void> updateSuggestions(String value) async {
    final generation = ++searchGeneration;
    searchDebounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => suggestions = const []);
      return;
    }
    searchDebounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await context.read<AppState>().repository.search(
        value.trim(),
      );
      if (!mounted ||
          generation != searchGeneration ||
          search.text.trim() != value.trim()) {
        return;
      }
      setState(() => suggestions = results.take(6).toList());
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 700 &&
              defaultTargetPlatform != TargetPlatform.macOS;
          return Row(
            children: [
              if (!compact)
                AppSidebar(
                  selected: selected,
                  onSelected: _selectSection,
                  source: context.watch<AppState>().source,
                  onSourceSelected: (source) {
                    setState(() {
                      detail = null;
                      selected = 0;
                      showFilter = false;
                    });
                    context.read<AppState>().switchSource(source);
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    if (compact)
                      _MobileHeader(
                        onBack: detail == null
                            ? null
                            : () => setState(() => detail = null),
                        onMenu: () => showDialog<void>(
                          context: context,
                          builder: (_) => Dialog(
                            alignment: Alignment.centerLeft,
                            insetPadding: EdgeInsets.zero,
                            child: SizedBox(
                              width: 250,
                              height: constraints.maxHeight,
                              child: AppSidebar(
                                selected: selected,
                                onSelected: (index) {
                                  Navigator.pop(context);
                                  _selectSection(index);
                                },
                                source: context.read<AppState>().source,
                                onSourceSelected: (source) {
                                  Navigator.pop(context);
                                  setState(() {
                                    detail = null;
                                    selected = 0;
                                    showFilter = false;
                                  });
                                  context.read<AppState>().switchSource(source);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (detail == null && selected != 10) ...[
                      _TopBar(
                        controller: search,
                        onSubmit: submit,
                        onChanged: updateSuggestions,
                        onFilter: () {
                          setState(() {
                            if (selected == 0) selected = 1;
                            showFilter = true;
                          });
                          showDialog<void>(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 980,
                                ),
                                child: MovieFilter(
                                  type: _typeForIndex(selected),
                                  onApplied: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (suggestions.isNotEmpty)
                        _Suggestions(
                          movies: suggestions,
                          onTap: (movie) => setState(() {
                            detail = movie;
                            suggestions = const [];
                          }),
                        ),
                    ],
                    Expanded(
                      child: detail == null
                          ? Column(
                              children: [
                                Expanded(
                                  child: _Results(
                                    showAll: selected == 0,
                                    favoritesOnly: selected == 10,
                                    onTap: (movie) =>
                                        setState(() => detail = movie),
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
          );
        },
      ),
    ),
  );

  void _selectSection(int index) {
    final state = context.read<AppState>();
    setState(() {
      selected = index;
      detail = null;
      showFilter = index >= 1 && index != 10;
    });
    if (index == 10) {
      state.selectFavorites();
      return;
    }
    if (index > 10) return;
    const sections = <(String, String)>[
      ('Trang chủ', ''),
      ('Phim mới', 'phim-moi-cap-nhat-v3'),
      ('Phim lẻ', 'phim-le'),
      ('Phim bộ', 'phim-bo'),
      ('TV Shows', 'tv-shows'),
      ('Hoạt hình', 'hoat-hinh'),
      ('Việt sub', 'phim-vietsub'),
      ('Thuyết minh', 'phim-thuyet-minh'),
      ('Lồng tiếng', 'phim-long-tieng'),
    ];
    final (title, slug) = sections[index];
    if (slug.isEmpty) {
      state.loadLatest();
    } else if (slug == 'phim-moi-cap-nhat-v3') {
      state.applyFilters(type: slug);
    } else {
      state.loadCategory(title, slug);
    }
  }

  String _typeForIndex(int index) {
    const types = [
      '',
      'phim-moi-cap-nhat-v3',
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
  const _TopBar({
    required this.controller,
    required this.onSubmit,
    required this.onChanged,
    required this.onFilter,
  });
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit(),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm phim...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(
                CupertinoIcons.search,
                color: Colors.white70,
              ),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onSubmit();
                      },
                      icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    ),
              filled: true,
              fillColor: const Color(0xFF1B1B1E),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFFFC107),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Bộ lọc phim',
          onPressed: onFilter,
          icon: const Icon(CupertinoIcons.slider_horizontal_3),
          color: const Color(0xFFFFC107),
        ),
      ],
    ),
  );
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.movies, required this.onTap});
  final List<Movie> movies;
  final ValueChanged<Movie> onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
    decoration: BoxDecoration(
      color: const Color(0xFF202023),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: movies
          .map(
            (movie) => Material(
              color: const Color(0xFF202023),
              child: ListTile(
                onTap: () => onTap(movie),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: SizedBox(
                  width: 52,
                  height: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: movie.poster.isEmpty
                        ? Image.asset('assets/images/logo.png')
                        : Image.network(movie.poster, fit: BoxFit.cover),
                  ),
                ),
                title: Text(
                  movie.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${movie.year} • ${movie.original}'),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _Results extends StatelessWidget {
  const _Results({
    required this.showAll,
    required this.favoritesOnly,
    required this.onTap,
  });
  final bool showAll;
  final bool favoritesOnly;
  final ValueChanged<Movie> onTap;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (favoritesOnly) {
      return ListView(
        padding: const EdgeInsets.all(30),
        children: [
          MovieSection(
            title: 'Phim yêu thích',
            movies: state.favorites,
            onMovieTap: onTap,
          ),
        ],
      );
    }
    if (state.loading) {
      return const MovieSkeletonGrid();
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
                  onViewAll: () => context
                      .findAncestorStateOfType<_HomePageState>()
                      ?._selectSection(_sectionIndex(entry.key)),
                ),
              ),
            )
            .toList(),
      );
    }
    return CustomScrollView(
      slivers: [
        if (favoritesOnly)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 0),
              child: _FavoriteSourceTabs(
                selected: state.source,
                onSelected: (source) async {
                  await state.switchSource(source);
                  await state.selectFavorites();
                },
              ),
            ),
          ),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
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

  int _sectionIndex(String title) {
    const titles = [
      'Phim mới cập nhật',
      'Phim lẻ',
      'Phim bộ',
      'TV Shows',
      'Hoạt hình',
      'Việt sub',
      'Thuyết minh',
      'Lồng tiếng',
    ];
    final index = titles.indexOf(title);
    return index < 0 ? 0 : index + 1;
  }
}

class _FavoriteSourceTabs extends StatelessWidget {
  const _FavoriteSourceTabs({required this.selected, required this.onSelected});
  final MovieApiSource selected;
  final ValueChanged<MovieApiSource> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: MovieApiSource.values.map((source) {
      final active = source == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ChoiceChip(
          label: Text(source == MovieApiSource.kkphim ? 'Nguồn 1' : 'Nguồn 2'),
          selected: active,
          onSelected: (_) => onSelected(source),
        ),
      );
    }).toList(),
  );
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
      final compact = MediaQuery.sizeOf(context).width < 700;
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
          if (!compact)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(CupertinoIcons.chevron_left, size: 24),
                label: const Text(
                  'Quay lại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFC107),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Flex(
            direction: MediaQuery.sizeOf(context).width < 700
                ? Axis.vertical
                : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: compact ? Alignment.center : Alignment.centerLeft,
                child: SizedBox(
                  width: compact ? 210 : 230,
                  height: compact ? 300 : 330,
                  child: Image.network(movie.poster, fit: BoxFit.cover),
                ),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 700 ? 0 : 24,
                height: MediaQuery.sizeOf(context).width < 700 ? 20 : 0,
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 700
                    ? MediaQuery.sizeOf(context).width - 60
                    : MediaQuery.sizeOf(context).width - 320,
                child: Column(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.name,
                      textAlign: compact ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie.original,
                      textAlign: compact ? TextAlign.center : TextAlign.start,
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 16,
                      children: [
                        Consumer<AppState>(
                          builder: (context, state, _) => OutlinedButton.icon(
                            onPressed: () => state.toggleFavorite(movie),
                            icon: Icon(
                              state.isFavorite(movie.slug)
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: const Color(0xFFFFC107),
                            ),
                            label: Text(
                              state.isFavorite(movie.slug)
                                  ? 'Đã yêu thích'
                                  : 'Yêu thích',
                            ),
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
                                      servers: detail.servers,
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
                      textAlign: compact ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: compact
                          ? WrapAlignment.center
                          : WrapAlignment.start,
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
                                builder: (_) => WatchPage(
                                  movie: detail,
                                  episode: episode,
                                  servers: detail.servers,
                                ),
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
          const SizedBox(height: 24),
          FutureBuilder<List<Movie>>(
            future: repository.latest(),
            builder: (context, similarSnapshot) {
              final similar = similarSnapshot.data ?? const <Movie>[];
              if (similar.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phim đề xuất cho bạn',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: similar.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 190,
                          mainAxisExtent: 410,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 24,
                        ),
                    itemBuilder: (_, index) => MovieCard(
                      movie: similar[index],
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _Details(
                            movie: similar[index],
                            repository: repository,
                            onBack: onBack,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    },
  );
}
