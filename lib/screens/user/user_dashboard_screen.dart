import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../models/user.dart' as app_user;
import '../../models/book.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final recentBooks = ref.watch(recentBooksProvider({'limit': 6}));
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人儀表板'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: userProfile.when(
        data: (user) => user != null
            ? SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _WelcomeSection(user: user),
                    
                    const SizedBox(height: 32),
                    
                    // Statistics Cards
                    _StatisticsSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Books
                    _RecentBooksSection(recentBooks: recentBooks),
                    
                    const SizedBox(height: 32),
                    
                    // Quick Actions
                    _QuickActionsSection(),
                  ],
                ),
              )
            : const Center(child: Text('請先登入')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '載入失敗',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final app_user.User user;

  const _WelcomeSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isDesktop
          ? Row(
              children: [
                _UserAvatar(user: user),
                const SizedBox(width: 24),
                Expanded(child: _WelcomeText(user: user)),
              ],
            )
          : Column(
              children: [
                _UserAvatar(user: user),
                const SizedBox(height: 16),
                _WelcomeText(user: user),
              ],
            ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final app_user.User user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundImage: user.avatarUrl != null
          ? NetworkImage(user.avatarUrl!)
          : null,
      child: user.avatarUrl == null
          ? Text(
              user.username?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

class _WelcomeText extends StatelessWidget {
  final app_user.User user;

  const _WelcomeText({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '歡迎回來，${user.username ?? 'User'}！',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '繼續您的閱讀之旅',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        if (user.isAdmin) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '管理員',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '閱讀統計',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: '已閱讀',
              value: '12',
              subtitle: '本書籍',
              icon: Icons.menu_book,
              color: Colors.blue,
            ),
            _StatCard(
              title: '閱讀時間',
              value: '24',
              subtitle: '小時',
              icon: Icons.schedule,
              color: Colors.green,
            ),
            _StatCard(
              title: '收藏',
              value: '8',
              subtitle: '本書籍',
              icon: Icons.bookmark,
              color: Colors.orange,
            ),
            _StatCard(
              title: '評分',
              value: '5',
              subtitle: '本書籍',
              icon: Icons.star,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '最近瀏覽',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all books
              },
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentBooks.when(
          data: (books) => books.isNotEmpty
              ? SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 16),
                        child: _BookTile(book: books[index]),
                      );
                    },
                  ),
                )
              : const Center(
                  child: Text('暫無最近瀏覽的書籍'),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('載入失敗')),
        ),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;

  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _DefaultBookCover(),
                    )
                  : _DefaultBookCover(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _DefaultBookCover() {
    return Center(
      child: Icon(
        Icons.menu_book,
        size: 32,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'title': '瀏覽書籍',
        'description': '探索更多精彩內容',
        'icon': Icons.library_books,
        'color': Colors.blue,
        'action': () {
          // TODO: Navigate to books
        },
      },
      {
        'title': '我的收藏',
        'description': '查看收藏的書籍',
        'icon': Icons.bookmark,
        'color': Colors.orange,
        'action': () {
          // TODO: Navigate to bookmarks
        },
      },
      {
        'title': '閱讀歷史',
        'description': '回顧閱讀記錄',
        'icon': Icons.history,
        'color': Colors.green,
        'action': () {
          // TODO: Navigate to reading history
        },
      },
      {
        'title': '個人設定',
        'description': '管理個人資料',
        'icon': Icons.settings,
        'color': Colors.grey,
        'action': () {
          // TODO: Navigate to settings
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速操作',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map(
          (action) => Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                ),
              ),
              title: Text(
                action['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(action['description'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: action['action'] as VoidCallback,
            ),
          ),
        ),
      ],
    );
  }
}