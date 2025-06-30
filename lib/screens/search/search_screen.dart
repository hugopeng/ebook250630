import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/book.dart';
import '../../providers/search_provider.dart';
import '../../widgets/cards/book_card.dart';
import '../../constants/app_constants.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _selectedCategory;
  String? _selectedFileType;
  double? _minRating;
  bool _sortByRating = false;
  bool _sortByDate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategory == null && _selectedFileType == null) {
      return;
    }

    ref.read(searchNotifierProvider.notifier).searchBooks(
      query: query.isEmpty ? null : query,
      category: _selectedCategory,
      fileType: _selectedFileType,
      minRating: _minRating,
      sortByRating: _sortByRating,
      sortByDate: _sortByDate,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedFileType = null;
      _minRating = null;
      _sortByRating = false;
      _sortByDate = false;
    });
    ref.read(searchNotifierProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜尋書籍'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜尋欄位
          Container(
            color: AppConstants.primaryColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 主搜尋框
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: '搜尋書名、作者...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.isNotEmpty) {
                      // 延遲搜尋，避免過於頻繁的API調用
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value) {
                          _performSearch();
                        }
                      });
                    }
                  },
                  onSubmitted: (_) => _performSearch(),
                ),
                
                const SizedBox(height: 12),
                
                // 篩選選項
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 分類篩選
                      _buildFilterChip(
                        label: '分類: ${_selectedCategory ?? "全部"}',
                        icon: Icons.category,
                        onTap: () => _showCategoryDialog(),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 檔案類型篩選
                      _buildFilterChip(
                        label: '格式: ${_selectedFileType ?? "全部"}',
                        icon: Icons.file_copy,
                        onTap: () => _showFileTypeDialog(),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 評分篩選
                      _buildFilterChip(
                        label: '評分: ${_minRating?.toStringAsFixed(1) ?? "全部"}',
                        icon: Icons.star,
                        onTap: () => _showRatingDialog(),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 排序選項
                      _buildFilterChip(
                        label: '排序',
                        icon: Icons.sort,
                        onTap: () => _showSortDialog(),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 清除篩選
                      if (_hasActiveFilters)
                        _buildFilterChip(
                          label: '清除',
                          icon: Icons.clear_all,
                          onTap: _clearSearch,
                          isDestructive: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 搜尋結果
          Expanded(
            child: _buildSearchResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive ? Colors.red : Colors.white.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive ? Colors.red : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('搜尋中...'),
          ],
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('搜尋失敗: ${searchState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    final books = searchState.results;
    
    if (books.isEmpty && !searchState.hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '輸入關鍵字開始搜尋',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '可搜尋書名、作者，或使用篩選功能',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '找不到符合條件的書籍',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '已搜尋: ${searchState.lastQuery ?? "無"}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('清除搜尋'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookCard(book: book),
        );
      },
    );
  }

  bool get _hasActiveFilters {
    return _selectedCategory != null ||
           _selectedFileType != null ||
           _minRating != null ||
           _sortByRating ||
           _sortByDate ||
           _searchController.text.isNotEmpty;
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇分類'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  Navigator.pop(context);
                  _performSearch();
                },
              ),
            ),
            ...AppConstants.bookCategories.map((category) => ListTile(
              title: Text(category),
              leading: Radio<String?>(
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  Navigator.pop(context);
                  _performSearch();
                },
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showFileTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedFileType,
                onChanged: (value) {
                  setState(() => _selectedFileType = value);
                  Navigator.pop(context);
                  _performSearch();
                },
              ),
            ),
            ...AppConstants.allowedBookFormats.map((format) => ListTile(
              title: Text(format.toUpperCase()),
              leading: Radio<String?>(
                value: format,
                groupValue: _selectedFileType,
                onChanged: (value) {
                  setState(() => _selectedFileType = value);
                  Navigator.pop(context);
                  _performSearch();
                },
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最低評分'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部'),
              leading: Radio<double?>(
                value: null,
                groupValue: _minRating,
                onChanged: (value) {
                  setState(() => _minRating = value);
                  Navigator.pop(context);
                  _performSearch();
                },
              ),
            ),
            for (int i = 1; i <= 5; i++)
              ListTile(
                title: Row(
                  children: [
                    for (int j = 0; j < i; j++)
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                    for (int j = i; j < 5; j++)
                      const Icon(Icons.star_outline, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text('$i 星以上'),
                  ],
                ),
                leading: Radio<double?>(
                  value: i.toDouble(),
                  groupValue: _minRating,
                  onChanged: (value) {
                    setState(() => _minRating = value);
                    Navigator.pop(context);
                    _performSearch();
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('排序方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('按評分排序'),
              value: _sortByRating,
              onChanged: (value) {
                setState(() {
                  _sortByRating = value ?? false;
                  if (_sortByRating) _sortByDate = false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('按日期排序'),
              value: _sortByDate,
              onChanged: (value) {
                setState(() {
                  _sortByDate = value ?? false;
                  if (_sortByDate) _sortByRating = false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch();
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}