# 🤖 AI Chatbot Tài Chính - Tài Liệu Kỹ Thuật

## 📌 Tổng Quan

AI Chatbot Tài Chính là tính năng trợ lý ảo thông minh tích hợp trong ứng dụng quản lý chi tiêu. Chatbot sử dụng **Google Gemini 2.0 Flash API** (không phải ChatGPT) để phân tích và tư vấn tài chính cá nhân dựa trên **dữ liệu thực** của người dùng từ Firestore.

---

## 🧠 AI Từ Đâu Ra?

### ❌ KHÔNG phải AI tự viết từ code
Chatbot **KHÔNG** sử dụng logic if-else hay rule-based (phiên bản cũ `ai_advice_service.dart` dùng rule-based đã được thay thế).

### ✅ API từ Google Gemini (Generative AI)
- **Model**: `gemini-2.0-flash` — mô hình AI mới nhất của Google
- **Package**: `google_generative_ai` phiên bản `0.4.7` (Flutter/Dart SDK chính thức của Google)
- **Cách hoạt động**: App gửi tin nhắn của user + context tài chính → Gemini API xử lý → trả về phản hồi thông minh bằng tiếng Việt
- **Không phải ChatGPT**: Sử dụng Google Gemini, không phải OpenAI ChatGPT

### 🔑 API Key
```
YOUR_API_KEY_HERE
```
API key được lưu trực tiếp trong `ai_chat_service.dart`. Trong production nên chuyển sang biến môi trường hoặc backend proxy.

---

## 🏗️ Cấu Trúc Code

```
lib/
├── data/
│   ├── models/
│   │   └── chat_message.dart          ← Model tin nhắn + Quick Actions
│   └── services/
│       ├── ai_chat_service.dart       ← ⭐ Core: Kết nối Gemini API + build context tài chính
│       └── ai_advice_service.dart     ← (Cũ) Rule-based, không còn dùng cho chatbot
├── providers/
│   └── chat_provider.dart             ← Riverpod state management cho chat
└── presentation/
    └── ai_advice/
        ├── ai_advice_screen.dart      ← Re-export file mới
        ├── ai_advice_screen_new.dart  ← ⭐ UI chính của chatbot
        └── widgets/
            ├── chat_bubble.dart       ← Widget bong bóng tin nhắn
            ├── quick_actions_bar.dart ← Thanh gợi ý nhanh
            └── financial_summary_header.dart ← Header tóm tắt tài chính
```

---

## 📁 Chi Tiết Từng File

### 1. `chat_message.dart` — Model Dữ Liệu

**Vai trò**: Định nghĩa cấu trúc dữ liệu cho tin nhắn và gợi ý nhanh.

```dart
// Enum phân loại vai trò tin nhắn
enum MessageRole { user, assistant, system }

// Enum phân loại nội dung
enum MessageType { text, financialSummary, suggestion, chart }

// Model tin nhắn
class ChatMessage {
  final String id;           // UUID duy nhất
  final MessageRole role;    // user hoặc assistant
  final String content;      // Nội dung text
  final MessageType type;    // Loại tin nhắn
  final DateTime timestamp;  // Thời gian gửi
  final bool isLoading;      // Đang chờ AI trả lời?
  final Map<String, dynamic>? metadata;  // Dữ liệu bổ sung
}

// Model gợi ý nhanh (6 gợi ý mặc định)
class QuickAction {
  final String label;   // "Phân tích chi tiêu"
  final String emoji;   // "📊"
  final String prompt;  // Câu hỏi gửi cho AI
  final Color color;    // Màu chip
}
```

**6 Quick Actions mặc định**:
| Emoji | Tên | Mô tả |
|-------|-----|-------|
| 📊 | Phân tích chi tiêu | Phân tích chi tiết theo danh mục |
| 💡 | Gợi ý tiết kiệm | 5 gợi ý tiết kiệm cụ thể |
| 🏆 | Đánh giá tài chính | Sức khỏe tài chính tổng thể |
| ⚠️ | Cảnh báo chi tiêu | Kiểm tra vượt ngân sách |
| ⚖️ | So sánh thu chi | Thu nhập vs chi tiêu |
| 📅 | Kế hoạch tháng sau | Lập kế hoạch chi tiêu |

---

### 2. `ai_chat_service.dart` — ⭐ Core AI Service

