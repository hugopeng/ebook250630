import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';
import '../../router.dart';

class EditBookScreen extends ConsumerStatefulWidget {
  final String bookId;

  const EditBookScreen({super.key, required this.bookId});

  @override
  ConsumerState<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends ConsumerState<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _filePathController = TextEditingController();
  
  // Form state
  String _selectedFileType = 'url';
  bool _isFree = true;
  bool _isPublished = false;
  PlatformFile? _selectedCoverFile;
  Book? _currentBook;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _productCodeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  void _initializeForm(Book book) {
    if (_currentBook?.id == book.id) return; // Already initialized
    
    _currentBook = book;
    _titleController.text = book.title;
    _authorController.text = book.author;
    _productCodeController.text = book.productCode ?? '';
    _categoryController.text = book.category ?? '';
    _descriptionController.text = book.description ?? '';
    _filePathController.text = book.filePath;
    
    setState(() {
      _selectedFileType = book.fileType;
      _isFree = book.isFree;
      _isPublished = book.isPublished;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookProvider(widget.bookId));
    final bookManagement = ref.watch(bookManagementProvider);
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.edit),
            const SizedBox(width: 8),
            const Text('編輯書籍'),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          bookAsync.whenOrNull(
            data: (book) => book != null
                ? OutlinedButton.icon(
                    onPressed: () => context.push(Routes.bookDetailPath(book.id)),
                    icon: const Icon(Icons.visibility),
                    label: const Text('查看書籍'),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.adminBooks),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回列表'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return const Center(child: Text('書籍不存在'));
          }
          
          _initializeForm(book);
          
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Current Status Alert
                    _buildStatusAlert(book),
                    
                    const SizedBox(height: 16),
                    
                    // Edit Form
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Form Title
                              Text(
                                '編輯書籍',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Basic Information Section
                              _buildBasicInfoSection(),
                              
                              const SizedBox(height: 24),
                              
                              // Description Section
                              _buildDescriptionSection(),
                              
                              const SizedBox(height: 24),
                              
                              // File Path Section
                              _buildFilePathSection(),
                              
                              const SizedBox(height: 24),
                              
                              // Cover Image Section
                              _buildCoverImageSection(book),
                              
                              const SizedBox(height: 24),
                              
                              // Settings Section
                              _buildSettingsSection(),
                              
                              const SizedBox(height: 32),
                              
                              // Action Buttons
                              _buildActionButtons(bookManagement),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Danger Zone
                    _buildDangerZone(book, bookManagement),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
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
                onPressed: () => ref.invalidate(bookProvider(widget.bookId)),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAlert(Book book) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '目前狀態：',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: book.isPublished ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  book.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '觀看次數：${book.viewCount}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '創建時間：${book.createdAt.toString().split(' ')[0]}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Quick Toggle Button
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _togglePublishStatus(book),
                icon: Icon(book.isPublished ? Icons.visibility_off : Icons.check),
                label: Text(book.isPublished ? '取消發布' : '立即發布'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: book.isPublished ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '基本資訊',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title, Product Code, Author Row
        Row(
          children: [
            // Title
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '書籍標題 *',
                  hintText: '請輸入書籍標題',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入書籍標題';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Product Code
            Expanded(
              child: TextFormField(
                controller: _productCodeController,
                decoration: const InputDecoration(
                  labelText: '貨品代號',
                  hintText: '例如: B700-A1',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final regex = RegExp(r'^[A-Za-z0-9\-]+$');
                    if (!regex.hasMatch(value)) {
                      return '只能包含英文字母、數字和破折號';
                    }
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Author
            Expanded(
              child: TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: '作者 *',
                  hintText: '請輸入作者姓名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入作者姓名';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Category and File Type Row
        Row(
          children: [
            // Category
            Expanded(
              child: TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: '分類',
                  hintText: '例如：程式設計、Web開發',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // File Type
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFileType,
                decoration: const InputDecoration(
                  labelText: '檔案格式 *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'epub', child: Text('EPUB')),
                  DropdownMenuItem(value: 'txt', child: Text('TXT')),
                  DropdownMenuItem(value: 'mobi', child: Text('MOBI')),
                  DropdownMenuItem(value: 'azw3', child: Text('AZW3')),
                  DropdownMenuItem(value: 'url', child: Text('網址連結 (URL)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFileType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請選擇檔案格式';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '書籍描述',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '書籍描述',
            hintText: '請輸入書籍的簡介或描述...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildFilePathSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedFileType == 'url' ? '網址' : '檔案路徑',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _filePathController,
                decoration: InputDecoration(
                  labelText: _selectedFileType == 'url' ? '網址 *' : '檔案路徑 *',
                  hintText: _selectedFileType == 'url' 
                      ? '請輸入完整網址'
                      : '本地檔案路徑',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _selectedFileType == 'url' ? '請輸入網址' : '請輸入檔案路徑';
                  }
                  if (_selectedFileType == 'url') {
                    final urlRegex = RegExp(r'^https?://');
                    if (!urlRegex.hasMatch(value)) {
                      return '網址必須以 http:// 或 https:// 開頭';
                    }
                  }
                  return null;
                },
              ),
            ),
            
            if (_selectedFileType != 'url') ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('選擇檔案'),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Help Text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedFileType == 'url'
                      ? '網址連結: 需以 http:// 或 https:// 開頭'
                      : '本地檔案: 相對於應用程式根目錄的路徑',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImageSection(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '封面圖片',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            // Current Cover Preview
            if (book.coverUrl != null || _selectedCoverFile != null) ...[
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _selectedCoverFile?.bytes != null
                      ? Image.memory(
                          _selectedCoverFile!.bytes!,
                          fit: BoxFit.cover,
                        )
                      : book.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: book.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.image, size: 40),
                            )
                          : const Icon(Icons.image, size: 40),
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            // Upload Button and Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.coverUrl != null)
                    Text(
                      '目前封面圖片',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _pickCoverImage,
                    icon: const Icon(Icons.upload),
                    label: Text(
                      book.coverUrl != null || _selectedCoverFile != null 
                          ? '更換封面' 
                          : '選擇封面圖片'
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    '支援 JPG, PNG, GIF, WebP 格式，建議尺寸 400x600 像素。如不選擇檔案則保持現有封面。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  if (_selectedCoverFile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '已選擇新封面: ${_selectedCoverFile!.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '設定選項',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Free Checkbox
            Expanded(
              child: CheckboxListTile(
                value: _isFree,
                onChanged: (value) {
                  setState(() {
                    _isFree = value ?? true;
                  });
                },
                title: Row(
                  children: [
                    Icon(Icons.free_breakfast, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text('免費書籍'),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            
            // Published Checkbox
            Expanded(
              child: CheckboxListTile(
                value: _isPublished,
                onChanged: (value) {
                  setState(() {
                    _isPublished = value ?? false;
                  });
                },
                title: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text('已發布'),
                  ],
                ),
                subtitle: const Text('取消勾選將變為待審核狀態'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(AsyncValue<void> bookManagement) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: bookManagement.isLoading 
              ? null 
              : () => context.push(Routes.adminBooks),
          icon: const Icon(Icons.close),
          label: const Text('取消'),
        ),
        
        const Spacer(),
        
        ElevatedButton.icon(
          onPressed: bookManagement.isLoading 
              ? null 
              : _saveChanges,
          icon: bookManagement.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(bookManagement.isLoading ? '儲存中...' : '儲存變更'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(Book book, AsyncValue<void> bookManagement) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  '危險操作',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '刪除書籍',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '永久刪除這本書籍，此操作無法復原',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: bookManagement.isLoading 
                      ? null 
                      : () => _deleteBook(book),
                  icon: const Icon(Icons.delete),
                  label: const Text('刪除書籍'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _filePathController.text = file.path ?? file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選擇檔案失敗: $e')),
      );
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedCoverFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選擇圖片失敗: $e')),
      );
    }
  }

  Future<void> _togglePublishStatus(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.isPublished ? '取消發布' : '發布書籍'),
        content: Text(
          book.isPublished 
              ? '確定要取消發布嗎？' 
              : '確定要發布嗎？',
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
      ref.invalidate(bookProvider(widget.bookId));
      ref.invalidate(booksProvider);
      ref.invalidate(bookStatisticsProvider);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final book = await ref.read(bookManagementProvider.notifier).updateBook(
        widget.bookId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        filePath: _filePathController.text.trim(),
        fileType: _selectedFileType,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        productCode: _productCodeController.text.trim().isEmpty 
            ? null 
            : _productCodeController.text.trim(),
        // TODO: Implement file upload for cover
        isPublished: _isPublished,
        isFree: _isFree,
      );

      if (book != null) {
        // Invalidate providers to refresh data
        ref.invalidate(bookProvider(widget.bookId));
        ref.invalidate(booksProvider);
        ref.invalidate(bookStatisticsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('書籍《${book.title}》更新成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('書籍更新失敗');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新書籍失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除書籍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('確定要刪除《${book.title}》嗎？'),
            const SizedBox(height: 8),
            const Text(
              '此操作無法復原！',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
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
      
      // Invalidate providers to refresh data
      ref.invalidate(booksProvider);
      ref.invalidate(bookStatisticsProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('書籍《${book.title}》已刪除'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Navigate back to books list
      context.push(Routes.adminBooks);
    }
  }
}