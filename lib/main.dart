import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'services/supabase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase
    await SupabaseService.instance.initialize();
    
    runApp(
      ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  '初始化失敗',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('錯誤: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('重試'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}