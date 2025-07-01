import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../models/user.dart' as app_user;
import '../../models/book.dart';
import '../../router.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final bookStats = ref.watch(bookStatisticsProvider);
    final recentBooks = ref.watch(recentBooksProvider({'limit': 5, 'adminView': true}));
    final pendingBooks = ref.watch(pendingBooksProvider(5));
    final usersCount = ref.watch(usersCountProvider({'search': null, 'status': 'all'}));
    
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理員儀表板'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              // Refresh all providers
              ref.invalidate(bookStatisticsProvider);
              ref.invalidate(recentBooksProvider);
              ref.invalidate(pendingBooksProvider);
              ref.invalidate(usersCountProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            userProfile.when(
              data: (user) => user != null
                  ? _WelcomeHeader(user: user)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 24),
            
            // Statistics Cards
            _StatisticsSection(
              bookStats: bookStats,
              usersCount: usersCount,
              isDesktop: isDesktop,
              isTablet: isTablet,
            ),
            
            const SizedBox(height: 32),
            
            // Recent Books and Pending Books
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RecentBooksSection(recentBooks: recentBooks),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _PendingBooksSection(pendingBooks: pendingBooks),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _RecentBooksSection(recentBooks: recentBooks),
                      const SizedBox(height: 24),
                      _PendingBooksSection(pendingBooks: pendingBooks),
                    ],
                  ),
            
            const SizedBox(height: 32),
            
            // Quick Actions
            _QuickActionsSection(isDesktop: isDesktop, isTablet: isTablet),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final app_user.User user;

  const _WelcomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.dashboard,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '管理員儀表板',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '歡迎，${user.username}！',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  final AsyncValue<Map<String, int>> bookStats;
  final AsyncValue<int> usersCount;
  final bool isDesktop;
  final bool isTablet;

  const _StatisticsSection({
    required this.bookStats,
    required this.usersCount,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        // Total Books Card
        bookStats.when(
          data: (stats) => _StatCard(
            title: '總書籍數',
            value: '${stats['total'] ?? 0}',
            icon: Icons.book,
            color: Colors.blue,
            footerText: '查看詳情',
            onTap: () => context.go(Routes.adminBooks),
          ),
          loading: () => const _StatCardLoading(
            title: '總書籍數',
            icon: Icons.book,
            color: Colors.blue,
          ),
          error: (_, __) => const _StatCardError(
            title: '總書籍數',
            icon: Icons.book,
            color: Colors.blue,
          ),
        ),
        
        // Published Books Card
        bookStats.when(
          data: (stats) => _StatCard(
            title: '已發布書籍',
            value: '${stats['published'] ?? 0}',
            icon: Icons.check_circle,
            color: Colors.green,
            footerText: '查看詳情',
            onTap: () => context.go('${Routes.adminBooks}?status=published'),
          ),
          loading: () => const _StatCardLoading(
            title: '已發布書籍',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          error: (_, __) => const _StatCardError(
            title: '已發布書籍',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        
        // Pending Books Card
        bookStats.when(
          data: (stats) => _StatCard(
            title: '待審核書籍',
            value: '${stats['pending'] ?? 0}',
            icon: Icons.schedule,
            color: Colors.orange,
            footerText: '查看詳情',
            onTap: () => context.go('${Routes.adminBooks}?status=pending'),
          ),
          loading: () => const _StatCardLoading(
            title: '待審核書籍',
            icon: Icons.schedule,
            color: Colors.orange,
          ),
          error: (_, __) => const _StatCardError(
            title: '待審核書籍',
            icon: Icons.schedule,
            color: Colors.orange,
          ),
        ),
        
        // Total Users Card
        usersCount.when(
          data: (count) => _StatCard(
            title: '總用戶數',
            value: '$count',
            icon: Icons.people,
            color: Colors.indigo,
            footerText: '用戶管理',
            onTap: () => context.go(Routes.adminUsers),
          ),
          loading: () {
            if (kDebugMode) {
              print('🔄 Users count is still loading...');
            }
            return const _StatCardLoading(
              title: '總用戶數',
              icon: Icons.people,
              color: Colors.indigo,
            );
          },
          error: (error, stackTrace) {
            if (kDebugMode) {
              print('❌ Users count error: $error');
              print('Stack trace: $stackTrace');
            }
            return const _StatCardError(
              title: '總用戶數',
              icon: Icons.people,
              color: Colors.indigo,
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String footerText;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.footerText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          footerText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCardLoading extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _StatCardLoading({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.7), color.withOpacity(0.5)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

class _StatCardError extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _StatCardError({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade400, Colors.grey.shade300],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _RecentBooksSection extends StatelessWidget {
  final AsyncValue<List<Book>> recentBooks;

  const _RecentBooksSection({required this.recentBooks});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.book, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '最近新增的書籍',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Container(
            padding: const EdgeInsets.all(16),
            child: recentBooks.when(
              data: (books) => books.isNotEmpty
                  ? Column(
                      children: [
                        ...books.map((book) => _BookListItem(book: book)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go(Routes.adminBooks),
                            child: const Text('查看全部書籍'),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '暫無書籍',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '載入失敗',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBooksSection extends StatelessWidget {
  final AsyncValue<List<Book>> pendingBooks;

  const _PendingBooksSection({required this.pendingBooks});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '待審核書籍',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Container(
            padding: const EdgeInsets.all(16),
            child: pendingBooks.when(
              data: (books) => books.isNotEmpty
                  ? Column(
                      children: [
                        ...books.map((book) => _PendingBookItem(book: book)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('${Routes.adminBooks}?status=pending'),
                            child: const Text('查看全部待審核'),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '無待審核書籍',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '載入失敗',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  final Book book;

  const _BookListItem({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.createdAt.toString().split(' ')[0],
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: book.isPublished ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              book.statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBookItem extends StatelessWidget {
  final Book book;

  const _PendingBookItem({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.createdAt.toString().split(' ')[0],
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.go(Routes.adminEditBookPath(book.id)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text(
              '審核',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;

  const _QuickActionsSection({
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    final actions = [
      {
        'title': '新增書籍',
        'icon': Icons.add,
        'color': Colors.blue,
        'onTap': () => context.go(Routes.adminAddBook),
      },
      {
        'title': '管理書籍',
        'icon': Icons.list,
        'color': Colors.blue.shade300,
        'onTap': () => context.go(Routes.adminBooks),
      },
      {
        'title': '審核書籍',
        'icon': Icons.schedule,
        'color': Colors.orange,
        'onTap': () => context.go('${Routes.adminBooks}?status=pending'),
      },
      {
        'title': '用戶管理',
        'icon': Icons.people,
        'color': Colors.indigo,
        'onTap': () => context.go(Routes.adminUsers),
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.build, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '快速操作',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
              children: actions.map((action) => 
                _QuickActionButton(
                  title: action['title'] as String,
                  icon: action['icon'] as IconData,
                  color: action['color'] as Color,
                  onTap: action['onTap'] as VoidCallback,
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}