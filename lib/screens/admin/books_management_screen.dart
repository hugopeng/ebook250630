import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';
import '../../router.dart';

class BooksManagementScreen extends ConsumerStatefulWidget {
  const BooksManagementScreen({super.key});

  @override
  ConsumerState<BooksManagementScreen> createState() => _BooksManagementScreenState();
}

class _BooksManagementScreenState extends ConsumerState<BooksManagementScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'created_at';
  bool _ascending = false;
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final booksAsync = ref.watch(booksProvider(searchState.toParams(adminView: true)));
    final booksCountAsync = ref.watch(booksCountProvider(searchState.toParams(adminView: true)));
    final categoriesAsync = ref.watch(categoriesProvider);
    
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('書籍管理'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.adminAddBook),
            icon: const Icon(Icons.add),
            label: const Text('新增書籍'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.adminDashboard),
            icon: const Icon(Icons.arrow_back),
            label: const Text('回到儀表板'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _SearchAndFilterSection(
            searchController: _searchController,
            searchState: searchState,
            categoriesAsync: categoriesAsync,
          ),
          
          // Books Table
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table Content
                  Expanded(
                    child: booksAsync.when(
                      data: (books) => books.isNotEmpty
                          ? _BooksDataTable(
                              books: books,
                              sortBy: _sortBy,
                              ascending: _ascending,
                              onSort: _onSort,
                              isDesktop: isDesktop,
                            )
                          : _EmptyState(
                              hasSearch: searchState.query.isNotEmpty || 
                                        searchState.status != null,
                            ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => _ErrorState(
                        error: error,
                        onRetry: () => ref.invalidate(booksProvider),
                      ),
                    ),
                  ),
                  
                  // Pagination
                  booksCountAsync.when(
                    data: (totalCount) => totalCount > _itemsPerPage
                        ? _PaginationSection(
                            currentPage: _currentPage,
                            totalItems: totalCount,
                            itemsPerPage: _itemsPerPage,
                            onPageChanged: _onPageChanged,
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSort(String column, bool ascending) {
    setState(() {
      _sortBy = column;
      _ascending = ascending;
    });
    ref.read(searchStateProvider.notifier).updateSort(column, ascending);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    ref.read(searchStateProvider.notifier).updatePage(page);
  }
}

class _SearchAndFilterSection extends ConsumerWidget {
  final TextEditingController searchController;
  final SearchState searchState;
  final AsyncValue<List<String>> categoriesAsync;

  const _SearchAndFilterSection({
    required this.searchController,
    required this.searchState,
    required this.categoriesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Status Row
            Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: '搜尋',
                      hintText: '書名、作者或描述...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref.read(searchStateProvider.notifier).updateQuery(value);
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Status Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: searchState.status,
                    decoration: const InputDecoration(
                      labelText: '狀態',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('全部')),
                      DropdownMenuItem(value: 'published', child: Text('已發布')),
                      DropdownMenuItem(value: 'pending', child: Text('待審核')),
                    ],
                    onChanged: (value) {
                      ref.read(searchStateProvider.notifier).updateStatus(value);
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    // Search is auto-triggered by state changes
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('搜尋'),
                ),
                
                const SizedBox(width: 8),
                
                OutlinedButton.icon(
                  onPressed: () {
                    searchController.clear();
                    ref.read(searchStateProvider.notifier).reset();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('清除'),
                ),
              ],
            ),
            
            // Category Filter (if available)
            categoriesAsync.when(
              data: (categories) => categories.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          const Text('分類：'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                _CategoryChip(
                                  label: '全部',
                                  isSelected: searchState.category == null,
                                  onTap: () => ref.read(searchStateProvider.notifier).updateCategory(null),
                                ),
                                ...categories.map(
                                  (category) => _CategoryChip(
                                    label: category,
                                    isSelected: searchState.category == category,
                                    onTap: () => ref.read(searchStateProvider.notifier).updateCategory(category),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _BooksDataTable extends ConsumerWidget {
  final List<Book> books;
  final String sortBy;
  final bool ascending;
  final Function(String, bool) onSort;
  final bool isDesktop;

  const _BooksDataTable({
    required this.books,
    required this.sortBy,
    required this.ascending,
    required this.onSort,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktop) {
      // Mobile: Use ListView instead of DataTable
      return _MobileBooksList(books: books);
    }

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 800,
      columns: [
        DataColumn2(
          label: const Text('ID'),
          size: ColumnSize.S,
          onSort: (columnIndex, ascending) => onSort('id', ascending),
        ),
        DataColumn2(
          label: const Text('代號'),
          size: ColumnSize.S,
          onSort: (columnIndex, ascending) => onSort('product_code', ascending),
        ),
        DataColumn2(
          label: const Text('標題'),
          size: ColumnSize.L,
          onSort: (columnIndex, ascending) => onSort('title', ascending),
        ),
        DataColumn2(
          label: const Text('作者'),
          size: ColumnSize.M,
          onSort: (columnIndex, ascending) => onSort('author', ascending),
        ),
        const DataColumn2(
          label: Text('分類'),
          size: ColumnSize.S,
        ),
        const DataColumn2(
          label: Text('格式'),
          size: ColumnSize.S,
        ),
        const DataColumn2(
          label: Text('狀態'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: const Text('觀看數'),
          size: ColumnSize.S,
          numeric: true,
          onSort: (columnIndex, ascending) => onSort('view_count', ascending),
        ),
        const DataColumn2(
          label: Text('操作'),
          size: ColumnSize.L,
        ),
      ],
      rows: books.map((book) => DataRow2(
        cells: [
          DataCell(
            Text(
              book.id.length > 8 ? book.id.substring(0, 8) : book.id,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          DataCell(
            book.productCode != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      book.productCode!,
                      style: const TextStyle(fontSize: 10),
                    ),
                  )
                : const Text('-'),
          ),
          DataCell(
            Row(
              children: [
                // Cover thumbnail
                Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: book.coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.book, size: 20),
                          ),
                        )
                      : const Icon(Icons.book, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.createdAt.toString().split(' ')[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(book.author)),
          DataCell(
            book.category != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      book.category!,
                      style: const TextStyle(fontSize: 10),
                    ),
                  )
                : const Text('未分類'),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getFileTypeColor(book.fileType),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                book.fileTypeDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: book.isPublished ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                book.statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, size: 12, color: Colors.grey),
                const SizedBox(width: 2),
                Text('${book.viewCount}'),
              ],
            ),
          ),
          DataCell(
            _BookActionsMenu(book: book),
          ),
        ],
      )).toList(),
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade400;
      case 'epub':
        return Colors.blue.shade400;
      case 'txt':
        return Colors.grey.shade500;
      case 'mobi':
        return Colors.orange.shade400;
      case 'azw3':
        return Colors.purple.shade400;
      case 'url':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }
}

class _MobileBooksList extends StatelessWidget {
  final List<Book> books;

  const _MobileBooksList({required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: book.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.book, size: 20),
                      ),
                    )
                  : const Icon(Icons.book, size: 20),
            ),
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.author),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: book.isPublished ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getFileTypeColor(book.fileType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book.fileTypeDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: _BookActionsMenu(book: book),
          ),
        );
      },
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade400;
      case 'epub':
        return Colors.blue.shade400;
      case 'txt':
        return Colors.grey.shade500;
      case 'mobi':
        return Colors.orange.shade400;
      case 'azw3':
        return Colors.purple.shade400;
      case 'url':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }
}

