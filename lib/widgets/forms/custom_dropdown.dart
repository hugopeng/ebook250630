import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemToString;
  final Widget Function(T)? itemBuilder;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final void Function(T?)? onSaved;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isDense;
  final double? menuMaxHeight;
  final Color? fillColor;
  final InputBorder? border;

  const CustomDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    required this.itemToString,
    this.itemBuilder,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.isDense = false,
    this.menuMaxHeight,
    this.fillColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder?.call(item) ?? Text(itemToString(item)),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      onSaved: onSaved,
      isDense: isDense,
      menuMaxHeight: menuMaxHeight,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        filled: true,
        fillColor: fillColor ?? theme.colorScheme.surface,
        border: border ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool enabled;
  final String? label;

  const CategoryDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      label: label ?? '分類',
      hint: '請選擇書籍分類',
      value: value,
      items: AppConstants.bookCategories,
      itemToString: (category) => category,
      onChanged: onChanged,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      prefixIcon: const Icon(Icons.category_outlined),
    );
  }
}

class BookFormatDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool enabled;
  final String? label;
  final bool includeUrl;

  const BookFormatDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.label,
    this.includeUrl = true,
  });

  @override
  Widget build(BuildContext context) {
    final formats = includeUrl 
        ? AppConstants.allowedBookFormats 
        : AppConstants.allowedBookFormats.where((f) => f != 'url').toList();

    return CustomDropdown<String>(
      label: label ?? '檔案格式',
      hint: '請選擇檔案格式',
      value: value,
      items: formats,
      itemToString: (format) => AppConstants.bookFormatNames[format] ?? format.toUpperCase(),
      itemBuilder: (format) {
        return Row(
          children: [
            Icon(_getFormatIcon(format), size: 20),
            const SizedBox(width: AppConstants.spacingS),
            Text(AppConstants.bookFormatNames[format] ?? format.toUpperCase()),
          ],
        );
      },
      onChanged: onChanged,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      prefixIcon: const Icon(Icons.file_present_outlined),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'epub':
        return Icons.menu_book;
      case 'txt':
        return Icons.text_snippet;
      case 'mobi':
      case 'azw3':
        return Icons.import_contacts;
      case 'url':
        return Icons.link;
      default:
        return Icons.description;
    }
  }
}

class StatusDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool enabled;
  final String? label;

  const StatusDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.label,
  });

  static const Map<String, String> _statusLabels = {
    'draft': '草稿',
    'published': '已發布',
    'archived': '已封存',
  };

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      label: label ?? '狀態',
      hint: '請選擇狀態',
      value: value,
      items: _statusLabels.keys.toList(),
      itemToString: (status) => _statusLabels[status] ?? status,
      itemBuilder: (status) {
        return Row(
          children: [
            Icon(_getStatusIcon(status), size: 20, color: _getStatusColor(status)),
            const SizedBox(width: AppConstants.spacingS),
            Text(_statusLabels[status] ?? status),
          ],
        );
      },
      onChanged: onChanged,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      prefixIcon: const Icon(Icons.info_outline),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'published':
        return Icons.check_circle;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return AppConstants.warningColor;
      case 'published':
        return AppConstants.successColor;
      case 'archived':
        return AppConstants.secondaryColor;
      default:
        return AppConstants.secondaryColor;
    }
  }
}

class RatingDropdown extends StatelessWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final void Function(int?)? onSaved;
  final bool enabled;
  final String? label;

  const RatingDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ratings = List.generate(5, (index) => index + 1);

    return CustomDropdown<int>(
      label: label ?? '評分',
      hint: '請選擇評分',
      value: value,
      items: ratings,
      itemToString: (rating) => '$rating 星',
      itemBuilder: (rating) {
        return Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 16,
                color: AppConstants.warningColor,
              );
            }),
            const SizedBox(width: AppConstants.spacingS),
            Text('$rating 星'),
          ],
        );
      },
      onChanged: onChanged,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      prefixIcon: const Icon(Icons.star_outline),
    );
  }
}

class SortOrderDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?)? onChanged;
  final bool enabled;
  final String? label;

  const SortOrderDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.label,
  });

  static const Map<String, String> _sortOptions = {
    'title_asc': '書名 A-Z',
    'title_desc': '書名 Z-A',
    'author_asc': '作者 A-Z',
    'author_desc': '作者 Z-A',
    'created_desc': '最新上傳',
    'created_asc': '最早上傳',
    'rating_desc': '評分高到低',
    'rating_asc': '評分低到高',
    'views_desc': '最多瀏覽',
    'views_asc': '最少瀏覽',
  };

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      label: label ?? '排序方式',
      hint: '請選擇排序方式',
      value: value,
      items: _sortOptions.keys.toList(),
      itemToString: (sort) => _sortOptions[sort] ?? sort,
      onChanged: onChanged,
      enabled: enabled,
      prefixIcon: const Icon(Icons.sort),
      isDense: true,
    );
  }
}