**Vai trò**: Kết nối Google Gemini API và xây dựng context tài chính từ dữ liệu thực.

#### Cấu hình Gemini:
```dart
GenerativeModel(
  model: 'gemini-2.0-flash',    // Model nhanh, chính xác
  apiKey: _apiKey,
  generationConfig: GenerationConfig(
    temperature: 0.7,     // Độ sáng tạo (0.0-1.0)
    topP: 0.95,           // Nucleus sampling
    topK: 40,             // Top-K sampling
    maxOutputTokens: 2048, // Giới hạn output
  ),
  systemInstruction: Content.system(_systemPrompt),
);
```

#### System Prompt (Chỉ dẫn cho AI):
AI được cấu hình với persona **"AI Tài Chính Thông Minh"** với 10 quy tắc:
1. Luôn trả lời bằng **tiếng Việt**
2. Phân tích dựa trên **dữ liệu thực** (không bịa số)
3. Lời khuyên **cụ thể** với con số chính xác
4. Sử dụng **emoji** cho trực quan
5. Giọng điệu **thân thiện**, dễ hiểu
6. Đơn vị tiền: **VNĐ**
7. Format số tiền dễ đọc: `1.500.000đ`
8. Ngoài phạm vi tài chính → nhẹ nhàng chuyển hướng
9. Trả lời **ngắn gọn** nhưng đầy đủ
10. **Không bịa số liệu**

#### `buildFinancialContext()` — Xây dựng context tài chính:

Hàm này đọc dữ liệu thực từ Firestore và tạo chuỗi context gửi kèm mỗi tin nhắn:

```
📊 DỮ LIỆU TÀI CHÍNH THÁNG 2/2026:
👤 Người dùng: Nguyễn Văn A

💵 TỔNG QUAN:
  - Thu nhập: 24.922.000đ (3 giao dịch)
  - Chi tiêu: 5.000.000đ (2 giao dịch)
  - Số dư: 19.922.000đ
  - Tỷ lệ tiết kiệm: 79.9%
  - Tổng giao dịch: 5

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
  - 💰 Khác: 4.922.000đ

🏷️ GIAO DỊCH GẦN ĐÂY:
  - 15/2: -3.000.000đ (Ăn uống) - Tiệc sinh nhật
  - 14/2: +20.000.000đ (Lương)
  ...

🔴 CHI TIÊU LỚN NHẤT: 3.000.000đ (Ăn uống, ngày 15/2)
```

Dữ liệu bao gồm:
- ✅ **Tổng quan**: thu nhập, chi tiêu, số dư, tỷ lệ tiết kiệm
- ✅ **Ngân sách**: đã dùng bao nhiêu %, ngày còn lại, ngân sách/ngày
- ✅ **Chi tiêu theo danh mục**: sắp xếp từ cao → thấp, kèm % và số giao dịch
- ✅ **Thu nhập theo nguồn**: phân loại nguồn thu
- ✅ **5 giao dịch gần nhất**: ngày, số tiền, danh mục, ghi chú
- ✅ **Chi tiêu lớn nhất**: flag giao dịch bất thường

#### `sendMessage()` — Gửi tin nhắn cho AI:

```
User gõ tin nhắn
        ↓
chatProvider.sendMessage(text)
        ↓
_getFinancialContext() ← Đọc dữ liệu thực từ Riverpod providers
        ↓
ai_chat_service.sendMessage(
  userMessage: text,
  financialContext: contextString,   ← Context tài chính kèm theo
)
        ↓
Gemini API nhận: "Câu hỏi + Context tài chính đầy đủ"
        ↓
Gemini trả về câu trả lời thông minh bằng tiếng Việt
        ↓
Hiển thị trong ChatBubble
```

**Lịch sử hội thoại**: Gemini nhớ 20 tin nhắn gần nhất (10 lượt hỏi-đáp) để trả lời có ngữ cảnh liên tục.

**Fallback khi lỗi**: Nếu API fail, hiển thị dữ liệu tài chính raw + thông báo lỗi (không crash app).

---

### 3. `chat_provider.dart` — State Management (Riverpod)

