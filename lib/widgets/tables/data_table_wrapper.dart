import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../constants/app_constants.dart';

class DataTableWrapper<T> extends StatelessWidget {
  final List<DataColumn> columns;
  final List<T> data;
  final List<DataCell> Function(T item, int index) cellBuilder;
  final void Function(T item)? onRowTap;
  final bool Function(T item)? isRowSelected;
  final void Function(T item, bool selected)? onRowSelectionChanged;
  final String? emptyMessage;
  final bool showCheckboxColumn;
  final bool sortAscending;
  final int? sortColumnIndex;
  final double? columnSpacing;
  final double? horizontalMargin;
  final double? rowHeight;
  final bool loading;
  final Widget? loadingWidget;
  final bool showBorders;
  final Color? headingRowColor;
  final TextStyle? headingTextStyle;
  final TextStyle? dataTextStyle;
  final ScrollController? scrollController;

  const DataTableWrapper({
    super.key,
    required this.columns,
    required this.data,
    required this.cellBuilder,
    this.onRowTap,
    this.isRowSelected,
    this.onRowSelectionChanged,
    this.emptyMessage,
    this.showCheckboxColumn = false,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.columnSpacing,
    this.horizontalMargin,
    this.rowHeight,
    this.loading = false,
    this.loadingWidget,
    this.showBorders = true,
    this.headingRowColor,
    this.headingTextStyle,
    this.dataTextStyle,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: loadingWidget ?? 
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppConstants.spacingM),
                Text(AppConstants.loadingMessage),
              ],
            ),
      );
    }

    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              emptyMessage ?? AppConstants.noDataMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: showBorders ? Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ) : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: DataTable2(
        columns: columns,
        rows: List.generate(data.length, (index) {
          final item = data[index];
          final cells = cellBuilder(item, index);
          final isSelected = isRowSelected?.call(item) ?? false;

          return DataRow2(
            selected: isSelected,
            onSelectChanged: onRowSelectionChanged != null 
                ? (selected) => onRowSelectionChanged!(item, selected ?? false)
                : null,
            onTap: onRowTap != null ? () => onRowTap!(item) : null,
            cells: cells,
          );
        }),
        showCheckboxColumn: showCheckboxColumn,
        sortAscending: sortAscending,
        sortColumnIndex: sortColumnIndex,
        columnSpacing: columnSpacing ?? AppConstants.spacingM,
        horizontalMargin: horizontalMargin ?? AppConstants.spacingM,
        minWidth: 600,
        scrollController: scrollController,
        headingRowColor: MaterialStateProperty.all(
          headingRowColor ?? theme.colorScheme.surfaceVariant,
        ),
        headingTextStyle: headingTextStyle ?? theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: dataTextStyle ?? theme.textTheme.bodyMedium,
        border: showBorders ? TableBorder.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ) : null,
      ),
    );
  }
}

class ResponsiveDataTable<T> extends StatelessWidget {
  final List<DataColumn> columns;
  final List<T> data;
  final List<DataCell> Function(T item, int index) cellBuilder;
  final Widget Function(T item, int index)? mobileCardBuilder;
  final void Function(T item)? onRowTap;
  final bool Function(T item)? isRowSelected;
  final void Function(T item, bool selected)? onRowSelectionChanged;
  final String? emptyMessage;
  final bool showCheckboxColumn;
  final bool sortAscending;
  final int? sortColumnIndex;
  final bool loading;
  final Widget? loadingWidget;
  final double mobileBreakpoint;

  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.data,
    required this.cellBuilder,
    this.mobileCardBuilder,
    this.onRowTap,
    this.isRowSelected,
    this.onRowSelectionChanged,
    this.emptyMessage,
    this.showCheckboxColumn = false,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.loading = false,
    this.loadingWidget,
    this.mobileBreakpoint = AppConstants.tabletBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint && mobileCardBuilder != null) {
          return _buildMobileView();
        } else {
          return _buildTableView();
        }
      },
    );
  }

  Widget _buildTableView() {
    return DataTableWrapper<T>(
      columns: columns,
      data: data,
      cellBuilder: cellBuilder,
      onRowTap: onRowTap,
      isRowSelected: isRowSelected,
      onRowSelectionChanged: onRowSelectionChanged,
      emptyMessage: emptyMessage,
      showCheckboxColumn: showCheckboxColumn,
      sortAscending: sortAscending,
      sortColumnIndex: sortColumnIndex,
      loading: loading,
      loadingWidget: loadingWidget,
    );
  }

  Widget _buildMobileView() {
    if (loading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: loadingWidget ?? 
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppConstants.spacingM),
                Text(AppConstants.loadingMessage),
              ],
            ),
      );
    }

    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              emptyMessage ?? AppConstants.noDataMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return mobileCardBuilder!(item, index);
      },
    );
  }
}

