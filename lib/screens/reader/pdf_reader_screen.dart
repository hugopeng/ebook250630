import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import '../../models/reading_history.dart';
import '../../providers/reading_history_provider.dart';
import '../../constants/app_constants.dart';

class PDFReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final String? pdfUrl;
  final File? pdfFile;

  const PDFReaderScreen({
    super.key,
    required this.book,
    this.pdfUrl,
    this.pdfFile,
  });

  @override
  ConsumerState<PDFReaderScreen> createState() => _PDFReaderScreenState();
}

class _PDFReaderScreenState extends ConsumerState<PDFReaderScreen> {
  late PdfViewerController _pdfViewerController;
  bool _isLoading = true;
  String? _error;
  File? _localFile;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isFullScreen = false;
  bool _showControls = true;
  double _zoomLevel = 1.0;
  
  // 閱讀設定
  bool _nightMode = false;
  double _brightness = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _initializePDF();
    _loadReadingProgress();
  }

  @override
  void dispose() {
    _saveReadingProgress();
    super.dispose();
  }

  Future<void> _initializePDF() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (widget.pdfFile != null) {
        _localFile = widget.pdfFile;
      } else if (widget.pdfUrl != null) {
        _localFile = await _downloadPDF();
      } else {
        throw Exception('沒有提供PDF文件或URL');
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<File> _downloadPDF() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl!));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.book.id}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('下載PDF失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('下載PDF失敗: $e');
    }
  }

  Future<void> _loadReadingProgress() async {
    try {
      final history = await ref
          .read(readingHistoryNotifierProvider.notifier)
          .getReadingHistory(widget.book.id);
      
      if (history != null && history.currentPage > 0) {
        // 延遲導航到上次閱讀位置
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _pdfViewerController.jumpToPage(history.currentPage);
            setState(() {
              _currentPage = history.currentPage;
            });
          }
        });
      }
    } catch (e) {
      // 忽略載入歷史錯誤
    }
  }

  Future<void> _saveReadingProgress() async {
    try {
      if (_totalPages > 0) {
        final progress = _currentPage / _totalPages;
        await ref
            .read(readingHistoryNotifierProvider.notifier)
            .updateReadingProgress(
              widget.book.id,
              _currentPage,
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

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _showPageNavigator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳轉到指定頁面'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('當前頁面: $_currentPage / $_totalPages'),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '頁碼',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page >= 1 && page <= _totalPages) {
                  _pdfViewerController.jumpToPage(page);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
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
            SwitchListTile(
              title: const Text('夜間模式'),
              value: _nightMode,
              onChanged: (value) {
                setState(() {
                  _nightMode = value;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('亮度'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _brightness,
                  onChanged: (value) {
                    setState(() {
                      _brightness = value;
                    });
                  },
                  min: 0.1,
                  max: 1.0,
                ),
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
            Text('載入PDF中...'),
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
              onPressed: _initializePDF,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_localFile == null) {
      return const Center(
        child: Text('PDF文件不存在'),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: _nightMode ? Colors.black : Colors.white,
        child: Opacity(
          opacity: _brightness,
          child: SfPdfViewer.file(
            _localFile!,
            controller: _pdfViewerController,
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
              _saveReadingProgress();
            },
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
              });
            },
          ),
        ),
      ),
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
            onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          
          Expanded(
            child: GestureDetector(
              onTap: _showPageNavigator,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
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
            onPressed: _currentPage < _totalPages ? _goToNextPage : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}