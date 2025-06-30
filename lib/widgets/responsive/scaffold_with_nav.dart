import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart' as app_user;
import '../../router.dart';

class ScaffoldWithNav extends ConsumerWidget {
  final Widget child;
  final bool isAdmin;

  const ScaffoldWithNav({
    super.key,
    required this.child,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    
    if (isDesktop || isTablet) {
      return _DesktopLayout(
        child: child,
        isAdmin: isAdmin,
        userProfile: userProfile,
      );
    } else {
      return _MobileLayout(
        child: child,
        isAdmin: isAdmin,
        userProfile: userProfile,
      );
    }
  }
}

class _DesktopLayout extends ConsumerWidget {
  final Widget child;
  final bool isAdmin;
  final AsyncValue<app_user.User?> userProfile;

  const _DesktopLayout({
    required this.child,
    required this.isAdmin,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _Sidebar(isAdmin: isAdmin, userProfile: userProfile),
          ),
          // Main Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final bool isAdmin;
  final AsyncValue<app_user.User?> userProfile;

  const _MobileLayout({
    required this.child,
    required this.isAdmin,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoR書庫'),
        actions: [
          userProfile.when(
            data: (user) => user != null
                ? PopupMenuButton<String>(
                    icon: CircleAvatar(
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(user.username?.substring(0, 1).toUpperCase() ?? 'U')
                          : null,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'profile':
                          context.push('/dashboard');
                          break;
                        case 'admin':
                          if (user.isAdmin) {
                            context.push('/admin');
                          }
                          break;
                        case 'logout':
                          ref.read(authNotifierProvider.notifier).signOut();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: ListTile(
                          leading: Icon(Icons.person),
                          title: Text('個人資料'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (user.isAdmin)
                        const PopupMenuItem(
                          value: 'admin',
                          child: ListTile(
                            leading: Icon(Icons.admin_panel_settings),
                            title: Text('管理後台'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('登出'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.login),
                    onPressed: () => context.push('/login'),
                  ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.error),
              onPressed: () => context.push('/login'),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: _BottomNavigation(isAdmin: isAdmin),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final bool isAdmin;
  final AsyncValue<app_user.User?> userProfile;

  const _Sidebar({
    required this.isAdmin,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.path;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'SoR書庫',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '管理後台',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: isAdmin ? _adminNavItems(currentLocation) : _userNavItems(currentLocation),
          ),
        ),
        
        // User Profile Section
        const Divider(),
        userProfile.when(
          data: (user) => user != null
              ? _UserProfileSection(user: user)
              : _LoginSection(),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => _LoginSection(),
        ),
      ],
    );
  }

  List<Widget> _userNavItems(String currentLocation) {
    return [
      _NavItem(
        icon: Icons.library_books,
        label: '書籍瀏覽',
        path: Routes.books,
        isSelected: currentLocation.startsWith('/books'),
      ),
      _NavItem(
        icon: Icons.dashboard,
        label: '個人儀表板',
        path: Routes.userDashboard,
        isSelected: currentLocation == '/dashboard',
      ),
    ];
  }

  List<Widget> _adminNavItems(String currentLocation) {
    return [
      _NavItem(
        icon: Icons.dashboard,
        label: '管理員儀表板',
        path: Routes.adminDashboard,
        isSelected: currentLocation == '/admin',
      ),
      _NavItem(
        icon: Icons.library_books,
        label: '書籍管理',
        path: Routes.adminBooks,
        isSelected: currentLocation.startsWith('/admin/books'),
      ),
      _NavItem(
        icon: Icons.people,
        label: '用戶管理',
        path: Routes.adminUsers,
        isSelected: currentLocation.startsWith('/admin/users'),
      ),
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
      _NavItem(
        icon: Icons.public,
        label: '回到用戶介面',
        path: Routes.books,
        isSelected: false,
      ),
    ];
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isSelected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => context.go(path),
      ),
    );
  }
}

class _UserProfileSection extends ConsumerWidget {
  final app_user.User user;

  const _UserProfileSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            user.username ?? 'Unknown User',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (user.isAdmin)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '管理員',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('登出'),
              onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginSection extends StatelessWidget {
  const _LoginSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('登入'),
          onPressed: () => context.push('/login'),
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final bool isAdmin;

  const _BottomNavigation({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    
    if (isAdmin) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getAdminSelectedIndex(currentLocation),
        onTap: (index) => _onAdminItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '儀表板',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: '書籍管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '用戶管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: '用戶介面',
          ),
        ],
      );
    }

    return BottomNavigationBar(
      currentIndex: _getUserSelectedIndex(currentLocation),
      onTap: (index) => _onUserItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: '書籍',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: '儀表板',
        ),
      ],
    );
  }

  int _getUserSelectedIndex(String location) {
    if (location.startsWith('/books')) return 0;
    if (location == '/dashboard') return 1;
    return 0;
  }

  int _getAdminSelectedIndex(String location) {
    if (location == '/admin') return 0;
    if (location.startsWith('/admin/books')) return 1;
    if (location.startsWith('/admin/users')) return 2;
    return 0;
  }

  void _onUserItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.books);
        break;
      case 1:
        context.go(Routes.userDashboard);
        break;
    }
  }

  void _onAdminItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.adminDashboard);
        break;
      case 1:
        context.go(Routes.adminBooks);
        break;
      case 2:
        context.go(Routes.adminUsers);
        break;
      case 3:
        context.go(Routes.books);
        break;
    }
  }
}