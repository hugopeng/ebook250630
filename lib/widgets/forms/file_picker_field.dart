import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_constants.dart';
import '../../utils/file_utils.dart';
import '../../utils/validation_utils.dart';

class FilePickerField extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<String> allowedExtensions;
  final void Function(File?)? onFileSelected;
  final void Function(PlatformFile?)? onPlatformFileSelected;
  final String? Function(PlatformFile?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final bool allowMultiple;
  final FileType fileType;
  final PlatformFile? initialFile;

  const FilePickerField({
    super.key,
    this.label,
    this.hint,
    this.allowedExtensions = const [],
    this.onFileSelected,
    this.onPlatformFileSelected,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.allowMultiple = false,
    this.fileType = FileType.any,
    this.initialFile,
  });

  @override
  State<FilePickerField> createState() => _FilePickerFieldState();
}

class _FilePickerFieldState extends State<FilePickerField> {
  PlatformFile? _selectedFile;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.fileType,
        allowedExtensions: widget.allowedExtensions.isNotEmpty 
            ? widget.allowedExtensions 
            : null,
        allowMultiple: widget.allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file
        final validationError = widget.validator?.call(file);
        if (validationError != null) {
          setState(() {
            _errorText = validationError;
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _errorText = null;
        });

        // Call callbacks
        widget.onPlatformFileSelected?.call(file);
        
        if (!kIsWeb && file.path != null) {
          widget.onFileSelected?.call(File(file.path!));
        }
      }
    } catch (e) {
      setState(() {
        _errorText = '選擇檔案時發生錯誤：$e';
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _errorText = null;
    });
    widget.onFileSelected?.call(null);
    widget.onPlatformFileSelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FormField<PlatformFile>(
      initialValue: _selectedFile,
      validator: (value) => widget.validator?.call(value),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
            ],
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: field.hasError 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              ),
              child: InkWell(
                onTap: widget.enabled ? _pickFile : null,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: _selectedFile != null 
                      ? _buildSelectedFileWidget(theme)
                      : _buildPlaceholderWidget(theme),
                ),
              ),
            ),
            
            if (field.hasError) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                field.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            
            if (_errorText != null) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSelectedFileWidget(ThemeData theme) {
    return Row(
      children: [
        widget.prefixIcon ?? Icon(
          _getFileIcon(_selectedFile!.extension),
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedFile!.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                FileUtils.formatFileSize(_selectedFile!.size),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (widget.enabled) ...[
          IconButton(
            onPressed: _removeFile,
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.error,
            ),
            tooltip: '移除檔案',
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderWidget(ThemeData theme) {
    return Row(
      children: [
        widget.prefixIcon ?? Icon(
          Icons.attach_file,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Text(
            widget.hint ?? '點擊選擇檔案',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.description;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'epub':
        return Icons.menu_book;
      case 'txt':
        return Icons.text_snippet;
      case 'mobi':
      case 'azw3':
        return Icons.import_contacts;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image;
      default:
        return Icons.description;
    }
  }
}

class BookFilePickerField extends StatelessWidget {
  final String? label;
  final void Function(PlatformFile?)? onFileSelected;
  final String? Function(PlatformFile?)? validator;
  final bool enabled;
  final PlatformFile? initialFile;

  const BookFilePickerField({
    super.key,
    this.label,
    this.onFileSelected,
    this.validator,
    this.enabled = true,
    this.initialFile,
  });

  String? _defaultValidator(PlatformFile? file) {
    if (file == null) {
      return '請選擇書籍檔案';
    }

    // Validate file format
    final formatError = ValidationUtils.validateFileFormat(file.name);
    if (formatError != null) {
      return formatError;
    }

    // Validate file size
    final sizeError = ValidationUtils.validateFileSize(file.size);
    if (sizeError != null) {
      return sizeError;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FilePickerField(
      label: label ?? '書籍檔案',
      hint: '選擇書籍檔案 (PDF, EPUB, TXT, MOBI, AZW3)',
      allowedExtensions: AppConstants.allowedBookFormats
          .where((format) => format != 'url')
          .toList(),
      fileType: FileType.custom,
      onPlatformFileSelected: onFileSelected,
      validator: validator ?? _defaultValidator,
      enabled: enabled,
      prefixIcon: const Icon(Icons.menu_book),
      initialFile: initialFile,
    );
  }
}

class ImagePickerField extends StatelessWidget {
  final String? label;
  final void Function(PlatformFile?)? onFileSelected;
  final String? Function(PlatformFile?)? validator;
  final bool enabled;
  final PlatformFile? initialFile;

  const ImagePickerField({
    super.key,
    this.label,
    this.onFileSelected,
    this.validator,
    this.enabled = true,
    this.initialFile,
  });

  String? _defaultValidator(PlatformFile? file) {
    if (file == null) {
      return null; // Image is optional
    }

    // Validate image format
    final formatError = ValidationUtils.validateImageFormat(file.name);
    if (formatError != null) {
      return formatError;
    }

    // Validate file size (images should be smaller)
    const maxImageSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxImageSize) {
      return '圖片大小不能超過 5MB';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FilePickerField(
      label: label ?? '封面圖片',
      hint: '選擇封面圖片 (JPG, PNG, WebP)',
      allowedExtensions: AppConstants.allowedImageFormats,
      fileType: FileType.custom,
      onPlatformFileSelected: onFileSelected,
      validator: validator ?? _defaultValidator,
      enabled: enabled,
      prefixIcon: const Icon(Icons.image),
      initialFile: initialFile,
    );
  }
}

class MultipleFilePickerField extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<String> allowedExtensions;
  final void Function(List<PlatformFile>)? onFilesSelected;
  final String? Function(List<PlatformFile>)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final FileType fileType;
  final List<PlatformFile> initialFiles;
  final int? maxFiles;

  const MultipleFilePickerField({
    super.key,
    this.label,
    this.hint,
    this.allowedExtensions = const [],
    this.onFilesSelected,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.fileType = FileType.any,
    this.initialFiles = const [],
    this.maxFiles,
  });

  @override
  State<MultipleFilePickerField> createState() => _MultipleFilePickerFieldState();
}

class _MultipleFilePickerFieldState extends State<MultipleFilePickerField> {
  List<PlatformFile> _selectedFiles = [];
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedFiles = List.from(widget.initialFiles);
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.fileType,
        allowedExtensions: widget.allowedExtensions.isNotEmpty 
            ? widget.allowedExtensions 
            : null,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = result.files;
        
        // Check max files limit
        if (widget.maxFiles != null) {
          final totalFiles = _selectedFiles.length + newFiles.length;
          if (totalFiles > widget.maxFiles!) {
            setState(() {
              _errorText = '最多只能選擇 ${widget.maxFiles} 個檔案';
            });
            return;
          }
        }

        setState(() {
          _selectedFiles.addAll(newFiles);
          _errorText = null;
        });

        widget.onFilesSelected?.call(_selectedFiles);
      }
    } catch (e) {
      setState(() {
        _errorText = '選擇檔案時發生錯誤：$e';
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onFilesSelected?.call(_selectedFiles);
  }

  void _clearAllFiles() {
    setState(() {
      _selectedFiles.clear();
      _errorText = null;
    });
    widget.onFilesSelected?.call(_selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FormField<List<PlatformFile>>(
      initialValue: _selectedFiles,
      validator: widget.validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Row(
                children: [
                  Text(
                    widget.label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_selectedFiles.isNotEmpty) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearAllFiles,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('清除全部'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
            ],
            
            // Add files button
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: field.hasError 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              ),
              child: InkWell(
                onTap: widget.enabled ? _pickFiles : null,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Row(
                    children: [
                      widget.prefixIcon ?? Icon(
                        Icons.add,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Text(
                          widget.hint ?? '點擊添加檔案',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Selected files list
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              ...List.generate(_selectedFiles.length, (index) {
                final file = _selectedFiles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                  child: ListTile(
                    leading: Icon(_getFileIcon(file.extension)),
                    title: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(FileUtils.formatFileSize(file.size)),
                    trailing: widget.enabled 
                        ? IconButton(
                            onPressed: () => _removeFile(index),
                            icon: Icon(
                              Icons.delete,
                              color: theme.colorScheme.error,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ],
            
            if (field.hasError) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                field.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            
            if (_errorText != null) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.description;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'epub':
        return Icons.menu_book;
      case 'txt':
        return Icons.text_snippet;
      case 'mobi':
      case 'azw3':
        return Icons.import_contacts;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image;
      default:
        return Icons.description;
    }
  }
}