class SortableDataColumn extends DataColumn {
  final String sortKey;
  final bool numeric;

  const SortableDataColumn({
    required Widget label,
    required this.sortKey,
    this.numeric = false,
    String? tooltip,
    bool Function(dynamic, dynamic)? onSort,
  }) : super(
          label: label,
          tooltip: tooltip,
          numeric: numeric,
          onSort: onSort,
        );

  static List<DataColumn> createColumns(
    List<Map<String, dynamic>> columnDefs,
    String? currentSortKey,
    bool sortAscending,
    void Function(String sortKey, bool ascending)? onSort,
  ) {
    return columnDefs.map((def) {
      final sortKey = def['sortKey'] as String?;
      final isCurrentSort = sortKey == currentSortKey;
      
      return DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(def['title'] as String),
            if (sortKey != null && isCurrentSort) ...[
              const SizedBox(width: AppConstants.spacingXs),
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
            ],
          ],
        ),
        tooltip: def['tooltip'] as String?,
        numeric: def['numeric'] as bool? ?? false,
        onSort: sortKey != null && onSort != null 
            ? (_, ascending) => onSort(sortKey, ascending)
            : null,
      );
    }).toList();
  }
}

class DataTableActionMenu extends StatelessWidget {
  final List<PopupMenuEntry<String>> menuItems;
  final void Function(String action)? onActionSelected;
  final IconData icon;
  final String tooltip;

  const DataTableActionMenu({
    super.key,
    required this.menuItems,
    this.onActionSelected,
    this.icon = Icons.more_vert,
    this.tooltip = '更多操作',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip,
      onSelected: onActionSelected,
      itemBuilder: (context) => menuItems,
    );
  }

  static PopupMenuItem<String> createMenuItem({
    required String value,
    required String text,
    IconData? icon,
    Color? textColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Text(
            text,
            style: textColor != null ? TextStyle(color: textColor) : null,
          ),
        ],
      ),
    );
  }
}

class DataTableStatusChip extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;
  final Map<String, Color>? statusColors;

  const DataTableStatusChip({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textColor,
    this.statusColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? 
        statusColors?[status] ?? 
        _getDefaultStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        border: Border.all(
          color: effectiveBackgroundColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        status,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor ?? effectiveBackgroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getDefaultStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case '已發布':
        return AppConstants.successColor;
      case 'draft':
      case '草稿':
        return AppConstants.warningColor;
      case 'archived':
      case '已封存':
        return AppConstants.secondaryColor;
      case 'active':
      case '啟用':
        return AppConstants.successColor;
      case 'inactive':
      case '停用':
        return AppConstants.errorColor;
      default:
        return AppConstants.secondaryColor;
    }
  }
}

class DataTableRatingDisplay extends StatelessWidget {
  final double? rating;
  final int? totalRatings;
  final bool showCount;
  final double starSize;

  const DataTableRatingDisplay({
    super.key,
    this.rating,
    this.totalRatings,
    this.showCount = true,
    this.starSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRating = rating ?? 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final isFilled = index < effectiveRating.floor();
            final isHalfFilled = index < effectiveRating && index >= effectiveRating.floor();
            
            return Icon(
              isFilled || isHalfFilled ? Icons.star : Icons.star_border,
              size: starSize,
              color: AppConstants.warningColor,
            );
          }),
        ),
        if (showCount) ...[
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            '(${totalRatings ?? 0})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}