import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart' as app_user;
import '../../router.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider({
      'search': _searchController.text.isEmpty ? null : _searchController.text,
      'status': _statusFilter == 'all' ? null : _statusFilter,
      'limit': _itemsPerPage,
      'offset': (_currentPage - 1) * _itemsPerPage,
    }));
    
    final usersCountAsync = ref.watch(usersCountProvider({
      'search': _searchController.text.isEmpty ? null : _searchController.text,
      'status': _statusFilter == 'all' ? null : _statusFilter,
    }));

    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.people),
            const SizedBox(width: 8),
            const Text('用戶管理'),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.adminDashboard),
            icon: const Icon(Icons.arrow_back),
            label: const Text('回到儀表板'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '用戶管理',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '管理平台用戶和權限',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search and Filter Section
          _buildSearchAndFilterSection(),
          
          // Statistics Cards
          _buildStatisticsSection(usersAsync),
          
          // Users Table
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table Header
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
                        const Icon(Icons.list, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '用戶列表',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(搜尋: "${_searchController.text}")',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Table Content
                  Expanded(
                    child: usersAsync.when(
                      data: (users) => users.isNotEmpty
                          ? isDesktop
                              ? _UsersDataTable(users: users)
                              : _MobileUsersList(users: users)
                          : _EmptyState(
                              hasSearch: _searchController.text.isNotEmpty || 
                                        _statusFilter != 'all',
                            ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => _ErrorState(
                        error: error,
                        onRetry: () => ref.invalidate(usersProvider),
                      ),
                    ),
                  ),
                  
                  // Pagination
                  usersCountAsync.when(
                    data: (totalCount) => totalCount > _itemsPerPage
                        ? _PaginationSection(
                            currentPage: _currentPage,
                            totalItems: totalCount,
                            itemsPerPage: _itemsPerPage,
                            onPageChanged: (page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: usersCountAsync.when(
                              data: (count) => Text(
                                '共 $count 項用戶',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Search Field
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: '搜尋用戶',
                  hintText: '用戶名或電子郵件',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _currentPage = 1; // Reset to first page when searching
                  });
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Status Filter
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(
                  labelText: '狀態篩選',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('全部用戶')),
                  DropdownMenuItem(value: 'active', child: Text('啟用用戶')),
                  DropdownMenuItem(value: 'inactive', child: Text('停用用戶')),
                  DropdownMenuItem(value: 'admin', child: Text('管理員')),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value!;
                    _currentPage = 1; // Reset to first page when filtering
                  });
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                // Trigger rebuild with current search/filter
                setState(() {});
              },
              icon: const Icon(Icons.search),
              label: const Text('搜尋'),
            ),
            
            const SizedBox(width: 8),
            
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _statusFilter = 'all';
                  _currentPage = 1;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('清除'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(AsyncValue<List<app_user.User>> usersAsync) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: usersAsync.when(
        data: (users) {
          final totalUsers = users.length;
          final activeUsers = users.where((u) => u.isActive).length;
          final inactiveUsers = users.where((u) => !u.isActive).length;
          final adminUsers = users.where((u) => u.isAdmin).length;

          return Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: '總用戶數',
                  value: '$totalUsers',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: '啟用用戶',
                  value: '$activeUsers',
                  icon: Icons.person_check,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: '停用用戶',
                  value: '$inactiveUsers',
                  icon: Icons.person_off,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: '管理員',
                  value: '$adminUsers',
                  icon: Icons.admin_panel_settings,
                  color: Colors.red,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersDataTable extends ConsumerWidget {
  final List<app_user.User> users;

  const _UsersDataTable({required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 1000,
      columns: const [
        DataColumn2(
          label: Text('ID'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('用戶名'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('電子郵件'),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('狀態'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('權限'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('創建時間'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('最後更新'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('操作'),
          size: ColumnSize.L,
        ),
      ],
      rows: users.map((user) => DataRow2(
        cells: [
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.id.length > 8 ? user.id.substring(0, 8) : user.id,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              children: [
                Text(
                  user.username ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (user.isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text(
                          '管理員',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          DataCell(Text(user.email ?? 'No email')),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isActive ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    user.isActive ? '啟用' : '停用',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.isAdmin ? Colors.red : Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    user.isAdmin ? '管理員' : '一般用戶',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          DataCell(
            Text(
              user.createdAt?.toString().split(' ')[0] ?? '未知',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          DataCell(
            Text(
              user.updatedAt?.toString().split(' ')[0] ?? '-',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          DataCell(
            user.id != currentUser?.id
                ? _UserActionsMenu(user: user)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '當前用戶',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      )).toList(),
    );
  }
}

class _MobileUsersList extends StatelessWidget {
  final List<app_user.User> users;

  const _MobileUsersList({required this.users});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(user.username?.substring(0, 1).toUpperCase() ?? 'U')
                  : null,
            ),
            title: Row(
              children: [
                Text(
                  user.username ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (user.isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '管理員',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email ?? 'No email'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.isActive ? '啟用' : '停用',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isAdmin ? Colors.red : Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.isAdmin ? '管理員' : '一般用戶',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: _UserActionsMenu(user: user),
          ),
        );
      },
    );
  }
}

class _UserActionsMenu extends ConsumerWidget {
  final app_user.User user;

  const _UserActionsMenu({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'toggle_status':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(user.isActive ? '停用用戶' : '啟用用戶'),
                content: Text(
                  '確定要${user.isActive ? '停用' : '啟用'}用戶「${user.username}」嗎？',
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
              await ref.read(userManagementProvider.notifier).toggleUserStatus(user.id);
              ref.invalidate(usersProvider);
            }
            break;
          case 'toggle_admin':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(user.isAdmin ? '移除管理員權限' : '授予管理員權限'),
                content: Text(
                  '確定要${user.isAdmin ? '移除' : '授予'}用戶「${user.username}」的管理員權限嗎？',
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
              await ref.read(userManagementProvider.notifier).toggleAdminStatus(user.id);
              ref.invalidate(usersProvider);
            }
            break;
          case 'reset_password':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('密碼重置功能開發中...')),
            );
            break;
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('刪除用戶'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('警告：此操作將永久刪除用戶「${user.username}」及其所有相關數據，無法恢復！'),
                    const SizedBox(height: 8),
                    const Text(
                      '確定要繼續嗎？',
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
              await ref.read(userManagementProvider.notifier).deleteUser(user.id);
              ref.invalidate(usersProvider);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('用戶「${user.username}」已刪除'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle_status',
          child: ListTile(
            leading: Icon(user.isActive ? Icons.person_off : Icons.person_add),
            title: Text(user.isActive ? '停用' : '啟用'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'toggle_admin',
          child: ListTile(
            leading: Icon(user.isAdmin ? Icons.person_remove : Icons.admin_panel_settings),
            title: Text(user.isAdmin ? '移除管理員' : '授予管理員'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'reset_password',
          child: ListTile(
            leading: Icon(Icons.key),
            title: Text('重置密碼'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('刪除用戶', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _PaginationSection extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChanged;

  const _PaginationSection({
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / itemsPerPage).ceil();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Text(
            '顯示第 ${(currentPage - 1) * itemsPerPage + 1} 到 '
            '${(currentPage * itemsPerPage).clamp(0, totalItems)} 項， '
            '共 $totalItems 項用戶',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Row(
            children: [
              TextButton.icon(
                onPressed: currentPage > 1 
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('上一頁'),
              ),
              Text(' $currentPage / $totalPages '),
              TextButton.icon(
                onPressed: currentPage < totalPages 
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('下一頁'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? '沒有找到用戶' : '暫無用戶',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch ? '嘗試調整搜尋條件或清除篩選' : '等待用戶註冊',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
            onPressed: onRetry,
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }
}