**Vai trò**: Quản lý state danh sách tin nhắn, kết nối UI với AI service.

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  UI (Screen)    │────▶│  ChatNotifier    │────▶│  AiChatService  │
│                 │◀────│  (Riverpod)      │◀────│  (Gemini API)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                    ┌──────────┼──────────┐
                    ▼          ▼          ▼
            transactions  monthlyBudget  currentUser
            StreamProvider  Provider     Provider
                    │          │          │
                    └──────────┼──────────┘
                               ▼
                         Firestore DB
```

**Providers**:
- `aiChatServiceProvider` — Singleton AiChatService
- `chatProvider` — `StateNotifierProvider<ChatNotifier, List<ChatMessage>>`

**Flow gửi tin nhắn**:
1. Thêm tin nhắn user vào state
2. Thêm tin nhắn loading (placeholder có animation 3 chấm)
3. Đọc dữ liệu tài chính real-time từ `transactionsStreamProvider`, `monthlyBudgetProvider`, `currentUserProvider`
4. Gọi Gemini API với câu hỏi + context
5. Thay thế loading bằng response thực
6. Nếu lỗi → thay thế loading bằng thông báo lỗi

---

### 4. `ai_advice_screen_new.dart` — ⭐ UI Chính

**Vai trò**: Màn hình chatbot hoàn chỉnh.

**Cấu trúc UI**:
```
┌──────────────────────────────┐
│  AppBar: 🤖 AI Tài Chính    │  ← Logo gradient + nút refresh
├──────────────────────────────┤
│  FinancialSummaryHeader      │  ← Thu nhập | Chi tiêu | Số dư
│  📈 24.9tr | 📉 5tr | 💰 19.9tr │  + Budget progress bar
├──────────────────────────────┤
│                              │
│  ChatBubble (AI welcome)     │  ← Tin nhắn chào mừng
│                              │
│  ChatBubble (User)      ████ │  ← Tin nhắn user (phải)
│  🤖 ChatBubble (AI)         │  ← Tin nhắn AI (trái + avatar)
│                              │
│  ...ListView scrollable...   │
│                              │
├──────────────────────────────┤
│  QuickActionsBar             │  ← 6 chip gợi ý cuộn ngang
│  [📊 Phân tích] [💡 Tiết kiệm] ... │
├──────────────────────────────┤
│  💡 [___Hỏi về tài chính___] 🟢│  ← Input bar + Send button
└──────────────────────────────┘
```

**Tính năng UI**:
- ✅ Auto-scroll khi có tin nhắn mới
- ✅ Quick actions ẩn sau khi gửi tin nhắn đầu tiên
- ✅ Toggle quick actions bằng nút 💡
- ✅ Support dark mode hoàn chỉnh
- ✅ Keyboard submit (gõ Enter gửi)
- ✅ Multi-line input (tối đa 4 dòng)
- ✅ Nút refresh tạo cuộc trò chuyện mới

---

### 5. `chat_bubble.dart` — Widget Bong Bóng Chat

**Vai trò**: Hiển thị tin nhắn với giao diện đẹp, hỗ trợ markdown.

- **Tin nhắn AI** (trái): Avatar gradient 🤖, nền xám nhạt, bo góc trái nhỏ
- **Tin nhắn User** (phải): Nền xanh primary, chữ trắng, bo góc phải nhỏ
- **Loading**: 3 chấm nhấp nháy animation (scale up/down lặp vô hạn)
- **Markdown**: Parse `**text**` → chữ **in đậm**
- **Animation**: Fade in + slide up khi xuất hiện (flutter_animate)

---

### 6. `quick_actions_bar.dart` — Thanh Gợi Ý Nhanh

**Vai trò**: Hiển thị 6 chip gợi ý cuộn ngang.

- Mỗi chip có: emoji + label + màu riêng
- Tap vào chip → gửi prompt tương ứng cho AI
- Animation: Fade in + slide từ phải (staggered delay theo index)
- Border + background color theo theme (dark/light)

---

### 7. `financial_summary_header.dart` — Header Tài Chính

**Vai trò**: Hiển thị tóm tắt tài chính compact ở đầu chatbot.

- 3 cột: 📈 Thu nhập | 📉 Chi tiêu | 💰 Số dư
- Progress bar ngân sách (xanh < 70% < vàng < 90% < đỏ)
- Text "Ngân sách: XX% đã dùng"
- Số tiền format compact (vd: 24.9tr, 5tr)
- Dark mode support

---

## 🔄 Luồng Hoạt Động Tổng Thể

```
                    ┌─────────────┐
                    │   User mở   │
                    │  tab AI 🤖  │
                    └──────┬──────┘
                           ▼
              ┌────────────────────────┐
              │ ChatNotifier khởi tạo  │
              │ + Tin nhắn welcome     │
              │ + Load transactions    │
              │   từ Firestore stream  │
              └────────────┬───────────┘
                           ▼
              ┌────────────────────────┐
              │ User chọn Quick Action │
              │ hoặc gõ câu hỏi       │
              └────────────┬───────────┘
                           ▼
              ┌────────────────────────┐
              │ _getFinancialContext() │
              │ Đọc real-time từ:      │
              │ • transactionsStream   │
              │ • monthlyBudget        │
              │ • currentUser          │
              └────────────┬───────────┘
                           ▼
              ┌────────────────────────┐
              │ buildFinancialContext() │
              │ Tạo context string:    │
              │ • Tổng thu/chi/dư      │
              │ • Budget status        │
              │ • Category breakdown   │
              │ • 5 giao dịch gần đây  │
              │ • Chi tiêu lớn nhất    │
              └────────────┬───────────┘
                           ▼
              ┌────────────────────────┐
              │ Gửi đến Gemini API:    │
              │ "Câu hỏi user"         │
              │ + "[Context tài chính]" │
              │                        │
              │ Gemini xử lý + trả lời │
              │ bằng tiếng Việt 🇻🇳    │
              └────────────┬───────────┘
                           ▼
              ┌────────────────────────┐
              │ Hiển thị trong         │
              │ ChatBubble + animation │
              └────────────────────────┘