class _BookActionsMenu extends ConsumerWidget {
  final Book book;

  const _BookActionsMenu({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'view':
            context.push(Routes.bookDetailPath(book.id));
            break;
          case 'edit':
            context.push(Routes.adminEditBookPath(book.id));
            break;
          case 'toggle_publish':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(book.isPublished ? '取消發布' : '發布書籍'),
                content: Text(
                  book.isPublished 
                      ? '確定要取消發布這本書嗎？' 
                      : '確定要發布這本書嗎？',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('確認'),
                  ),
                ],
              ),
            );
            
            if (confirmed == true) {
              await ref.read(bookManagementProvider.notifier).togglePublishStatus(book.id);
              ref.invalidate(booksProvider);
            }
            break;
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('刪除書籍'),
                content: Text('確定要刪除《${book.title}》嗎？此操作無法復原！'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('刪除'),
                  ),
                ],
              ),
            );
            
            if (confirmed == true) {
              await ref.read(bookManagementProvider.notifier).deleteBook(book.id);
              ref.invalidate(booksProvider);
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('查看'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('編輯'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'toggle_publish',
          child: ListTile(
            leading: Icon(book.isPublished ? Icons.visibility_off : Icons.check),
            title: Text(book.isPublished ? '取消發布' : '發布'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('刪除', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _PaginationSection extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChanged;

  const _PaginationSection({
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / itemsPerPage).ceil();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Text(
            '顯示第 ${(currentPage - 1) * itemsPerPage + 1} 到 '
            '${(currentPage * itemsPerPage).clamp(0, totalItems)} 項， '
            '共 $totalItems 項書籍',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1 
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                totalPages.clamp(0, 5),
                (index) {
                  final page = index + 1;
                  if (totalPages <= 5) {
                    return _PageButton(
                      page: page,
                      isSelected: page == currentPage,
                      onPressed: () => onPageChanged(page),
                    );
                  } else {
                    // Show ellipsis for large page counts
                    if (index == 0) return _PageButton(page: 1, isSelected: currentPage == 1, onPressed: () => onPageChanged(1));
                    if (index == 4) return _PageButton(page: totalPages, isSelected: currentPage == totalPages, onPressed: () => onPageChanged(totalPages));
                    if (index == 2) return _PageButton(page: currentPage, isSelected: true, onPressed: () {});
                    return const Text('...');
                  }
                },
              ),
              IconButton(
                onPressed: currentPage < totalPages 
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PageButton({
    required this.page,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$page',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : TextButton(
              onPressed: onPressed,
              child: Text('$page'),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.library_books_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? '找不到符合條件的書籍' : '暫無書籍',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch ? '試試調整搜尋條件或新增一本書籍' : '新增第一本書籍開始管理',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.adminAddBook),
            icon: const Icon(Icons.add),
            label: const Text('新增書籍'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '載入失敗',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('$error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }
}