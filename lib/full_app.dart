import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/environment_service.dart';

// 簡化版本的模型類別 (不依賴 code generation)
class SimpleBook {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? fileUrl;
  final String filePath;
  final String fileType;
  final String? category;
  final bool isPublished;
  final double? averageRating;
  final int totalRatings;
  final DateTime createdAt;

  SimpleBook({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.fileUrl,
    required this.filePath,
    required this.fileType,
    this.category,
    this.isPublished = false,
    this.averageRating,
    this.totalRatings = 0,
    required this.createdAt,
  });

  factory SimpleBook.fromJson(Map<String, dynamic> json) {
    return SimpleBook(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      coverUrl: json['cover_url'],
      fileUrl: json['file_url'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      category: json['category'],
      isPublished: json['is_published'] ?? false,
      averageRating: json['average_rating']?.toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get fileTypeDisplay {
    switch (fileType.toLowerCase()) {
      case 'pdf': return 'PDF';
      case 'epub': return 'EPUB';
      case 'txt': return 'TXT';
      case 'mobi': return 'MOBI';
      case 'azw3': return 'AZW3';
      case 'url': return 'URL連結';
      default: return fileType.toUpperCase();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 載入環境變數
    await dotenv.load(fileName: '.env');
    
    // 驗證環境配置
    final envService = EnvironmentService.instance;
    if (!envService.validateConfiguration()) {
      throw Exception('環境配置驗證失敗');
    }
    
    // 初始化 Supabase
    await Supabase.initialize(
      url: envService.apiUrl,
      anonKey: envService.anonKey,
    );
    
    runApp(const ProviderScope(child: SoRFullApp()));
  } catch (e) {
    // 如果初始化失敗，運行離線版本
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Supabase 連線失敗', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text('錯誤: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class SoRFullApp extends StatelessWidget {
  const SoRFullApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoR書庫 完整版',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final EnvironmentService envService = EnvironmentService.instance;
  List<SimpleBook> books = [];
  bool isLoading = true;
  String? error;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadBooks();
  }

  Future<void> _checkAuth() async {
    currentUser = supabase.auth.currentUser;
    setState(() {});
  }

  Future<void> _loadBooks() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await supabase
          .from(envService.booksTable)
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      books = (response as List)
          .map((json) => SimpleBook.fromJson(json))
          .toList();

    } catch (e) {
      error = '載入書籍失敗: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
      _checkAuth();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登入失敗: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      setState(() {
        currentUser = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登出失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoR書庫 完整版'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          if (currentUser != null)
            IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              tooltip: '登出',
            )
          else
            IconButton(
              onPressed: _signInWithGoogle,
              icon: const Icon(Icons.login),
              tooltip: '使用 Google 登入',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 狀態指示器
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud,
                          color: error == null ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Supabase 連線狀態',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: envService.isDevelopment ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            envService.environmentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ 已連線', style: TextStyle(color: Colors.green)),
                          const SizedBox(height: 4),
                          Text(
                            '資料表: ${envService.booksTable}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          currentUser != null ? Icons.person : Icons.person_off,
                          color: currentUser != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentUser != null 
                              ? '已登入: ${currentUser!.email}' 
                              : '未登入',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 書籍列表標題
            Row(
              children: [
                Text(
                  '📚 書籍列表',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadBooks,
                  icon: const Icon(Icons.refresh),
                  tooltip: '重新載入',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 書籍列表內容
            Expanded(
              child: isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('載入中...'),
                        ],
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadBooks,
                                child: const Text('重試'),
                              ),
                            ],
                          ),
                        )
                      : books.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.book, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('暫無書籍資料'),
                                  SizedBox(height: 8),
                                  Text(
                                    '這可能是因為資料庫中還沒有資料，\n或者資料表名稱需要調整。',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF2563EB),
                                      child: Icon(
                                        _getFileTypeIcon(book.fileType),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(book.title),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('作者: ${book.author}'),
                                        Text('格式: ${book.fileTypeDisplay}'),
                                        if (book.category != null)
                                          Text('分類: ${book.category}'),
                                        if (book.averageRating != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.star, 
                                                size: 16, color: Colors.amber),
                                              Text(' ${book.averageRating!.toStringAsFixed(1)} (${book.totalRatings})'),
                                            ],
                                          ),
                                      ],
                                    ),
                                    trailing: Icon(
                                      book.isPublished 
                                          ? Icons.check_circle 
                                          : Icons.schedule,
                                      color: book.isPublished 
                                          ? Colors.green 
                                          : Colors.orange,
                                    ),
                                    onTap: () {
                                      _showBookDetails(book);
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBookDialog();
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'epub': return Icons.menu_book;
      case 'txt': return Icons.text_snippet;
      case 'mobi':
      case 'azw3': return Icons.import_contacts;
      case 'url': return Icons.link;
      default: return Icons.description;
    }
  }

  void _showBookDetails(SimpleBook book) {
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
            const SizedBox(height: 8),
            Text('狀態: ${book.isPublished ? "已發布" : "待審核"}'),
            const SizedBox(height: 8),
            Text('建立時間: ${book.createdAt.toString().split('.')[0]}'),
            if (book.fileType == 'url' && book.fileUrl != null) ...[
              const SizedBox(height: 8),
              Text('連結: ${book.fileUrl}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入才能新增書籍')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增書籍'),
        content: const Text(
          '完整的新增書籍功能需要更複雜的表單實作。\n'
          '這個示範版本主要展示 Supabase 連線和資料讀取功能。\n\n'
          '完整版本包含：\n'
          '• 檔案上傳功能\n'
          '• 表單驗證\n'
          '• 圖片處理\n'
          '• 權限控制',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }
}