```

---

## 📦 Dependencies Sử Dụng

| Package | Version | Vai trò |
|---------|---------|---------|
| `google_generative_ai` | 0.4.7 | SDK chính thức Google Gemini API |
| `flutter_riverpod` | 2.6.1 | State management |
| `uuid` | 4.5.1 | Tạo ID duy nhất cho tin nhắn |
| `flutter_animate` | 4.5.2 | Animation cho chat bubble, quick actions |
| `cloud_firestore` | 5.6.5 | Database (nguồn dữ liệu giao dịch) |
| `intl` | 0.19.0 | Format số tiền, ngày tháng |

---

## ⚡ Tại Sao Chọn Gemini 2.0 Flash Mà Không Phải ChatGPT?

| Tiêu chí | Gemini 2.0 Flash | ChatGPT (OpenAI) |
|-----------|-----------------|-------------------|
| **Tốc độ** | ⚡ Rất nhanh (optimized for speed) | 🐢 Chậm hơn |
| **Giá** | 💚 Free tier rộng rãi | 💰 Tốn phí từ đầu |
| **Flutter SDK** | ✅ SDK chính thức (`google_generative_ai`) | ❌ Không có SDK Dart chính thức |
| **Tiếng Việt** | ✅ Tốt | ✅ Tốt |
| **Context window** | 1M tokens | 128K tokens |
| **Tích hợp Firebase** | ✅ Cùng hệ sinh thái Google | ❌ Khác hệ sinh thái |

---

## 🔐 Bảo Mật & Lưu Ý

1. **API Key**: Hiện hardcode trong source code → Production nên dùng:
   - Firebase Remote Config
   - Backend proxy server
   - Biến môi trường (`--dart-define`)

2. **Dữ liệu gửi đi**: Context tài chính được gửi đến Google Gemini API mỗi lần chat → dữ liệu tài chính cá nhân đi qua server Google

3. **Rate Limiting**: Gemini Free tier có giới hạn:
   - 15 requests/phút
   - 1,500 requests/ngày
   - Production nên upgrade lên paid plan

4. **Fallback**: Khi API lỗi, app hiển thị dữ liệu raw thay vì crash

---

## 🚀 Hướng Phát Triển Tương Lai

- [ ] Thêm biểu đồ trong chat (pie chart chi tiêu)
- [ ] Voice input (nhận diện giọng nói)
- [ ] Export báo cáo tài chính PDF
- [ ] So sánh chi tiêu với tháng trước
- [ ] Nhận diện ảnh hóa đơn → tự thêm giao dịch
- [ ] Push notification từ AI khi chi tiêu bất thường
- [ ] Đa ngôn ngữ (EN/VI)
