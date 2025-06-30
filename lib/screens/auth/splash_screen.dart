import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait a bit for the splash screen effect
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    final authState = ref.read(authStateProvider);
    
    authState.when(
      data: (auth) {
        if (auth.session != null) {
          // User is logged in, go to books
          context.go('/books');
        } else {
          // User is not logged in, go to login
          context.go('/login');
        }
      },
      loading: () {
        // Still loading, stay on splash
      },
      error: (_, __) {
        // Error, go to login
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_book,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              'SoR書庫',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App Description
            Text(
              '現代化電子書閱讀平台',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading Indicator
            authState.when(
              data: (_) => const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              loading: () => const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              error: (error, _) => Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '載入失敗',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('重試'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}