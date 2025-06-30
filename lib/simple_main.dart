import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'utils/validation_utils.dart';
import 'utils/url_utils.dart';
import 'widgets/forms/custom_text_field.dart';
import 'widgets/forms/custom_dropdown.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
      ),
      home: const DemoScreen(),
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _urlController = TextEditingController();
  String? _selectedCategory;
  String? _selectedFormat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📚 ${AppConstants.appDescription}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppConstants.spacingL),
              
              Text(
                '🎯 新增書籍示範',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // 書名輸入
              CustomTextField(
                label: '書名',
                controller: _titleController,
                validator: ValidationUtils.validateBookTitle,
                prefixIcon: const Icon(Icons.book),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // 作者輸入
              CustomTextField(
                label: '作者',
                controller: _authorController,
                validator: ValidationUtils.validateAuthor,
                prefixIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // 分類選擇
              CategoryDropdown(
                value: _selectedCategory,
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: ValidationUtils.validateCategory,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // 格式選擇
              BookFormatDropdown(
                value: _selectedFormat,
                onChanged: (value) => setState(() => _selectedFormat = value),
                validator: (value) => value == null ? '請選擇格式' : null,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // URL 輸入（當選擇 URL 格式時）
              if (_selectedFormat == 'url') ...[
                UrlTextField(
                  label: '書籍網址',
                  controller: _urlController,
                  validator: ValidationUtils.validateUrl,
                ),
                const SizedBox(height: AppConstants.spacingM),
              ],
              
              const Spacer(),
              
              // 提交按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                  ),
                  child: const Text('驗證表單'),
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // 功能測試按鈕
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _testUrlUtils,
                      child: const Text('測試 URL 工具'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showConstants,
                      child: const Text('顯示常數'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final bookData = {
        'title': _titleController.text,
        'author': _authorController.text,
        'category': _selectedCategory,
        'format': _selectedFormat,
        if (_selectedFormat == 'url') 'url': _urlController.text,
      };
      
      _showDialog(
        title: '✅ 表單驗證成功',
        content: '書籍資料：\n${bookData.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
      );
    } else {
      _showDialog(
        title: '❌ 表單驗證失敗',
        content: '請檢查輸入的資料是否正確',
      );
    }
  }

  void _testUrlUtils() {
    const testUrl = 'https://example.com/book';
    
    final results = [
      'URL 驗證: ${UrlUtils.isValidUrl(testUrl) ? '✅ 有效' : '❌ 無效'}',
      'URL 類型: ${UrlUtils.getUrlType(testUrl)}',
      'URL 網域: ${UrlUtils.getDomain(testUrl) ?? '無法取得'}',
      '格式化顯示: ${UrlUtils.formatUrlForDisplay(testUrl, maxLength: 30)}',
    ];
    
    _showDialog(
      title: '🔗 URL 工具測試結果',
      content: results.join('\n'),
    );
  }

  void _showConstants() {
    final constants = [
      '應用程式名稱: ${AppConstants.appName}',
      '版本: ${AppConstants.appVersion}',
      '支援的書籍格式: ${AppConstants.allowedBookFormats.join(', ')}',
      '支援的圖片格式: ${AppConstants.allowedImageFormats.join(', ')}',
      '最大檔案大小: ${(AppConstants.maxFileSize / 1024 / 1024).toInt()}MB',
      '書籍分類數量: ${AppConstants.bookCategories.length}',
    ];
    
    _showDialog(
      title: '⚙️ 應用程式常數',
      content: constants.join('\n'),
    );
  }

  void _showDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}