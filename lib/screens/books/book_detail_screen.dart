import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookProvider(bookId));
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('書籍詳情'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: bookAsync.when(
        data: (book) => book != null
            ? SingleChildScrollView(
                child: isDesktop
                    ? _DesktopLayout(book: book)
                    : _MobileLayout(book: book),
              )
            : const Center(
                child: Text('書籍不存在'),
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
                onPressed: () => ref.invalidate(bookProvider(bookId)),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Book book;

  const _DesktopLayout({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover (Left)
          SizedBox(
            width: 300,
            child: _BookCover(book: book),
          ),
          
          const SizedBox(width: 32),
          
          // Book Info (Right)
          Expanded(
            child: _BookInfo(book: book),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Book book;

  const _MobileLayout({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book Cover
        Container(
          height: 300,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 200,
              child: _BookCover(book: book),
            ),
          ),
        ),
        
        // Book Info
        Padding(
          padding: const EdgeInsets.all(16),
          child: _BookInfo(book: book),
        ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  final Book book;

  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: book.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: book.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => _DefaultCover(),
              )
            : _DefaultCover(),
      ),
    );
  }

  Widget _DefaultCover() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              book.fileTypeDisplay,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookInfo extends StatelessWidget {
  final Book book;

  const _BookInfo({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          book.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Author
        Text(
          '作者：${book.author}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Metadata Row
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.category,
              label: book.category ?? '未分類',
              color: Colors.blue,
            ),
            _InfoChip(
              icon: Icons.insert_drive_file,
              label: book.fileTypeDisplay,
              color: _getFileTypeColor(book.fileType),
            ),
            if (book.productCode != null)
              _InfoChip(
                icon: Icons.qr_code,
                label: book.productCode!,
                color: Colors.grey,
              ),
            if (book.isFree)
              _InfoChip(
                icon: Icons.free_breakfast,
                label: '免費',
                color: Colors.green,
              ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Rating and Stats
        Row(
          children: [
            if (book.averageRating != null && book.averageRating! > 0) ...[
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < book.averageRating!.floor()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.orange.shade400,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${book.formattedRating} (${book.totalRatings} 評分)',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ] else ...[
              Text(
                '暫無評分',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            
            const Spacer(),
            
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${book.viewCount} 次觀看',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Description
        if (book.description != null && book.description!.isNotEmpty) ...[
          Text(
            '書籍簡介',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.description!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement read functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('閱讀功能開發中...')),
                  );
                },
                icon: Icon(book.isUrl ? Icons.open_in_new : Icons.menu_book),
                label: Text(book.isUrl ? '開啟連結' : '開始閱讀'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement bookmark functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('收藏功能開發中...')),
                );
              },
              icon: const Icon(Icons.bookmark_border),
              label: const Text('收藏'),
            ),
          ],
        ),
      ],
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'epub':
        return Colors.blue;
      case 'txt':
        return Colors.grey;
      case 'mobi':
        return Colors.orange;
      case 'azw3':
        return Colors.purple;
      case 'url':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}