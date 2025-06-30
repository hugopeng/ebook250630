import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

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
        cardTheme: CardTheme(
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