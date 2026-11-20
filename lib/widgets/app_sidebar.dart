import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/movie_repository.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.selected,
    required this.onSelected,
    required this.source,
    required this.onSourceSelected,
    super.key,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  final MovieApiSource source;
  final ValueChanged<MovieApiSource> onSourceSelected;
  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (CupertinoIcons.house_fill, 'Trang chủ'),
      (CupertinoIcons.star_fill, 'Phim mới'),
      (CupertinoIcons.film, 'Phim lẻ'),
      (CupertinoIcons.tv, 'Phim bộ'),
      (CupertinoIcons.tv_fill, 'TV Shows'),
      (CupertinoIcons.circle_grid_hex, 'Hoạt hình'),
      (CupertinoIcons.textformat_abc, 'Việt sub'),
      (CupertinoIcons.person_2_fill, 'Thuyết minh'),
      (CupertinoIcons.mic_fill, 'Lồng tiếng'),
    ];
    return Container(
      width: 220,
      color: const Color(0xFF121214),
      padding: const EdgeInsets.fromLTRB(18, 30, 14, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 14, bottom: 42),
              child: Text(
                'ALATALOLILE',
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (source == MovieApiSource.kkphim) ...[
              const Padding(
                padding: EdgeInsets.only(left: 14, bottom: 12),
                child: Text(
                  'KHÁM PHÁ',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              ...List.generate(
                items.length,
                (i) => Material(
                  color: const Color(0xFF121214),
                  child: ListTile(
                    onTap: () => onSelected(i),
                    selected: selected == i,
                    selectedTileColor: const Color(0x33FFC107),
                    leading: Icon(items[i].$1),
                    title: Text(items[i].$2),
                  ),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.only(left: 14, top: 18, bottom: 8),
              child: Text(
                'NGUỒN PHIM',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
            ...MovieApiSource.values.map(
              (item) => Material(
                color: const Color(0xFF121214),
                child: ListTile(
                  dense: true,
                  onTap: () => onSourceSelected(item),
                  selected: source == item,
                  selectedTileColor: const Color(0x33FFC107),
                  leading: const Icon(CupertinoIcons.cloud),
                  title: Text(_sourceName(item)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            Material(
              color: const Color(0xFF121214),
              child: ListTile(
                onTap: () => onSelected(10),
                selected: selected == 10,
                leading: Icon(CupertinoIcons.heart_fill),
                title: const Text('Yêu thích'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceName(MovieApiSource source) => switch (source) {
    MovieApiSource.kkphim => 'Nguồn 1',
    MovieApiSource.vsmov => 'Nguồn 2',
  };
}
