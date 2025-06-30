# ebook250630 - SoR書庫

## 專案概述

SoR書庫是一個基於 Flutter + Supabase 的現代化電子書閱讀平台，提供優質的跨平台在線閱讀體驗。

## 功能特色

- **多格式支援**：PDF、EPUB、TXT、MOBI、AZW3、URL 連結等格式
- **雲端儲存**：基於 Supabase Storage 的檔案管理系統
- **用戶認證**：安全的註冊、登入與個人資料管理
- **書籍管理**：上傳、編輯、分類與搜尋書籍
- **評分系統**：為書籍評分與評論
- **閱讀歷史**：記錄閱讀進度與統計
- **管理後台**：完整的後台管理功能

## 技術架構

- **前端**：Flutter (支援 iOS、Android、Web、桌面)
- **後端**：Supabase (PostgreSQL + Auth + Storage)
- **狀態管理**：Riverpod
- **路由**：GoRouter
- **UI 組件**：Material Design 3

## 環境設定

### 1. 安裝 Flutter

確保已安裝 Flutter SDK 3.8.1 或更高版本。

### 2. 設定 Supabase

1. 在 [Supabase](https://supabase.com) 建立新專案
2. 複製專案的 URL 和 anon key
3. 在專案根目錄建立 `.env` 文件：

```
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
APP_NAME=SoR書庫
APP_VERSION=1.0.0
ENVIRONMENT=development
```

### 3. 資料庫設定

在 Supabase SQL 編輯器中執行以下 SQL 來建立必要的資料表：

```sql
-- 建立用戶資料表
CREATE TABLE users (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    username TEXT,
    avatar_url TEXT,
    is_admin BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB
);

-- 建立書籍資料表
CREATE TABLE books (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    description TEXT,
    cover_url TEXT,
    file_url TEXT,
    file_type TEXT NOT NULL,
    category TEXT,
    product_code TEXT,
    is_published BOOLEAN DEFAULT FALSE,
    average_rating DECIMAL(2,1),
    total_ratings INTEGER DEFAULT 0,
    uploader_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立評分資料表
CREATE TABLE ratings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(book_id, user_id)
);

-- 建立閱讀歷史資料表
CREATE TABLE reading_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    current_page INTEGER,
    progress DECIMAL(5,2),
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reading_time_minutes INTEGER DEFAULT 0,
    UNIQUE(book_id, user_id)
);

-- 建立 Storage Buckets
INSERT INTO storage.buckets (id, name, public) VALUES
('book-files', 'book-files', false),
('book-covers', 'book-covers', true),
('avatars', 'avatars', true);

-- 設定 RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_history ENABLE ROW LEVEL SECURITY;

-- 用戶資料表的政策
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 書籍資料表的政策
CREATE POLICY "Anyone can view published books" ON books
    FOR SELECT USING (is_published = true);

CREATE POLICY "Authenticated users can view all books" ON books
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert books" ON books
    FOR INSERT WITH CHECK (auth.uid() = uploader_id);

CREATE POLICY "Users can update own books" ON books
    FOR UPDATE USING (auth.uid() = uploader_id);

-- 評分資料表的政策
CREATE POLICY "Anyone can view ratings" ON ratings
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own ratings" ON ratings
    FOR ALL USING (auth.uid() = user_id);

-- 閱讀歷史資料表的政策
CREATE POLICY "Users can manage own reading history" ON reading_history
    FOR ALL USING (auth.uid() = user_id);
```

### 4. 安裝依賴

```bash
flutter pub get
```

### 5. 運行專案

```bash
flutter run
```

## 專案結構

```
lib/
├── main.dart               # 入口主程式
├── app.dart                # App 與路由設定
├── router.dart             # 路由配置
├── services/               # Supabase、API、資料處理
├── screens/                # 各主畫面
├── widgets/                # 自訂元件
├── models/                 # 資料結構 Class
└── utils/                  # 工具/輔助函式
```

## 開發進度

- [x] 專案架構建立
- [ ] 用戶認證系統
- [ ] 基本 UI 設計
- [ ] 資料模型定義
- [ ] Supabase 服務整合
- [ ] 書籍上傳功能
- [ ] 電子書閱讀器
- [ ] 搜尋功能
- [ ] 管理後台
- [ ] 測試與優化

## 開發指南

1. **讀取 CLAUDE.md 文件** - 包含 Claude Code 的重要開發規則
2. 遵循預先檢查清單再開始任何工作
3. 使用 `lib/` 下的模組化結構
4. 每完成一個功能後進行提交

## 常用指令

```bash
# 安裝依賴
flutter pub get

# 運行專案
flutter run

# 建置發佈版本
flutter build apk --release
flutter build web --release

# 執行測試
flutter test

# 程式碼格式化與分析
flutter format .
flutter analyze
```

## 貢獻指南

- 遵循 Flutter 開發最佳實務
- 使用 Material Design 3 設計規範
- 確保 Supabase 資料安全性
- 編寫單元測試和整合測試
- 提交前執行程式碼分析

---

**🎯 Template by Hugo Peng | v1.0.0**