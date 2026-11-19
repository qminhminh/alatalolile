import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.search_rounded, 'Tìm kiếm'),
      (Icons.new_releases_rounded, 'Phim mới'),
      (Icons.movie_filter_rounded, 'Phim lẻ'),
      (Icons.live_tv_rounded, 'Phim bộ'),
      (Icons.tv_rounded, 'TV Shows'),
      (Icons.animation_rounded, 'Hoạt hình'),
      (Icons.translate_rounded, 'Việt sub'),
      (Icons.record_voice_over_rounded, 'Thuyết minh'),
      (Icons.mic_rounded, 'Lồng tiếng'),
    ];
    return Container(
      width: 220,
      color: const Color(0xFF121214),
      padding: const EdgeInsets.fromLTRB(18, 30, 14, 20),
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
          const Padding(
            padding: EdgeInsets.only(left: 14, bottom: 12),
            child: Text(
              'KHÁM PHÁ',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          ...List.generate(
            items.length,
            (i) => ListTile(
              onTap: () => onSelected(i),
              selected: selected == i,
              selectedTileColor: const Color(0x33FFC107),
              leading: Icon(items[i].$1),
              title: Text(items[i].$2),
            ),
          ),
          const Spacer(),
          const Divider(color: Colors.white12),
          const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Cài đặt'),
          ),
        ],
      ),
    );
  }
}
