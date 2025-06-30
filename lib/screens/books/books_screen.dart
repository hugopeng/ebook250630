import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../providers/book_provider.dart';
import '../../widgets/cards/book_card.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final booksAsync = ref.watch(booksProvider(searchState.toParams()));
    final categoriesAsync = ref.watch(categoriesProvider);
    
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    
    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 3;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('書籍瀏覽'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋書名、作者...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchStateProvider.notifier).updateQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(searchStateProvider.notifier).updateQuery(value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Category Filter
                categoriesAsync.when(
                  data: (categories) => categories.isNotEmpty
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _CategoryChip(
                                label: '全部',
                                isSelected: searchState.category == null,
                                onTap: () => ref.read(searchStateProvider.notifier).updateCategory(null),
                              ),
                              const SizedBox(width: 8),
                              ...categories.map(
                                (category) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _CategoryChip(
                                    label: category,
                                    isSelected: searchState.category == category,
                                    onTap: () => ref.read(searchStateProvider.notifier).updateCategory(category),
                                  ),
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
          
          // Books Grid
          Expanded(
            child: booksAsync.when(
              data: (books) => books.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return BookCard(book: books[index]);
                      },
                    )
                  : _EmptyState(
                      hasSearch: searchState.query.isNotEmpty || searchState.category != null,
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      '載入失敗',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('$error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(booksProvider),
                      child: const Text('重試'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
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
          ),
        ),
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
            hasSearch ? '找不到相關書籍' : '暫無書籍',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch ? '試試調整搜尋條件' : '敬請期待更多精彩內容',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}