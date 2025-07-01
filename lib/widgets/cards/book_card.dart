import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/book.dart';
import '../../router.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      child: InkWell(
        onTap: () {
          try {
            // 嘗試使用 GoRouter
            context.push(Routes.bookDetailPath(book.id));
          } catch (e) {
            // 如果 GoRouter 不可用，顯示簡單的書籍詳情對話框
            _showBookDetailsDialog(context);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => _DefaultCover(),
                      )
                    : _DefaultCover(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Book Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Author
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Bottom Row: Rating, Category, File Type
                    Row(
                      children: [
                        // Rating
                        if (book.averageRating != null && book.averageRating! > 0) ...[
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.orange.shade400,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            book.formattedRating,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        // File Type Badge
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
                        
                        const Spacer(),
                        
                        // Free Badge
                        if (book.isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '免費',
                              style: TextStyle(
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
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _showBookDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者: ${book.author}'),
            const SizedBox(height: 8),
            Text('格式: ${book.fileTypeDisplay}'),
            if (book.category != null) ...[
              const SizedBox(height: 8),
              Text('分類: ${book.category}'),
            ],
            if (book.description != null && book.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('描述: ${book.description}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
          if (book.fileType.toLowerCase() == 'url')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openUrl(context);
              },
              child: const Text('開啟連結'),
            ),
        ],
      ),
    );
  }

  void _openUrl(BuildContext context) async {
    // 這裡可以加入開啟 URL 的邏輯
    final url = book.fileUrl ?? book.filePath;
    if (url.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開啟: $url')),
      );
    }
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
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              book.fileTypeDisplay,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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