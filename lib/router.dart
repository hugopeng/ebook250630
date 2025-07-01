import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/books/books_screen.dart';
import 'screens/books/book_detail_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/books_management_screen.dart';
import 'screens/admin/add_book_screen.dart';
import 'screens/admin/edit_book_screen.dart';
import 'screens/admin/users_management_screen.dart';
import 'screens/user/user_dashboard_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'widgets/responsive/scaffold_with_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isAdmin = ref.watch(isAdminProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    // Enable logging to debug route conflicts
    routerNeglect: false,
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;
      
      return authState.when(
        data: (auth) {
          final isLoggedIn = auth.session != null;
          
          // If not logged in and trying to access protected routes
          if (!isLoggedIn && location != '/login' && location != '/') {
            return '/login';
          }
          
          // If logged in and on login page, redirect to home
          if (isLoggedIn && location == '/login') {
            return '/';
          }
          
          // Admin route protection
          if (location.startsWith('/admin')) {
            return isAdmin.when(
              data: (adminStatus) => adminStatus ? null : '/',
              loading: () => '/',
              error: (_, __) => '/',
            );
          }
          
          return null;
        },
        loading: () => null,
        error: (_, __) => '/login',
      );
    },
    routes: [
      // Splash/Loading Route
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Main App with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNav(child: child);
        },
        routes: [
          // Books Routes
          GoRoute(
            path: '/books',
            builder: (context, state) => const BooksScreen(),
          ),
          GoRoute(
            path: '/books/:id',
            builder: (context, state) {
              final bookId = state.pathParameters['id']!;
              return BookDetailScreen(bookId: bookId);
            },
          ),
          
          // User Dashboard
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const UserDashboardScreen(),
          ),
          
          // Search
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          
          // User Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      
      // Admin Routes - Flat structure for compatibility
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/books',
        builder: (context, state) => const BooksManagementScreen(),
      ),
      GoRoute(
        path: '/admin/books/add',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('新增書籍')),
          body: const Center(
            child: Text('新增書籍頁面（測試）'),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/books/:id/edit',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return EditBookScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UsersManagementScreen(),
      ),
    ],
    
    // Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '頁面不存在',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('錯誤: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('回到首頁'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation Helper Extensions
extension GoRouterExtension on GoRouter {
  void pushAndClearStack(String location) {
    while (canPop()) {
      pop();
    }
    pushReplacement(location);
  }
}

// Route Names (for type safety)
class Routes {
  static const splash = '/';
  static const login = '/login';
  static const books = '/books';
  static const bookDetail = '/books/:id';
  static const userDashboard = '/dashboard';
  static const search = '/search';
  static const profile = '/profile';
  
  // Admin Routes
  static const adminDashboard = '/admin';
  static const adminBooks = '/admin/books';
  static const adminAddBook = '/admin/books/add';
  static const adminEditBook = '/admin/books/:id/edit';
  static const adminUsers = '/admin/users';
  
  // Helper methods
  static String bookDetailPath(String bookId) => '/books/$bookId';
  static String adminEditBookPath(String bookId) => '/admin/books/$bookId/edit';
}