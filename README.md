 Smart Expense - Personal Finance Manager with AI 💰

Ứng dụng quản lý tài chính cá nhân thông minh với phân tích AI được xây dựng bằng Flutter.

## ✨ Tính năng chính

### 🔐 Xác thực
- Đăng nhập/Đăng ký bằng Email
- Đăng nhập bằng Google
- Quên mật khẩu
- Quản lý hồ sơ người dùng

### 💸 Quản lý giao dịch
- Thêm thu/chi nhanh chóng
- Phân loại theo danh mục (Ăn uống, Di chuyển, Mua sắm, ...)
- Ghi chú cho mỗi giao dịch
- Xem lịch sử giao dịch theo tháng
- Lọc theo loại giao dịch
- Xóa giao dịch (swipe to delete)

### 📊 Thống kê & Phân tích
- Biểu đồ tròn chi tiêu theo danh mục
- Biểu đồ cột chi tiêu hàng ngày
- Phân tích chi tiết từng danh mục
- Tổng quan thu chi tháng
- Tỷ lệ tiết kiệm

### 🤖 AI Chatbot Tài Chính (Google Gemini 2.0 Flash)
- Chatbot AI trò chuyện real-time bằng tiếng Việt
- Tự động đọc dữ liệu thu/chi/ngân sách từ Firestore
- Phân tích chi tiêu theo danh mục với con số cụ thể
- Cảnh báo vượt ngân sách, gợi ý tiết kiệm
- Đánh giá sức khỏe tài chính tổng thể
- Lập kế hoạch tài chính cho tháng sau
- 6 gợi ý nhanh (Quick Actions) có sẵn
- Giao diện chat hiện đại với animation
- Hỗ trợ dark mode

### 👤 Cá nhân
- Quản lý hồ sơ cá nhân
- Cài đặt ngân sách tháng
- Chuyển đổi giao diện sáng/tối
- Thống kê nhanh (giao dịch, streak, tiết kiệm)
- Đăng xuất

## 🚀 Cài đặt

### Yêu cầu
- Flutter SDK ^3.10.7
- Dart SDK ^3.10.7
- Android Studio / Xcode (cho mobile)
- Firebase Project (cho authentication & database)

### Bước 1: Clone repository
```bash
git clone <repository-url>
cd android
```

### Bước 2: Cài đặt dependencies
```bash
flutter pub get
```

### Bước 3: Cấu hình Firebase

#### 3.1 Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới hoặc chọn project có sẵn
3. Thêm Android/iOS app vào project

#### 3.2 Cài đặt Firebase CLI
```bash
# Cài đặt Firebase CLI
npm install -g firebase-tools

# Đăng nhập Firebase
firebase login

# Cài đặt FlutterFire CLI
dart pub global activate flutterfire_cli
```

#### 3.3 Cấu hình Firebase cho Flutter
```bash
# Chạy lệnh cấu hình
flutterfire configure --project=<your-project-id>

# Chọn platforms: Android, iOS, Web (tùy theo nhu cầu)
```

Lệnh này sẽ tự động tạo file `lib/firebase_options.dart` với cấu hình Firebase của bạn.

#### 3.4 Kích hoạt Firebase services
Trong Firebase Console, kích hoạt các services:
- **Authentication**: Email/Password và Google Sign-In
- **Cloud Firestore**: Tạo database ở chế độ test
- **Storage**: (Optional) Cho việc lưu hình ảnh

