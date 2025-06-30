# SoR書庫 部署指南

## 環境配置

### 🧪 測試環境 (Development)
- **資料表**: `_dev_users`, `_dev_books`, `_dev_ratings`, `_dev_reading_history`
- **Storage Buckets**: `-dev-covers`, `-dev-avatars`, `-dev-files`
- **設定**: `.env` 檔案中 `ENVIRONMENT=development`

### 🚀 正式環境 (Production)
- **資料表**: `users`, `books`, `ratings`, `reading_history`
- **Storage Buckets**: `covers`, `avatars`, `files`
- **設定**: `.env.production` 檔案或 Vercel 環境變數中 `ENVIRONMENT=production`

## 部署到 Vercel

### 1. 建置 Flutter Web 版本
```bash
flutter build web --web-renderer html --release
```

### 2. 設定 Vercel 環境變數
在 Vercel Dashboard 中設定以下環境變數：
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anon key
- `ENVIRONMENT`: `production`
- `VERCEL_ENV`: `production`

### 3. 部署配置
- `vercel.json` 已配置為靜態網站部署
- 自動將 `ENVIRONMENT` 設為 `production`
- 支援 SPA 路由

### 4. 自動環境判斷
應用程式會根據以下順序判斷環境：
1. Vercel 環境變數 `VERCEL_ENV`
2. 自定義環境變數 `ENVIRONMENT`
3. Flutter Debug 模式 (`kDebugMode`)

## Supabase 資料庫設定

### 測試資料表
```sql
-- 建立用戶資料表
CREATE TABLE _dev_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR UNIQUE NOT NULL,
  username VARCHAR,
  avatar_url VARCHAR,
  is_admin BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立書籍資料表
CREATE TABLE _dev_books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR NOT NULL,
  author VARCHAR NOT NULL,
  description TEXT,
  cover_url VARCHAR,
  file_url VARCHAR,
  file_path VARCHAR NOT NULL,
  file_type VARCHAR NOT NULL,
  category VARCHAR,
  product_code VARCHAR,
  is_published BOOLEAN DEFAULT FALSE,
  is_free BOOLEAN DEFAULT TRUE,
  average_rating DECIMAL(3,2),
  total_ratings INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  uploader_id UUID REFERENCES _dev_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立評分資料表
CREATE TABLE _dev_ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES _dev_books(id) ON DELETE CASCADE,
  user_id UUID REFERENCES _dev_users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(book_id, user_id)
);

-- 建立閱讀歷史資料表
CREATE TABLE _dev_reading_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES _dev_books(id) ON DELETE CASCADE,
  user_id UUID REFERENCES _dev_users(id) ON DELETE CASCADE,
  current_page INTEGER DEFAULT 0,
  progress DECIMAL(5,4) DEFAULT 0.0,
  last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reading_time_minutes INTEGER DEFAULT 0,
  UNIQUE(book_id, user_id)
);
```

### 正式資料表
將上述 SQL 中的 `_dev_` 前綴移除即可。

## Storage Buckets

### 測試環境
- `-dev-covers`: 書籍封面圖片
- `-dev-avatars`: 用戶頭像
- `-dev-files`: 書籍檔案

### 正式環境
- `covers`: 書籍封面圖片
- `avatars`: 用戶頭像
- `files`: 書籍檔案

## 注意事項

1. **環境分離**: 測試和正式環境使用不同的資料表和 Storage Buckets
2. **自動切換**: 應用程式會根據環境變數自動選擇對應的資源
3. **安全性**: 正式環境的 Service Role Key 不應暴露在客戶端
4. **RLS 政策**: 確保 Supabase 的 Row Level Security 政策正確設定