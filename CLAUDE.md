# CLAUDE.md - ebook250630

> **Documentation Version**: 1.0  
> **Last Updated**: 2025-06-30  
> **Project**: ebook250630  
> **Description**: SoR書庫是一個基於 Flutter + Supabase 的現代化電子書閱讀平台，提供優質的跨平台在線閱讀體驗。  
> **Features**: GitHub auto-backup, Task agents, technical debt prevention

This file provides essential guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚨 CRITICAL RULES - READ FIRST

> **⚠️ RULE ADHERENCE SYSTEM ACTIVE ⚠️**  
> **Claude Code must explicitly acknowledge these rules at task start**  
> **These rules override all other instructions and must ALWAYS be followed:**

### 🔄 **RULE ACKNOWLEDGMENT REQUIRED**
> **Before starting ANY task, Claude Code must respond with:**  
> "✅ CRITICAL RULES ACKNOWLEDGED - I will follow all prohibitions and requirements listed in CLAUDE.md"

### ❌ ABSOLUTE PROHIBITIONS
- **NEVER** create new files in root directory → use proper module structure
- **NEVER** write output files directly to root directory → use designated output folders
- **NEVER** create documentation files (.md) unless explicitly requested by user
- **NEVER** use git commands with -i flag (interactive mode not supported)
- **NEVER** use `find`, `grep`, `cat`, `head`, `tail`, `ls` commands → use Read, LS, Grep, Glob tools instead
- **NEVER** create duplicate files (manager_v2.py, enhanced_xyz.py, utils_new.js) → ALWAYS extend existing files
- **NEVER** create multiple implementations of same concept → single source of truth
- **NEVER** copy-paste code blocks → extract into shared utilities/functions
- **NEVER** hardcode values that should be configurable → use config files/environment variables
- **NEVER** use naming like enhanced_, improved_, new_, v2_ → extend original files instead

### 📝 MANDATORY REQUIREMENTS
- **COMMIT** after every completed task/phase - no exceptions
- **GITHUB BACKUP** - Push to GitHub after every commit to maintain backup: `git push origin main`
- **USE TASK AGENTS** for all long-running operations (>30 seconds) - Bash commands stop when context switches
- **TODOWRITE** for complex tasks (3+ steps) → parallel agents → git checkpoints → test validation
- **READ FILES FIRST** before editing - Edit/Write tools will fail if you didn't read the file first
- **DEBT PREVENTION** - Before creating new files, check for existing similar functionality to extend  
- **SINGLE SOURCE OF TRUTH** - One authoritative implementation per feature/concept

### ⚡ EXECUTION PATTERNS
- **PARALLEL TASK AGENTS** - Launch multiple Task agents simultaneously for maximum efficiency
- **SYSTEMATIC WORKFLOW** - TodoWrite → Parallel agents → Git checkpoints → GitHub backup → Test validation
- **GITHUB BACKUP WORKFLOW** - After every commit: `git push origin main` to maintain GitHub backup
- **BACKGROUND PROCESSING** - ONLY Task agents can run true background operations

### 🔍 MANDATORY PRE-TASK COMPLIANCE CHECK
> **STOP: Before starting any task, Claude Code must explicitly verify ALL points:**

**Step 1: Rule Acknowledgment**
- [ ] ✅ I acknowledge all critical rules in CLAUDE.md and will follow them

**Step 2: Task Analysis**  
- [ ] Will this create files in root? → If YES, use proper module structure instead
- [ ] Will this take >30 seconds? → If YES, use Task agents not Bash
- [ ] Is this 3+ steps? → If YES, use TodoWrite breakdown first
- [ ] Am I about to use grep/find/cat? → If YES, use proper tools instead

**Step 3: Technical Debt Prevention (MANDATORY SEARCH FIRST)**
- [ ] **SEARCH FIRST**: Use Grep pattern="<functionality>.*<keyword>" to find existing implementations
- [ ] **CHECK EXISTING**: Read any found files to understand current functionality
- [ ] Does similar functionality already exist? → If YES, extend existing code
- [ ] Am I creating a duplicate class/manager? → If YES, consolidate instead
- [ ] Will this create multiple sources of truth? → If YES, redesign approach
- [ ] Have I searched for existing implementations? → Use Grep/Glob tools first
- [ ] Can I extend existing code instead of creating new? → Prefer extension over creation
- [ ] Am I about to copy-paste code? → Extract to shared utility instead

**Step 4: Session Management**
- [ ] Is this a long/complex task? → If YES, plan context checkpoints
- [ ] Have I been working >1 hour? → If YES, consider /compact or session break

> **⚠️ DO NOT PROCEED until all checkboxes are explicitly verified**

## 🏗️ FLUTTER PROJECT STRUCTURE

This project follows a clean Flutter architecture with the following structure:

