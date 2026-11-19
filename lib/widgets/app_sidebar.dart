import 'package:flutter/cupertino.dart';
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
      (CupertinoIcons.house_fill, 'Trang chủ'),
      (CupertinoIcons.search, 'Tìm kiếm'),
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
            leading: Icon(CupertinoIcons.gear),
            title: Text('Cài đặt'),
          ),
        ],
      ),
    );
  }
}
