import 'package:flutter/material.dart';

void main() {
  runApp(const SoRTestApp());
}

class SoRTestApp extends StatelessWidget {
  const SoRTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoR書庫 功能測試',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedFormat = 'pdf';
  String _selectedCategory = '文學小說';

  final List<String> _formats = ['pdf', 'epub', 'txt', 'mobi', 'azw3', 'url'];
  final List<String> _categories = [
    '文學小說', '商業理財', '心理勵志', '醫療保健', '藝術設計',
    '人文史地', '社會科學', '自然科普', '電腦資訊', '語言學習',
    '考試用書', '童書', '輕小說', '漫畫', '其他'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoR書庫 功能測試'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Text(
              '📚 SoR書庫電子書平台',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '支援多種書籍格式，包含 URL 連結',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // 表單
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 書名輸入
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '書名',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入書名';
                        }
                        if (value.length > 200) {
                          return '書名不能超過 200 個字元';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 格式選擇
                    DropdownButtonFormField<String>(
                      value: _selectedFormat,
                      decoration: const InputDecoration(
                        labelText: '檔案格式',
                        prefixIcon: Icon(Icons.file_present),
                        border: OutlineInputBorder(),
                      ),
                      items: _formats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Row(
                            children: [
                              Icon(_getFormatIcon(format)),
                              const SizedBox(width: 8),
                              Text(format.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFormat = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 分類選擇
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: '分類',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // URL 輸入 (當格式為 url 時顯示)
                    if (_selectedFormat == 'url') ...[
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '書籍網址',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/book',
                        ),
                        validator: (value) {
                          if (_selectedFormat == 'url') {
                            if (value == null || value.trim().isEmpty) {
                              return '請輸入網址';
                            }
                            if (!RegExp(r'^https?:\/\/.+').hasMatch(value)) {
                              return '請輸入有效的網址格式';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Spacer(),

                    // 按鈕
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _validateForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('驗證表單'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _showFeatures,
                          child: const Text('顯示支援功能'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _testUrlFeatures,
                          child: const Text('測試 URL 功能'),
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

  void _validateForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        '書名': _titleController.text,
        '格式': _selectedFormat.toUpperCase(),
        '分類': _selectedCategory,
        if (_selectedFormat == 'url') '網址': _urlController.text,
      };

      _showDialog(
        title: '✅ 表單驗證成功',
        content: '書籍資料：\n${data.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
      );
    }
  }

  void _showFeatures() {
    const features = [
      '📱 響應式設計 (手機/平板/桌面)',
      '🔐 用戶認證與權限管理',
      '📚 多格式書籍支援',
      '🔗 URL 連結書籍',
      '⭐ 評分與評論系統',
      '🎯 分類與搜尋功能',
      '📊 管理員後台',
      '☁️ Supabase 雲端後端',
      '🎨 Material Design 3',
    ];

    _showDialog(
      title: '🚀 SoR書庫功能特色',
      content: features.join('\n'),
    );
  }

  void _testUrlFeatures() {
    const testUrl = 'https://example.com/sample-book';
    
    // 簡單的 URL 驗證
    final isValid = RegExp(r'^https?:\/\/.+').hasMatch(testUrl);
    final domain = Uri.tryParse(testUrl)?.host ?? '無法解析';
    
    final results = [
      'URL 驗證: ${isValid ? '✅ 有效' : '❌ 無效'}',
      '測試網址: $testUrl',
      '網域: $domain',
      '格式: URL 連結書籍',
      '支援功能: 在瀏覽器開啟、複製連結',
    ];

    _showDialog(
      title: '🔗 URL 功能測試',
      content: results.join('\n'),
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
    _urlController.dispose();
    super.dispose();
  }
}