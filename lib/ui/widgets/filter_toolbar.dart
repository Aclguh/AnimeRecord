import 'package:flutter/material.dart';
import '../../models/app_constants.dart';

/// 顶部工具栏（状态筛选 Tab、搜索框、排序下拉、添加番剧按钮）
class FilterToolbar extends StatefulWidget {
  final String activeStatus;
  final Map<String, int> statusCounts;
  final String searchQuery;
  final String sortBy;
  final ValueChanged<String> onSelectStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onAddAnime;

  const FilterToolbar({
    super.key,
    required this.activeStatus,
    required this.statusCounts,
    required this.searchQuery,
    required this.sortBy,
    required this.onSelectStatus,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onAddAnime,
  });

  @override
  State<FilterToolbar> createState() => _FilterToolbarState();
}

class _FilterToolbarState extends State<FilterToolbar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant FilterToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterItems = [
      ('all', '全部'),
      (AnimeStatus.wantToWatch, '想看'),
      (AnimeStatus.watching, '在看'),
      (AnimeStatus.watched, '看过'),
      (AnimeStatus.onHold, '搁置'),
      (AnimeStatus.dropped, '抛弃'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final statusTabs = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171A22) : const Color(0xFFEFEFF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: filterItems.map((item) {
                final status = item.$1;
                final label = item.$2;
                final isSelected = widget.activeStatus == status;
                final count = status == 'all' ? null : (widget.statusCounts[status] ?? 0);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => widget.onSelectStatus(status),
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF262B37) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430))
                                  : (isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A)),
                            ),
                          ),
                          if (count != null && count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );

        final searchBox = SizedBox(
          width: isWide ? 220 : double.infinity,
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: '搜索番剧...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF98A0B3),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        );

        final sortDropdown = Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2029) : const Color(0xFFFBFBFD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF262B37) : const Color(0xFFE9EAF0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.sortBy,
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
              ),
              dropdownColor: isDark ? const Color(0xFF171A22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: SortOption.labels.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) widget.onSortChanged(val);
              },
            ),
          ),
        );

        final addBtn = ElevatedButton.icon(
          onPressed: widget.onAddAnime,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('添加番剧'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: statusTabs),
              const SizedBox(width: 16),
              searchBox,
              const SizedBox(width: 10),
              sortDropdown,
              const SizedBox(width: 10),
              addBtn,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              statusTabs,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: searchBox),
                  const SizedBox(width: 8),
                  sortDropdown,
                  const SizedBox(width: 8),
                  addBtn,
                ],
              ),
            ],
          );
        }
      },
    );
  }
}
