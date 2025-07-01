import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../providers/reading_history_provider.dart';
import '../../services/supabase_service.dart';
import '../../constants/app_constants.dart';
import '../../widgets/forms/custom_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  File? _selectedAvatar;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    // 延遲載入確保 context 完全初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
      _loadReadingStats();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      // 直接從 AuthService 取得當前用戶
      final authService = AuthService.instance;
      final currentUser = authService.currentUser;
      
      if (currentUser != null && mounted) {
        // 先顯示基本認證資訊
        setState(() {
          _usernameController.text = currentUser.userMetadata?['full_name'] ?? 
                                   currentUser.email?.split('@').first ?? 
                                   'User';
          _emailController.text = currentUser.email ?? '';
          _currentAvatarUrl = currentUser.userMetadata?['avatar_url'];
        });

        // 然後嘗試載入資料庫中的完整用戶資料
        try {
          final userProfile = await authService.getCurrentUserProfile();
          if (userProfile != null && mounted) {
            setState(() {
              _usernameController.text = userProfile.username ?? _usernameController.text;
              _emailController.text = userProfile.email ?? _emailController.text;
              _currentAvatarUrl = userProfile.avatarUrl ?? _currentAvatarUrl;
            });
          }
        } catch (profileError) {
          // 資料庫載入失敗，保留基本認證資訊
          print('Profile load error: $profileError');
        }
      }
    } catch (e) {
      print('Auth error: $e');
    }
  }

  Future<void> _loadReadingStats() async {
    await ref.read(readingHistoryNotifierProvider.notifier).loadReadingHistories();
  }

  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('選擇頭像失敗: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = SupabaseService.instance;
      String? avatarUrl = _currentAvatarUrl;

      // 上傳頭像（如果有選擇新頭像）
      if (_selectedAvatar != null) {
        final fileName = '${supabase.currentUser!.id}.jpg';
        final bytes = await _selectedAvatar!.readAsBytes();
        
        await supabase.avatars.uploadBinary(
          fileName,
          bytes,
        );
        
        avatarUrl = supabase.getPublicUrl(supabase.avatarsBucket, fileName);
      }

      // 更新用戶資料
      await supabase.users.update({
        'username': _usernameController.text.trim(),
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', supabase.currentUser!.id);

      // 重新載入用戶資料
      await ref.read(authNotifierProvider.notifier).refreshUser();

      setState(() {
        _isEditing = false;
        _selectedAvatar = null;
        _currentAvatarUrl = avatarUrl;
      });

      _showSuccessSnackBar('個人資料更新成功');

    } catch (e) {
      _showErrorSnackBar('更新失敗: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final email = _emailController.text;
    if (email.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final supabase = SupabaseService.instance;
      await supabase.client.auth.resetPasswordForEmail(email);

      _showSuccessSnackBar('密碼重設信件已發送到您的信箱');

    } catch (e) {
      _showErrorSnackBar('發送重設信件失敗: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showErrorSnackBar('登出失敗: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final readingStats = ref.watch(readingStatsProvider);
    final userProfile = ref.watch(userProfileProvider);

    // Listen for user profile changes and update fields
    ref.listen(userProfileProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          setState(() {
            _usernameController.text = user.username ?? _usernameController.text;
            _emailController.text = user.email ?? _emailController.text;
            _currentAvatarUrl = user.avatarUrl ?? _currentAvatarUrl;
          });
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人資料'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 頭像區域
            _buildAvatarSection(),
            
            const SizedBox(height: 24),
            
            // 個人資料表單
            _buildProfileForm(),
            
            const SizedBox(height: 24),
            
            // 閱讀統計
            _buildReadingStats(readingStats),
            
            const SizedBox(height: 24),
            
            // 動作按鈕
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
            backgroundImage: _selectedAvatar != null
                ? FileImage(_selectedAvatar!) as ImageProvider
                : _currentAvatarUrl != null
                    ? NetworkImage(_currentAvatarUrl!)
                    : null,
            child: _selectedAvatar == null && _currentAvatarUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: AppConstants.primaryColor,
                  )
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _usernameController,
            label: '用戶名稱',
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入用戶名稱';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _emailController,
            label: '電子信箱',
            enabled: false, // 電子信箱不可編輯
            keyboardType: TextInputType.emailAddress,
          ),
          
          if (_isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _isEditing = false;
                        _selectedAvatar = null;
                      });
                      _loadUserProfile();
                    },
                    child: const Text('取消'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingStats(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '閱讀統計',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '閱讀書籍',
                    '${stats['totalBooks']} 本',
                    Icons.book,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '完成書籍',
                    '${stats['completedBooks']} 本',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '閱讀時間',
                    '${stats['totalReadingTime']} 分鐘',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均進度',
                    '${(stats['averageProgress'] * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _changePassword,
            icon: const Icon(Icons.lock_reset),
            label: const Text('重設密碼'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('登出'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}