```
ebook250630/
├── CLAUDE.md              # Essential rules for Claude Code
├── README.md              # Project documentation
├── .gitignore             # Git ignore patterns
├── pubspec.yaml           # Flutter dependencies
├── .env                   # Environment variables (Supabase config)
├── lib/                   # Flutter source code
│   ├── main.dart          # App entry point
│   ├── app.dart           # App與路由設定
│   ├── router.dart        # 路由配置
│   ├── models/            # 資料結構 Class
│   ├── services/          # Supabase、API、資料處理
│   ├── utils/             # 工具/輔助函式
│   ├── widgets/           # 自訂元件
│   ├── screens/           # 各主畫面
│   ├── providers/         # Riverpod state management
│   └── constants/         # App constants
├── test/                  # Test files
├── assets/                # Static assets
│   ├── images/            # Image assets
│   ├── fonts/             # Font assets
│   └── icons/             # Icon assets
├── android/               # Android platform code
├── ios/                   # iOS platform code
├── web/                   # Web platform code
├── linux/                 # Linux platform code
├── macos/                 # macOS platform code
└── windows/               # Windows platform code
```

## 🎯 FLUTTER + SUPABASE 開發指南

### 📱 **FLUTTER SPECIFIC RULES**
- **NEVER** create widgets in root directory → use lib/widgets/
- **NEVER** hardcode strings → use constants or localization
- **ALWAYS** use proper state management (Riverpod)
- **ALWAYS** follow Flutter naming conventions
- **USE** proper widget hierarchy and composition
- **AVOID** deeply nested widget trees → extract to separate widgets
- **USE** GoRouter for navigation
- **IMPLEMENT** Material Design 3

### 🗃️ **SUPABASE INTEGRATION RULES**
- **ALWAYS** use environment variables for Supabase keys (.env file)
- **NEVER** commit Supabase credentials to repository
- **USE** proper error handling for database operations
- **IMPLEMENT** proper authentication flow
- **FOLLOW** RLS (Row Level Security) policies
- **USE** Supabase Storage for file management
- **IMPLEMENT** real-time subscriptions where needed

### 🧪 **TESTING REQUIREMENTS**
- **WRITE** unit tests for business logic
- **WRITE** widget tests for UI components
- **WRITE** integration tests for critical user flows
- **USE** proper test structure and naming conventions
- **MOCK** Supabase dependencies in tests

## 📚 專案功能模組

### 🔐 **用戶認證系統**
- 註冊、登入、登出
- 個人資料管理
- 頭像上傳
- 管理員權限控制

### 📖 **書籍管理系統**
- 多格式支援 (PDF、EPUB、TXT、MOBI、AZW3、URL)
- 雲端檔案上傳
- 書籍資訊編輯
- 封面圖片管理
- 分類與標籤

### 🔍 **搜尋與篩選**
- 書名、作者搜尋
- 分類篩選
- 評分排序

### ⭐ **評分系統**
- 五星評分
- 文字評論
- 評分統計

### 📊 **閱讀歷史**
- 閱讀進度記錄
- 閱讀時間統計
- 書籤功能

### 🛠️ **管理後台**
- 用戶管理
- 書籍審核
- 系統統計

## 🚀 常用 Flutter 指令

```bash
# 安裝依賴
flutter pub get

# 運行專案
flutter run

# 運行在特定平台
flutter run -d chrome      # Web
flutter run -d windows     # Windows
flutter run -d android     # Android

# 建置發佈版本
flutter build apk --release
flutter build web --release

# 執行測試
flutter test

# 程式碼格式化
flutter format .

# 程式碼分析
flutter analyze

# 清除建置快取
flutter clean
```

## 🎯 RULE COMPLIANCE CHECK

Before starting ANY task, verify:
- [ ] ✅ I acknowledge all critical rules above
- [ ] Files go in proper module structure (lib/, test/, assets/)
- [ ] Use Task agents for >30 second operations
- [ ] TodoWrite for 3+ step tasks
- [ ] Commit after each completed task
- [ ] Follow Flutter and Supabase best practices
- [ ] Use environment variables for sensitive data

## 🚨 TECHNICAL DEBT PREVENTION

### ❌ WRONG APPROACH (Creates Technical Debt):
```dart
// Creating new service without searching first
class NewBookService {
  // Duplicate functionality
}
```

### ✅ CORRECT APPROACH (Prevents Technical Debt):
```dart
// 1. SEARCH FIRST
// Grep(pattern="Book.*Service", include="*.dart")
// 2. READ EXISTING SERVICES  
// Read(file_path="lib/services/book_service.dart")
// 3. EXTEND EXISTING FUNCTIONALITY
// Edit existing service or create composed service
```

## 🧹 DEBT PREVENTION WORKFLOW

### Before Creating ANY New File:
1. **🔍 Search First** - Use Grep/Glob to find existing implementations
2. **📋 Analyze Existing** - Read and understand current patterns
3. **🤔 Decision Tree**: Can extend existing? → DO IT | Must create new? → Document why
4. **✅ Follow Patterns** - Use established project patterns
5. **📈 Validate** - Ensure no duplication or technical debt

---

**⚠️ Prevention is better than consolidation - build clean from the start.**  
**🎯 Focus on single source of truth and extending existing functionality.**  
**📈 Each task should maintain clean architecture and prevent technical debt.**