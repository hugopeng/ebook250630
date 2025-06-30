import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import '../../models/reading_history.dart';
import '../../providers/reading_history_provider.dart';
import '../../constants/app_constants.dart';

class EPUBReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final String? epubUrl;
  final File? epubFile;

  const EPUBReaderScreen({
    super.key,
    required this.book,
    this.epubUrl,
    this.epubFile,
  });

  @override
  ConsumerState<EPUBReaderScreen> createState() => _EPUBReaderScreenState();
}

class _EPUBReaderScreenState extends ConsumerState<EPUBReaderScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;
  EpubBook? _epubBook;
  File? _localFile;
  
  int _currentChapter = 0;
  List<EpubChapter> _chapters = [];
  bool _isFullScreen = false;
  bool _showControls = true;
  
  // 閱讀設定
  bool _nightMode = false;
  double _fontSize = 16.0;
  String _fontFamily = 'Default';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _initializeEPUB();
    _loadReadingProgress();
  }

  @override
  void dispose() {
    _saveReadingProgress();
    super.dispose();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
  }

  Future<void> _initializeEPUB() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (widget.epubFile != null) {
        _localFile = widget.epubFile;
      } else if (widget.epubUrl != null) {
        _localFile = await _downloadEPUB();
      } else {
        throw Exception('沒有提供EPUB文件或URL');
      }

      // 解析EPUB
      final bytes = await _localFile!.readAsBytes();
      _epubBook = await EpubReader.readBook(bytes);
      
      if (_epubBook == null) {
        throw Exception('無法解析EPUB文件');
      }

      // 獲取章節列表
      _chapters = _epubBook!.Chapters?.toList() ?? [];
      
      if (_chapters.isNotEmpty) {
        await _loadChapter(_currentChapter);
      } else {
        throw Exception('EPUB文件沒有章節內容');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<File> _downloadEPUB() async {
    try {
      final response = await http.get(Uri.parse(widget.epubUrl!));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.book.id}.epub');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('下載EPUB失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('下載EPUB失敗: $e');
    }
  }

  Future<void> _loadChapter(int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= _chapters.length) return;

    try {
      final chapter = _chapters[chapterIndex];
      String content = chapter.HtmlContent ?? '';
      
      // 添加基本的CSS樣式
      final html = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: ${_fontFamily == 'Default' ? 'system-ui, -apple-system' : _fontFamily};
              font-size: ${_fontSize}px;
              line-height: 1.6;
              margin: 16px;
              padding: 0;
              background-color: ${_nightMode ? '#1a1a1a' : '#ffffff'};
              color: ${_nightMode ? '#e0e0e0' : '#333333'};
              text-align: justify;
            }
            
            h1, h2, h3, h4, h5, h6 {
              color: ${_nightMode ? '#ffffff' : '#000000'};
              margin-top: 24px;
              margin-bottom: 16px;
            }
            
            p {
              margin-bottom: 12px;
            }
            
            img {
              max-width: 100%;
              height: auto;
            }
            
            a {
              color: ${_nightMode ? '#4da6ff' : '#2563eb'};
            }
            
            .chapter-title {
              font-size: 24px;
              font-weight: bold;
              text-align: center;
              margin-bottom: 32px;
              border-bottom: 2px solid ${_nightMode ? '#333' : '#eee'};
              padding-bottom: 16px;
            }
          </style>
        </head>
        <body>
          <div class="chapter-title">${chapter.Title ?? '第 ${chapterIndex + 1} 章'}</div>
          $content
        </body>
        </html>
      ''';

      await _webViewController.loadHtmlString(html);
      
      setState(() {
        _currentChapter = chapterIndex;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = '載入章節失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReadingProgress() async {
    try {
      final history = await ref
          .read(readingHistoryNotifierProvider.notifier)
          .getReadingHistory(widget.book.id);
      
      if (history != null && history.currentPage > 0) {
        final chapterIndex = (history.currentPage - 1).clamp(0, _chapters.length - 1);
        await _loadChapter(chapterIndex);
      }
    } catch (e) {
      // 忽略載入歷史錯誤
    }
  }

  Future<void> _saveReadingProgress() async {
    try {
      if (_chapters.isNotEmpty) {
        final progress = (_currentChapter + 1) / _chapters.length;
        await ref
            .read(readingHistoryNotifierProvider.notifier)
            .updateReadingProgress(
              widget.book.id,
              _currentChapter + 1,
              progress,
            );
      }
    } catch (e) {
      // 忽略保存錯誤
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _goToPreviousChapter() {
    if (_currentChapter > 0) {
      _loadChapter(_currentChapter - 1);
    }
  }

  void _goToNextChapter() {
    if (_currentChapter < _chapters.length - 1) {
      _loadChapter(_currentChapter + 1);
    }
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '章節目錄',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  final isCurrentChapter = index == _currentChapter;
                  
                  return ListTile(
                    title: Text(
                      chapter.Title ?? '第 ${index + 1} 章',
                      style: TextStyle(
                        fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentChapter ? AppConstants.primaryColor : null,
                      ),
                    ),
                    leading: isCurrentChapter 
                        ? Icon(Icons.play_arrow, color: AppConstants.primaryColor)
                        : Text('${index + 1}'),
                    onTap: () {
                      Navigator.pop(context);
                      _loadChapter(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '閱讀設定',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 夜間模式
            SwitchListTile(
              title: const Text('夜間模式'),
              value: _nightMode,
              onChanged: (value) {
                setState(() {
                  _nightMode = value;
                });
                _loadChapter(_currentChapter); // 重新載入以應用新樣式
                Navigator.pop(context);
              },
            ),
            
            // 字體大小
            ListTile(
              title: const Text('字體大小'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _fontSize > 12 ? () {
                      setState(() {
                        _fontSize = _fontSize - 2;
                      });
                      _loadChapter(_currentChapter);
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('${_fontSize.toInt()}'),
                  IconButton(
                    onPressed: _fontSize < 24 ? () {
                      setState(() {
                        _fontSize = _fontSize + 2;
                      });
                      _loadChapter(_currentChapter);
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            
            // 字體家族
            ListTile(
              title: const Text('字體'),
              trailing: DropdownButton<String>(
                value: _fontFamily,
                items: const [
                  DropdownMenuItem(value: 'Default', child: Text('預設')),
                  DropdownMenuItem(value: 'serif', child: Text('襯線體')),
                  DropdownMenuItem(value: 'sans-serif', child: Text('無襯線體')),
                  DropdownMenuItem(value: 'monospace', child: Text('等寬字體')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _fontFamily = value;
                    });
                    _loadChapter(_currentChapter);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _nightMode ? Colors.black : Colors.white,
      appBar: _isFullScreen || !_showControls ? null : AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showChapterList,
            icon: const Icon(Icons.list),
          ),
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: _toggleFullScreen,
            icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isFullScreen || !_showControls 
          ? null 
          : _buildBottomControls(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('載入EPUB中...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('載入失敗: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeEPUB,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: WebViewWidget(controller: _webViewController),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentChapter > 0 ? _goToPreviousChapter : null,
            icon: const Icon(Icons.chevron_left),
          ),
          
          Expanded(
            child: GestureDetector(
              onTap: _showChapterList,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '第 ${_currentChapter + 1} 章 / 共 ${_chapters.length} 章',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          IconButton(
            onPressed: _currentChapter < _chapters.length - 1 ? _goToNextChapter : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}