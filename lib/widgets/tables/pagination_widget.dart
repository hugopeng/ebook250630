import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final void Function(int page) onPageChanged;
  final void Function(int itemsPerPage)? onItemsPerPageChanged;
  final List<int>? pageSizeOptions;
  final bool showItemsPerPageSelector;
  final bool showPageInfo;
  final bool showFirstLastButtons;
  final String itemsPerPageText;
  final String pageInfoText;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.pageSizeOptions,
    this.showItemsPerPageSelector = true,
    this.showPageInfo = true,
    this.showFirstLastButtons = true,
    this.itemsPerPageText = '每頁顯示',
    this.pageInfoText = '第 {start}-{end} 項，共 {total} 項',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          // Items per page selector
          if (showItemsPerPageSelector && onItemsPerPageChanged != null) ...[
            Text(
              itemsPerPageText,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: AppConstants.spacingS),
            DropdownButton<int>(
              value: itemsPerPage,
              items: (pageSizeOptions ?? [10, 20, 50, 100]).map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text('$size'),
                );
              }).toList(),
              onChanged: onItemsPerPageChanged,
              underline: const SizedBox(),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: AppConstants.spacingL),
          ],

          // Page info
          if (showPageInfo) ...[
            Text(
              _buildPageInfoText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppConstants.spacingL),
          ],

          const Spacer(),

          // Pagination controls
          _buildPaginationControls(theme),
        ],
      ),
    );
  }

  String _buildPageInfoText() {
    final start = (currentPage - 1) * itemsPerPage + 1;
    final end = (currentPage * itemsPerPage).clamp(0, totalItems);
    
    return pageInfoText
        .replaceAll('{start}', start.toString())
        .replaceAll('{end}', end.toString())
        .replaceAll('{total}', totalItems.toString());
  }

  Widget _buildPaginationControls(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First page button
        if (showFirstLastButtons)
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
            icon: const Icon(Icons.first_page),
            tooltip: '第一頁',
          ),

        // Previous page button
        IconButton(
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: '上一頁',
        ),

        // Page numbers
        ..._buildPageNumbers(theme),

        // Next page button
        IconButton(
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: '下一頁',
        ),

        // Last page button
        if (showFirstLastButtons)
          IconButton(
            onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
            icon: const Icon(Icons.last_page),
            tooltip: '最後一頁',
          ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(ThemeData theme) {
    const maxVisiblePages = 5;
    final List<Widget> pageNumbers = [];

    int startPage = (currentPage - maxVisiblePages ~/ 2).clamp(1, totalPages);
    int endPage = (startPage + maxVisiblePages - 1).clamp(1, totalPages);

    // Adjust start page if we're near the end
    if (endPage - startPage < maxVisiblePages - 1) {
      startPage = (endPage - maxVisiblePages + 1).clamp(1, totalPages);
    }

    // Add ellipsis at the beginning if needed
    if (startPage > 1) {
      pageNumbers.add(_buildPageButton(1, theme));
      if (startPage > 2) {
        pageNumbers.add(_buildEllipsis(theme));
      }
    }

    // Add page numbers
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageButton(i, theme));
    }

    // Add ellipsis at the end if needed
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageNumbers.add(_buildEllipsis(theme));
      }
      pageNumbers.add(_buildPageButton(totalPages, theme));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(int page, ThemeData theme) {
    final isCurrentPage = page == currentPage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isCurrentPage ? null : () => onPageChanged(page),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrentPage ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
            border: Border.all(
              color: isCurrentPage 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              '$page',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isCurrentPage 
                    ? theme.colorScheme.onPrimary 
                    : theme.colorScheme.onSurface,
                fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(ThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: Text(
        '...',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class SimplePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final void Function(int page) onPageChanged;
  final bool showPageNumbers;

  const SimplePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.showPageNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一頁',
          ),

          // Page info
          if (showPageNumbers) ...[
            const SizedBox(width: AppConstants.spacingS),
            Text(
              '$currentPage / $totalPages',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
          ],

          // Next button
          IconButton(
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一頁',
          ),
        ],
      ),
    );
  }
}

class PaginationController {
  int _currentPage = 1;
  int _itemsPerPage = AppConstants.defaultPageSize;
  int _totalItems = 0;

  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalItems => _totalItems;
  int get totalPages => (_totalItems / _itemsPerPage).ceil();
  int get startIndex => (_currentPage - 1) * _itemsPerPage;
  int get endIndex => (_currentPage * _itemsPerPage).clamp(0, _totalItems);

  bool get hasNextPage => _currentPage < totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  void setTotalItems(int total) {
    _totalItems = total;
    // Reset to first page if current page is out of bounds
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
  }

  void setCurrentPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
    }
  }

  void setItemsPerPage(int itemsPerPage) {
    _itemsPerPage = itemsPerPage;
    // Adjust current page to maintain position
    final currentStartIndex = startIndex;
    _currentPage = (currentStartIndex / _itemsPerPage).floor() + 1;
    _currentPage = _currentPage.clamp(1, totalPages.clamp(1, double.infinity).toInt());
  }

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
    }
  }

  void firstPage() {
    _currentPage = 1;
  }

  void lastPage() {
    _currentPage = totalPages;
  }

  Map<String, dynamic> toMap() {
    return {
      'page': _currentPage,
      'limit': _itemsPerPage,
      'offset': startIndex,
    };
  }

  void reset() {
    _currentPage = 1;
    _totalItems = 0;
  }
}