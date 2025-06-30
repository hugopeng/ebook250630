import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/book_provider.dart';
import '../../router.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
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

  @override
  Widget build(BuildContext context) {
    final bookManagement = ref.watch(bookManagementProvider);
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.add),
            const SizedBox(width: 8),
            const Text('新增書籍'),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.adminBooks),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回列表'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
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
                        '新增書籍',
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
                      _buildCoverImageSection(),
                      
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
          ),
        ),
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
                    _updateFilePathLabel();
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
          '檔案路徑/網址',
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
                      ? '請輸入完整網址，例如：https://docs.github.com'
                      : '本地檔案路徑，例如：uploads/books/sample.pdf',
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
                      : '本地檔案: 例如 uploads/books/sample.pdf',
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

  Widget _buildCoverImageSection() {
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
            // Cover Preview
            if (_selectedCoverFile != null) ...[
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _selectedCoverFile!.bytes != null
                      ? Image.memory(
                          _selectedCoverFile!.bytes!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 40),
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            // Upload Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickCoverImage,
                    icon: const Icon(Icons.upload),
                    label: Text(_selectedCoverFile != null ? '更換封面' : '選擇封面圖片'),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    '支援 JPG, PNG, GIF 格式，建議尺寸 400x600 像素',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  if (_selectedCoverFile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '已選擇: ${_selectedCoverFile!.name}',
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
                    const Text('立即發布'),
                  ],
                ),
                subtitle: const Text('不勾選則為待審核狀態'),
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
        
        // Save Button
        ElevatedButton.icon(
          onPressed: bookManagement.isLoading 
              ? null 
              : () => _saveBook(false),
          icon: bookManagement.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(bookManagement.isLoading ? '儲存中...' : '儲存書籍'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Save and Continue Button
        ElevatedButton.icon(
          onPressed: bookManagement.isLoading 
              ? null 
              : () => _saveBook(true),
          icon: const Icon(Icons.add),
          label: const Text('儲存並繼續新增'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _updateFilePathLabel() {
    // This is handled by the setState in the dropdown onChanged
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

  Future<void> _saveBook(bool continueAdding) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final book = await ref.read(bookManagementProvider.notifier).createBook(
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
        coverUrl: null,
        isPublished: _isPublished,
        isFree: _isFree,
      );

      if (book != null) {
        // Invalidate providers to refresh data
        ref.invalidate(booksProvider);
        ref.invalidate(bookStatisticsProvider);
        ref.invalidate(recentBooksProvider);
        ref.invalidate(pendingBooksProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('書籍《${book.title}》新增成功！'),
            backgroundColor: Colors.green,
          ),
        );

        if (continueAdding) {
          // Clear form for next book
          _clearForm();
        } else {
          // Go back to books list
          context.push(Routes.adminBooks);
        }
      } else {
        throw Exception('書籍創建失敗');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('新增書籍失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _authorController.clear();
    _productCodeController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _filePathController.clear();
    
    setState(() {
      _selectedFileType = 'url';
      _isFree = true;
      _isPublished = false;
      _selectedCoverFile = null;
    });
  }
}