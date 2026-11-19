import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class MovieFilter extends StatefulWidget {
  const MovieFilter({required this.type, super.key});
  final String type;
  @override
  State<MovieFilter> createState() => _MovieFilterState();
}

class _MovieFilterState extends State<MovieFilter> {
  String sort = 'modified.time-desc';
  String language = 'all';
  String category = 'all';
  String country = 'all';
  String year = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 8, 30, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.line_horizontal_3_decrease,
                color: Color(0xFFFFC107),
              ),
              SizedBox(width: 8),
              Text(
                'Bộ lọc phim',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _select('Sắp xếp', sort, {
                'modified.time-desc': 'Mới cập nhật',
                'year-desc': 'Năm mới nhất',
                'year-asc': 'Năm cũ nhất',
              }, (v) => setState(() => sort = v)),
              _select('Ngôn ngữ', language, {
                'all': 'Tất cả ngôn ngữ',
                'vietsub': 'Vietsub',
                'thuyet-minh': 'Thuyết minh',
                'long-tieng': 'Lồng tiếng',
              }, (v) => setState(() => language = v)),
              _select(
                'Thể loại',
                category,
                _options('Tất cả thể loại', state.categories),
                (v) => setState(() => category = v),
              ),
              _select(
                'Quốc gia',
                country,
                _options('Tất cả quốc gia', state.countries),
                (v) => setState(() => country = v),
              ),
              _select('Năm', year, {
                'all': 'Tất cả các năm',
                for (var y = DateTime.now().year; y >= 2000; y--) '$y': '$y',
              }, (v) => setState(() => year = v)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(CupertinoIcons.line_horizontal_3_decrease),
                label: const Text('Lọc phim'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => setState(() {
                  sort = 'modified.time-desc';
                  language = category = country = year = 'all';
                }),
                icon: const Icon(CupertinoIcons.xmark),
                label: const Text('Xóa bộ lọc'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, String> _options(String all, List<Map<String, String>> values) =>
      {'all': all, for (final item in values) item['slug']!: item['name']!};
  Widget _select(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String> onChanged,
  ) => SizedBox(
    width: 200,
    child: DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.entries
          .map(
            (item) => DropdownMenuItem(
              value: item.key,
              child: Text(item.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
  void _apply() {
    final parts = sort.split('-');
    context.read<AppState>().applyFilters(
      type: widget.type,
      newLanguage: language == 'all' ? null : language,
      newCategory: category == 'all' ? null : category,
      newCountry: country == 'all' ? null : country,
      newYear: year == 'all' ? null : int.tryParse(year),
      newSortField: parts.first,
      newSortType: parts.last,
    );
  }
}
