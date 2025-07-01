import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'router.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    // Listen to auth state changes and auto-create user profile
    ref.listen(authStateProvider, (previous, next) {
      if (kDebugMode) {
        print('🔍 ===========================================');
        print('🔍 [APP.DART] 認證狀態變化檢測');
        print('  Previous State: ${previous?.value?.session != null ? "已登入" : "未登入"} (${previous?.value?.session?.user.email ?? "無"})');
        print('  Current State: ${next.value?.session != null ? "已登入" : "未登入"} (${next.value?.session?.user.email ?? "無"})');
        print('  HasError: ${next.hasError}');
        print('  IsLoading: ${next.isLoading}');
        if (next.hasError) {
          print('  Error: ${next.error}');
        }
      }
      
      next.when(
        data: (authState) async {
          final isLoggedIn = authState.session != null;
          final wasLoggedIn = previous?.value?.session != null;
          
          if (kDebugMode) {
            print('🔍 [APP.DART] 詳細狀態:');
            print('  當前登入狀態: $isLoggedIn');
            print('  之前登入狀態: $wasLoggedIn');
            print('  用戶ID: ${authState.session?.user.id ?? "無"}');
            print('  用戶Email: ${authState.session?.user.email ?? "無"}');
            print('  AuthState Event: ${authState.event}');
          }
          
          if (isLoggedIn && !wasLoggedIn) {
            // User just logged in
            if (kDebugMode) {
              print('🔍 [APP.DART] 檢測到用戶登入，自動觸發用戶資料創建...');
            }
            
            try {
              // Wait a moment for auth state to fully update
              await Future.delayed(const Duration(milliseconds: 500));
              final profile = await AuthService.instance.getCurrentUserProfile();
              
              if (kDebugMode) {
                print('🔍 [APP.DART] 用戶資料創建結果: ${profile != null ? "成功" : "失敗"}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ [APP.DART] 自動創建用戶資料失敗: $e');
              }
            }
          }
        },
        loading: () {
          if (kDebugMode) {
            print('🔍 [APP.DART] Auth state is loading...');
          }
        },
        error: (error, stackTrace) {
          if (kDebugMode) {
            print('❌ [APP.DART] Auth state error: $error');
          }
        },
      );
    });

    return MaterialApp.router(
      title: 'SoR書庫',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Blue primary
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(),
        
        // AppBar Theme
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          titleTextStyle: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        
        // Data Table Theme
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          headingTextStyle: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          dataTextStyle: GoogleFonts.notoSans(
            fontSize: 13,
          ),
        ),
      ),
      
      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
      ),
      
      // Router Configuration
      routerConfig: router,
      
      // Responsive Framework
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        );
      },
    );
  }
}