#### 3.5 Cấu hình Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Transactions subcollection
      match /transactions/{transactionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Bước 4: Chạy ứng dụng
```bash
# Chạy trên device/emulator
flutter run

# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios
```

## 📁 Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # MaterialApp configuration
├── core/                     # Core utilities
│   ├── theme/               # App themes (light/dark)
│   ├── constants/           # Constants & category data
│   ├── utils/               # Formatters & helpers
│   └── router/              # GoRouter configuration
├── data/                     # Data layer
│   ├── models/              # Data models
│   │   ├── transaction_model.dart   # Giao dịch thu/chi
│   │   ├── user_model.dart          # Thông tin user
│   │   └── chat_message.dart        # ⭐ Model tin nhắn AI + QuickAction
│   ├── repositories/        # Data repositories
│   │   ├── transaction_repository.dart
│   │   └── user_repository.dart
│   └── services/            # Business logic services
│       ├── ai_chat_service.dart     # ⭐ Kết nối Google Gemini API
│       └── ai_advice_service.dart   # (Cũ) Rule-based analysis
├── providers/               # Riverpod providers
│   ├── transaction_provider.dart    # Stream giao dịch từ Firestore
│   ├── user_provider.dart           # User profile + budget
│   ├── auth_provider.dart           # Authentication state
│   └── chat_provider.dart           # ⭐ State management cho AI chat
└── presentation/            # UI layer
    ├── auth/               # Authentication screens
    ├── navigation/         # Bottom navigation
    ├── home/               # Home screen
    ├── transactions/       # Transactions management
    ├── statistics/         # Statistics & charts
    ├── ai_advice/          # ⭐ AI Chatbot
    │   ├── ai_advice_screen.dart        # Re-export
    │   ├── ai_advice_screen_new.dart    # ⭐ UI chatbot chính
    │   └── widgets/
    │       ├── chat_bubble.dart          # Bong bóng tin nhắn
    │       ├── quick_actions_bar.dart    # 6 gợi ý nhanh
    │       └── financial_summary_header.dart  # Header tài chính
    ├── profile/            # User profile
    └── shared/             # Shared widgets
```

## 🎨 Design System

### Màu sắc chính
- **Primary**: `#2ECC71` (Fintech Green)
- **Background Light**: `#F8F9FA`
- **Background Dark**: `#121212`
- **Expense**: `#E74C3C` (Red)
- **Income**: `#2ECC71` (Green)

### Typography
- Font chữ: **Inter** (Google Fonts)
- Sizes: 36sp (Display), 28sp (Amount), 24sp (Headline), 16sp (Body), 12sp (Caption)

### Components
- **Border Radius**: 8-24px
- **Spacing**: 4-32px increments
- **Shadows**: Subtle shadows cho depth
- **Animations**: 300ms smooth transitions

## 🤖 AI Chatbot - Chi Tiết Kiến Trúc

### Nguồn AI: Google Gemini 2.0 Flash (KHÔNG phải ChatGPT)

Chatbot sử dụng **Google Gemini 2.0 Flash API** thông qua package `google_generative_ai` (SDK chính thức của Google cho Dart/Flutter). Đây là AI thật từ cloud API, **không phải** logic if-else viết tay trong code.

### Cấu trúc file chatbot

```
📁 AI CHATBOT FILES:

lib/data/models/chat_message.dart        ← Model dữ liệu
lib/data/services/ai_chat_service.dart   ← Core: gọi Gemini API
lib/providers/chat_provider.dart         ← State management
lib/presentation/ai_advice/
  ├── ai_advice_screen_new.dart          ← Màn hình chatbot
  └── widgets/
      ├── chat_bubble.dart               ← Widget tin nhắn
      ├── quick_actions_bar.dart          ← 6 nút gợi ý
      └── financial_summary_header.dart   ← Header thu/chi/dư
```

### Vai trò từng file

| File | Vai trò | Chi tiết |
|------|---------|----------|
| `chat_message.dart` | Model dữ liệu | Định nghĩa `ChatMessage` (id, role, content, isLoading) và `QuickAction` (6 gợi ý mặc định) |
| `ai_chat_service.dart` | **⭐ Core AI** | Kết nối Gemini 2.0 Flash, gửi/nhận tin nhắn, xây dựng context tài chính từ dữ liệu Firestore |
| `chat_provider.dart` | State management | `ChatNotifier` (Riverpod) quản lý danh sách tin nhắn, đọc dữ liệu real-time từ providers khác |
| `ai_advice_screen_new.dart` | UI chính | Màn hình chat: header tài chính + list tin nhắn + input bar + quick actions |
| `chat_bubble.dart` | Widget UI | Bong bóng tin nhắn (AI bên trái, User bên phải), parse markdown bold, loading 3 chấm |
| `quick_actions_bar.dart` | Widget UI | 6 chip gợi ý cuộn ngang: Phân tích, Tiết kiệm, Đánh giá, Cảnh báo, So sánh, Kế hoạch |
| `financial_summary_header.dart` | Widget UI | Hiển thị compact: 📈Thu nhập \| 📉Chi tiêu \| 💰Số dư + thanh ngân sách |

### Luồng dữ liệu (Data Flow)

```
┌──────────────────────────────────────────────────────────────┐
│                    LUỒNG DỮ LIỆU CHATBOT                    │
└──────────────────────────────────────────────────────────────┘

  ┌─────────┐    tin nhắn     ┌──────────────┐
  │  User   │ ──────────────▶ │  UI Screen   │
  │ (gõ/tap)│                 │ (ai_advice_  │
  └─────────┘                 │  screen_new) │
                              └──────┬───────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │ ChatNotifier │  (chat_provider.dart)
                              │  (Riverpod)  │
                              └──────┬───────┘
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
           ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
           │ transactions │ │ monthlyBudget│ │ currentUser  │
           │ StreamProvider│ │   Provider   │ │   Provider   │
           └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
                  │                │                │
                  └────────────────┼────────────────┘
                                   ▼
                            ┌─────────────┐
                            │  Firestore  │  (Cloud Database)
                            │  Database   │
                            └─────────────┘

  (Dữ liệu Firestore được đọc real-time qua Riverpod providers)

                              ┌──────────────┐
                              │ ChatNotifier │
                              └──────┬───────┘
                                     │
                    Gộp: tin nhắn + context tài chính
                                     │
                                     ▼
                              ┌──────────────┐
                              │AiChatService │  (ai_chat_service.dart)
                              │              │
                              │ buildContext │ → Tạo chuỗi context:
                              │    ()        │   • Tổng thu/chi/dư
                              │              │   • Ngân sách còn lại
                              │              │   • Chi tiêu theo danh mục
                              │              │   • 5 giao dịch gần nhất
                              │              │   • Chi lớn nhất
                              │              │   • Tỷ lệ tiết kiệm
                              └──────┬───────┘
                                     │
                    Gửi: câu hỏi + context tài chính
                                     │
                                     ▼
                         ┌────────────────────┐
                         │  Google Gemini API  │  (Cloud)
                         │  Model: gemini-2.0  │
                         │         -flash      │
                         │                    │
                         │  Xử lý + trả lời  │
                         │  bằng tiếng Việt   │
                         └─────────┬──────────┘
                                   │
                          Phản hồi AI (text)
                                   │
                                   ▼
                              ┌──────────────┐
                              │ ChatNotifier │  Cập nhật state
                              └──────┬───────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │  ChatBubble  │  Hiển thị tin nhắn
                              │  (animation) │  với fade-in + slide
                              └──────────────┘
```

### Context tài chính gửi cho AI (mỗi lần chat)

Mỗi khi user gửi tin nhắn, hàm `buildFinancialContext()` tự động đọc dữ liệu Firestore và tạo context:

```
📊 DỮ LIỆU TÀI CHÍNH THÁNG 2/2026:
👤 Người dùng: Nguyễn Văn A

💵 TỔNG QUAN:
  - Thu nhập: 24.922.000đ (3 giao dịch)
  - Chi tiêu: 5.000.000đ (2 giao dịch)
  - Số dư: 19.922.000đ
  - Tỷ lệ tiết kiệm: 79.9%

💰 NGÂN SÁCH:
  - Ngân sách tháng: 10.000.000đ
  - Đã sử dụng: 50.0%
  - Còn 12 ngày trong tháng
  - Ngân sách còn lại/ngày: 416.667đ

📉 CHI TIÊU THEO DANH MỤC:
  - 🍔 Ăn uống: 3.000.000đ (60.0%, 1 giao dịch)
  - 🚗 Di chuyển: 2.000.000đ (40.0%, 1 giao dịch)

📈 THU NHẬP THEO NGUỒN:
  - 💼 Lương: 20.000.000đ

🏷️ 5 GIAO DỊCH GẦN ĐÂY:
  - 15/2: -3.000.000đ (Ăn uống)
  - 14/2: +20.000.000đ (Lương)
  ...

🔴 CHI TIÊU LỚN NHẤT: 3.000.000đ (Ăn uống, ngày 15/2)
```

→ Context này được **gửi kèm mỗi tin nhắn** để Gemini luôn có dữ liệu mới nhất.

### Cấu hình Gemini AI

```dart
GenerativeModel(
  model: 'gemini-2.0-flash',       // Model nhanh của Google
  apiKey: _apiKey,                  // API key Google AI Studio
  generationConfig: GenerationConfig(
    temperature: 0.7,               // Độ sáng tạo
    topP: 0.95,                     // Nucleus sampling
    topK: 40,                       // Top-K sampling
    maxOutputTokens: 2048,          // Giới hạn output
  ),
  systemInstruction: Content.system(
    'Bạn là AI Tài Chính Thông Minh...'
    // 10 quy tắc: tiếng Việt, dùng dữ liệu thực,
    // không bịa số, format VNĐ, emoji, thân thiện...
  ),
);
```

### Tại sao Gemini mà không phải ChatGPT?

| Tiêu chí | Gemini 2.0 Flash | ChatGPT (OpenAI) |
|-----------|-----------------|-------------------|
| Tốc độ | ⚡ Rất nhanh | 🐢 Chậm hơn |
| Giá | 💚 Free tier rộng | 💰 Tốn phí ngay |
| Flutter SDK | ✅ Chính thức | ❌ Không có |
| Context | 1M tokens | 128K tokens |
| Firebase | ✅ Cùng Google | ❌ Khác hệ sinh thái |

---

## 📦 Dependencies chính

### UI & Design
- `fl_chart` - Biểu đồ
- `google_fonts` - Fonts
- `flutter_animate` - Animations
- `shimmer` - Loading effects

### Navigation & State
- `go_router` - Routing
- `flutter_riverpod` - State management

### Firebase
- `firebase_core` - Firebase core
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `google_sign_in` - Google login

### AI
- `google_generative_ai` - Google Gemini 2.0 Flash API (SDK chính thức)

### Utility
- `intl` - Internationalization
- `shared_preferences` - Local storage
- `uuid` - ID generation

## 🔧 Troubleshooting

### Firebase initialization error
Nếu gặp lỗi Firebase initialization:
1. Đảm bảo đã chạy `flutterfire configure`
2. Kiểm tra file `firebase_options.dart` đã được tạo
3. Kiểm tra Firebase project ID đúng
4. Xóa `build` folder và chạy lại: `flutter clean && flutter pub get`

### Google Sign-In không hoạt động
1. Kích hoạt Google Sign-In trong Firebase Console
2. Thêm SHA-1 fingerprint (Android):
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
3. Cập nhật `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS)

### Lỗi build
```bash
# Clean project
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

## 📝 Lưu ý

- Ứng dụng yêu cầu kết nối internet để đồng bộ dữ liệu với Firebase
- Dữ liệu được lưu trên Cloud Firestore
- AI Chatbot sử dụng Google Gemini 2.0 Flash API (cần kết nối internet)
- API key Gemini hiện hardcode trong code → production nên dùng biến môi trường
- Gemini Free tier: 15 req/phút, 1.500 req/ngày
- Theme tối/sáng được lưu local và áp dụng tự động

## 🤝 Contributing

Mọi đóng góp đều được chào đón! Vui lòng:
1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📄 License

Dự án được phát hành dưới MIT License.

## 📧 Liên hệ

Nếu có câu hỏi hoặc góp ý, vui lòng tạo issue trên GitHub.

---

Made with ❤️ using Flutter
