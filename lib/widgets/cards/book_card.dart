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
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push(Routes.bookDetailPath(book.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                ),
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
            
            // Book Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
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