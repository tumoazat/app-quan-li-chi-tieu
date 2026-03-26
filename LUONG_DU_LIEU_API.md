# 📊 Luồng Dữ Liệu & API Nhận Diện AI - Smart Expense

Tài liệu chi tiết về cách luồng dữ liệu hoạt động trong ứng dụng Smart Expense, tập trung vào công nghệ AI Cog (nhận diện văn bản/OCR) và xử lý dữ liệu.

---

## 📑 Mục Lục

1. [Kiến Trúc Tổng Thể](#kiến-trúc-tổng-thể)
2. [Luồng Dữ Liệu Giao Dịch](#luồng-dữ-liệu-giao-dịch)
3. [Hệ Thống OCR & Nhận Diện AI](#hệ-thống-ocr--nhận-diện-ai)
4. [API AI & Chatbot](#api-ai--chatbot)
5. [Lưu Trữ & Đồng Bộ Dữ Liệu](#lưu-trữ--đồng-bộ-dữ-liệu)
6. [Các Model Dữ Liệu](#các-model-dữ-liệu)

---

## 🏗️ Kiến Trúc Tổng Thể

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SMART EXPENSE APP                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐         ┌─────────────────────────────────┐  │
│  │   UI Layer       │         │   Presentation Layer            │  │
│  │  (Flutter)       │ ◄──────►│  (Provider/State Management)   │  │
│  └──────────────────┘         └─────────────────────────────────┘  │
│         ▲                               ▲                           │
│         │                               │                           │
│         └───────────────────┬───────────┘                           │
│                             │                                       │
│                     ┌───────▼────────┐                              │
│                     │  Application   │                              │
│                     │  Business      │                              │
│                     │  Logic         │                              │
│                     └───────┬────────┘                              │
│                             │                                       │
│  ┌──────────────────────────┴──────────────────────────────────┐  │
│  │                    Data Layer                              │  │
│  │                                                             │  │
│  │  ┌────────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │ Repositories   │  │  Services    │  │  Models      │  │  │
│  │  │  - Transaction │  │  - Firebase  │  │  - Trans     │  │  │
│  │  │  - User        │  │  - OCR       │  │  - User      │  │  │
│  │  │  - Chat        │  │  - AI Chat   │  │  - Category  │  │  │
│  │  └────────────────┘  │  - Geo Loc   │  │  - Chat Msg  │  │  │
│  │                      │  - Cache     │  └──────────────┘  │  │
│  │                      └──────────────┘                     │  │
│  └────────────────────────────────────────────────────────────┘  │
│         │                      │                       │          │
│         │                      │                       │          │
│         ▼                      ▼                       ▼          │
│  ┌────────────┐        ┌──────────────┐      ┌───────────────┐  │
│  │ Firestore  │        │   Local DB   │      │  Image Cache  │  │
│  │  (Cloud)   │        │   (Hive)     │      │   (Storage)   │  │
│  └────────────┘        └──────────────┘      └───────────────┘  │
│                                                                     │
└──────────────────────────────────────────────────────────────────────┘
                             ▲                    ▲
                             │                    │
                    ┌────────┴────────────────────┴────────┐
                    │                                      │
                    ▼                                      ▼
            ┌──────────────────┐            ┌──────────────────────┐
            │   External APIs  │            │   Camera / Gallery   │
            │                  │            │                      │
            │ - Google Gemini  │            │ - Image Capture      │
            │   (AI Chat)      │            │ - Google ML Kit      │
            │ - Google ML Kit  │            │ - Receipt Parsing    │
            │   (OCR)          │            │                      │
            │ - Firebase Auth  │            └──────────────────────┘
            │ - Notifications  │
            └──────────────────┘
```

---

## 🔄 Luồng Dữ Liệu Giao Dịch

### 1️⃣ **Thêm Giao Dịch Thủ Công**

```
┌─────────────────┐
│  User Input     │
│  (UI Screen)    │
└────────┬────────┘
         │
         │ 1. User nhập số tiền, danh mục, ghi chú
         │ 2. Click "Thêm giao dịch"
         │
         ▼
┌──────────────────────────────────────────┐
│  Auto-Categorization Service             │
│  (AutoCategoryService)                   │
│                                          │
│  - Phân tích text ghi chú                │
│  - So sánh keywords (từ khóa)            │
│  - Gợi ý danh mục tự động               │
│  - Confidence Score: 0-1.0              │
└────────┬─────────────────────────────────┘
         │
         │ 3. Nếu tin tưởng, áp dụng gợi ý
         │    (hoặc user có thể thay đổi)
         │
         ▼
┌──────────────────────────────────────────┐
│  Validation & Model Creation             │
│                                          │
│  - Kiểm tra số tiền > 0                 │
│  - Kiểm tra danh mục hợp lệ             │
│  - Tạo TransactionModel object          │
│  - Gán ngày/giờ hiện tại                │
└────────┬─────────────────────────────────┘
         │
         │ 4. Lưu vào Firestore
         │
         ▼
┌──────────────────────────────────────────┐
│  Firestore Database                      │
│                                          │
│  Collection: /users/{userId}/            │
│              transactions/{transId}      │
│                                          │
│  Document Fields:                        │
│  - id                                    │
│  - userId                                │
│  - amount (VNĐ)                         │
│  - type (income/expense)                │
│  - categoryId                            │
│  - date (Timestamp)                      │
│  - note (string)                         │
│  - imageUrl (optional)                   │
│  - createdAt (Timestamp)                │
└────────┬─────────────────────────────────┘
         │
         │ 5. Broadcast update
         │
         ▼
┌──────────────────────────────────────────┐
│  Update UI (Riverpod Provider)           │
│                                          │
│  - Cập nhật danh sách giao dịch         │
│  - Refresh biểu đồ thống kê             │
│  - Hiển thị notification thành công      │
└──────────────────────────────────────────┘
```

---

### 2️⃣ **Luồng Thêm Giao Dịch Qua Hóa Đơn (OCR)**

```
┌──────────────────────────────────────────┐
│  User Chụp Ảnh Hóa Đơn                  │
│                                          │
│  - Click nút "Chụp hóa đơn"             │
│  - Mở Camera app                         │
│  - Chụp ảnh hóa đơn                     │
└────────┬─────────────────────────────────┘
         │
         │ 1. Image File (JPEG/PNG)
         │
         ▼
┌──────────────────────────────────────────┐
│  Google ML Kit - OCR Service            │
│  (OcrService)                            │
│                                          │
│  - Nhận diện văn bản từ ảnh             │
│  - Sử dụng TextRecognizer               │
│  - Script: Latin (hỗ trợ tiếng Việt)   │
│  - Output: Raw text string              │
└────────┬─────────────────────────────────┘
         │
         │ 2. Raw Text (chứa tất cả thông tin)
         │    "Nhà hàng XYZ
         │     Tổng: 250.000đ
         │     Ngày 26/03/2026"
         │
         ▼
┌──────────────────────────────────────────┐
│  Receipt Parser                          │
│  (ReceiptParser)                         │
│                                          │
│  Trích xuất từ text raw:                │
│  ✓ extractAmount() - Lấy số tiền       │
│    - Pattern VNĐ: 1.000.000đ           │
│    - Pattern Quốc tế: 1,000.00         │
│    - Keywords: "tổng", "total", "...$" │
│                                          │
│  ✓ extractDescription() - Lấy mô tả    │
│    - Dòng đầu tiên > 3 ký tự           │
│    - Max 50 ký tự                       │
│                                          │
│  ✓ extractDate() - Lấy ngày            │
│    - Pattern: dd/MM/yyyy                │
│    - Pattern: yyyy-MM-dd                │
│                                          │
│  Output: StructuredReceipt object       │
│  {                                       │
│    amount: 250000.0,                    │
│    description: "Nhà hàng XYZ",        │
│    date: DateTime(2026, 03, 26)        │
│  }                                       │
└────────┬─────────────────────────────────┘
         │
         │ 3. Structured Data
         │
         ▼
┌──────────────────────────────────────────┐
│  AI Auto-Categorization                 │
│                                          │
│  - Input: description ("Nhà hàng XYZ") │
│  - Keywords matching từ MAP             │
│  - Best match: "restaurant"             │
│  - Category: "expense_food"             │
│  - Confidence: 0.8                      │
└────────┬─────────────────────────────────┘
         │
         │ 4. Pre-filled Form
         │
         ▼
┌──────────────────────────────────────────┐
│  Pre-fill Transaction Form              │
│                                          │
│  - Số tiền: 250,000 VNĐ                │
│  - Danh mục: Ăn uống [có thể thay]    │
│  - Ghi chú: Nhà hàng XYZ               │
│  - Ngày: 26/03/2026                    │
│  - Hình ảnh: [ảnh hóa đơn]            │
│                                          │
│  User có thể:                           │
│  - Chỉnh sửa lại                        │
│  - Xác nhận và lưu                      │
└────────┬─────────────────────────────────┘
         │
         │ 5. Upload ảnh hóa đơn
         │
         ▼
┌──────────────────────────────────────────┐
│  Firebase Storage                        │
│                                          │
│  Path: /receipts/{userId}/{transId}/    │
│        {timestamp}.jpg                   │
│                                          │
│  Return: imageUrl (cloud path)          │
└────────┬─────────────────────────────────┘
         │
         │ 6. Lưu vào Firestore
         │    (với imageUrl)
         │
         ▼
┌──────────────────────────────────────────┐
│  Firestore Transaction Document         │
│                                          │
│  {                                       │
│    "amount": 250000,                    │
│    "categoryId": "expense_food",        │
│    "note": "Nhà hàng XYZ",             │
│    "imageUrl": ".../receipts/abc.jpg",  │
│    "date": Timestamp,                   │
│    "createdAt": Timestamp               │
│  }                                       │
└──────────────────────────────────────────┘
```

---

## 🤖 Hệ Thống OCR & Nhận Diện AI

### **Google ML Kit - OCR (Optical Character Recognition)**

#### 📋 Chi Tiết Kỹ Thuật

| Thành phần | Chi tiết |
|-----------|---------|
| **Library** | `google_mlkit_text_recognition` |
| **Script** | Latin (hỗ trợ tiếng Việt) |
| **Input** | File ảnh (JPEG, PNG) |
| **Output** | Text string (raw) |
| **Độ chính xác** | ~95% với ảnh chất lượng tốt |
| **Speed** | ~1-3 giây tùy kích thước ảnh |
| **Cost** | Miễn phí (chạy on-device) |

#### 🔌 Cách Sử Dụng

```dart
// 1. Khởi tạo
final ocr = OcrService();

// 2. Recognize text từ file ảnh
final imageFile = File('/path/to/receipt.jpg');
final recognizedText = await ocr.recognizeText(imageFile);

// 3. Output example
// "Nhà hàng KFC
//  Tổng: 250.000đ
//  Ngày: 26/03/2026
//  Cảm ơn quý khách"

// 4. Cleanup
ocr.dispose();
```

#### ✅ Ưu Điểm
- ✓ Miễn phí, chạy on-device (không cần API)
- ✓ Hỗ trợ tiếng Việt tốt
- ✓ Nhanh chóng (offline)
- ✓ Bảo mật (không gửi ảnh lên server)

#### ⚠️ Hạn Chế
- ✗ Chính xác tùy chất lượng ảnh
- ✗ Không nhận diện tiêu đề/cấu trúc hóa đơn
- ✗ Cần parse thêm để lấy thông tin

---

### **Receipt Parser - Trích Xuất Thông Tin Hóa Đơn**

#### 📊 Quy Trình Phân Tích

**1. Trích Xuất Số Tiền (`extractAmount`)**

```
Input: "Tổng: 250.000đ"

Pattern Matching:
├─ Keyword patterns (ưu tiên cao)
│  ├─ /tổng[:\s]+(\d[\d.,]+)/i → "250.000"
│  ├─ /total[:\s]+(\d[\d.,]+)/i
│  └─ /thành tiền[:\s]+(\d[\d.,]+)/i
│
├─ VNĐ format (dot-separated): 1.000.000đ
│  └─ Regex: /(\d{1,3}(?:\.\d{3})+)/
│  └─ Replace "." → ""
│  └─ Parse: 1000000.0
│
├─ International format: 1,000,000
│  └─ Replace "," → ""
│
└─ Direct: "250đ", "250vnd"

Output: 250000.0 (double)
```

**2. Trích Xuất Mô Tả (`extractDescription`)**

```
Input: "Nhà hàng KFC\n
         Địa chỉ: ..."

Logic:
- Split text by newlines
- Filter lines với length > 3
- Lấy dòng đầu tiên
- Max 50 ký tự

Output: "Nhà hàng KFC"
```

**3. Trích Xuất Ngày (`extractDate`)**

```
Input: "Ngày: 26/03/2026"

Patterns:
├─ dd/MM/yyyy: 26/03/2026
├─ dd-MM-yyyy: 26-03-2026
└─ yyyy-MM-dd: 2026-03-26

Output: DateTime(2026, 03, 26)
```

#### 📈 Ví Dụ Đầu Ra

```dart
ReceiptData(
  amount: 250000.0,           // VNĐ
  description: "KFC Việt",    // Tên cửa hàng
  date: DateTime(2026, 3, 26) // Ngày ghi nhận
)
```

---

## 🧠 AI Auto-Categorization

### **Keyword-Based Classification**

Hệ thống phân loại dữ liệu dự trên từ khóa (keyword matching):

```dart
// Ví dụ keyword map
const keywordMap = {
  'ăn uống': 'expense_food',
  'nhà hàng': 'expense_food',
  'cafe': 'expense_food',
  'xăng': 'expense_transport',
  'taxi': 'expense_transport',
  'grab': 'expense_transport',
  'mua sắm': 'expense_shopping',
  'bách hóa': 'expense_shopping',
  // ... more keywords
};

// Categorization logic
String analyze(String text) {
  final lower = text.toLowerCase();
  
  String bestCategory = 'expense_others'; // default
  double bestScore = 0;
  
  for (final entry in keywordMap.entries) {
    final keyword = entry.key;
    
    if (lower.contains(keyword)) {
      // Keyword dài hơn → specificity cao hơn → score cao hơn
      final score = keyword.length.toDouble();
      
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.value;
      }
    }
  }
  
  final confidence = bestScore > 0 ? 0.8 : 0.0;
  
  return CategorySuggestion(
    categoryId: bestCategory,
    confidence: confidence,
    matchedKeyword: matchedKeyword,
  );
}
```

### **Confidence Scoring**

| Điều kiện | Confidence |
|----------|-----------|
| Keyword match (1 từ) | 0.8 |
| Keyword match (2+ từ) | 0.85-0.9 |
| Không match | 0.0 |
| Default category | N/A |

---

## 💬 API AI & Chatbot

### **Google Gemini 2.0 Flash - AI Chat Service**

#### 🔌 Cấu Hình API

```yaml
# .env file
GOOGLE_GEMINI_API_KEY=your_api_key_here
GOOGLE_GEMINI_MODEL=gemini-2.0-flash
```

#### 📡 Flow Chatbot

```
┌─────────────────────────────────────┐
│  User Message                       │
│  "Phân tích chi tiêu tháng này"    │
└────────┬────────────────────────────┘
         │
         │ 1. Prepare context data
         │
         ▼
┌─────────────────────────────────────┐
│  Fetch Transaction Data             │
│                                     │
│  - Load all transactions this month │
│  - Filter by userId                │
│  - Group by category               │
│  - Calculate totals                │
└────────┬────────────────────────────┘
         │
         │ 2. Build context string
         │
         ▼
┌─────────────────────────────────────┐
│  System Prompt + User Context       │
│                                     │
│  "Bạn là AI Chuyên gia tài chính"  │
│                                     │
│  Context:                           │
│  - Tháng 3/2026                    │
│  - Thu nhập: 50.000.000 VNĐ        │
│  - Chi tiêu:                       │
│    • Ăn uống: 8.000.000            │
│    • Xăng: 3.000.000               │
│    • Mua sắm: 5.000.000            │
│    • Khác: 2.000.000               │
│  - Tiết kiệm: 32.000.000           │
│                                     │
│  User: "Phân tích chi tiêu tháng"  │
└────────┬────────────────────────────┘
         │
         │ 3. Send to Google Gemini API
         │
         ▼
┌─────────────────────────────────────┐
│  Google Generative AI API           │
│                                     │
│  - Model: gemini-2.0-flash         │
│  - Temperature: 0.7                │
│  - Max tokens: 2048               │
│                                     │
│  Response:                          │
│  "Chi tiêu tháng 3 của bạn là      │
│   18.000.000 VNĐ, chiếm 36% thu    │
│   nhập. Ăn uống chiếm 44% chi      │
│   tiêu. Bạn nên giảm chi phí ăn    │
│   uống để tăng tiết kiệm..."       │
└────────┬────────────────────────────┘
         │
         │ 4. Stream response to UI
         │
         ▼
┌─────────────────────────────────────┐
│  Chat UI                            │
│                                     │
│  [AI Icon] Chi tiêu tháng 3...     │
│                                     │
│  - Real-time streaming             │
│  - Emoji hỗ trợ: 📈📉💰           │
│  - Formatted response              │
└─────────────────────────────────────┘
```

#### 🎯 System Prompt Chính

Chatbot được cấu hình với prompt chi tiết:

```
Bạn là "AI Chuyên Gia Tài Chính Toàn Cầu"

Quy tắc:
1. Luôn trả lời bằng tiếng Việt
2. Sử dụng emoji (📈📉💰🎯)
3. Luôn đưa số liệu cụ thể và %
4. Format số dễ đọc (1.200.000.000đ)
5. Đưa kịch bản & xác suất (không khẳng định chắc chắn)
6. Nhắc rủi ro khi nói đầu tư
7. Phân tích → Chiến lược → Kết luận

Loại câu hỏi hỗ trợ:
- Phân tích chi tiêu
- Tư vấn quản lý tài chính
- Dự đoán xu hướng
- Phân tích chuyên sâu
- Tính toán tài chính
```

#### 📊 Các Loại Query Hỗ Trợ

| Query | Ví dụ | Output |
|-------|-------|--------|
| **Phân tích** | "Phân tích chi tiêu tháng này" | Tổng quan chi tiêu, breakdown danh mục, gợi ý |
| **Tư vấn** | "Nên tiết kiệm bao nhiêu %" | Kế hoạch tiết kiệm, chiến lược cắt giảm |
| **Dự đoán** | "Dự đoán chi tiêu cuối tháng" | Trend, forecast, scenarios |
| **So sánh** | "So sánh tháng này vs tháng trước" | Phân tích so sánh, thay đổi, insights |
| **Tính toán** | "Bao lâu tiết kiệm 1 tỷ?" | Công thức, timeline, kịch bản |

---

### **Multi-Provider AI Support**

Hệ thống hỗ trợ nhiều AI provider với fallback tự động:

```dart
class AiProvider {
  final String name;        // "Google Gemini", "Claude", ...
  final String apiKey;      // API key
  final String model;       // "gemini-2.0-flash", ...
  final String type;        // "gemini", "claude", "openai", "groq"
  bool isAvailable;         // Health status
}

// Fallback logic
┌─ Provider 1 (Gemini) ─ Lỗi ─┐
│                             │
└─ Provider 2 (Claude) ─ Lỗi ─┤
│                             │
└─ Provider 3 (OpenAI) ─ OK ──► Sử dụng Provider 3
│                             │
└─ Provider 4 (Groq) ─────────┘
```

---

## 💾 Lưu Trữ & Đồng Bộ Dữ Liệu

### **Firestore Database Structure**

```
/users/{userId}/
├─ /transactions/{transId}/
│  ├─ id: string
│  ├─ userId: string
│  ├─ amount: number (VNĐ)
│  ├─ type: string ("income" | "expense")
│  ├─ categoryId: string ("expense_food", ...)
│  ├─ date: timestamp
│  ├─ note: string
│  ├─ imageUrl: string (optional)
│  └─ createdAt: timestamp
│
├─ /budgets/{budgetId}/
│  ├─ categoryId: string
│  ├─ monthYear: string ("202603")
│  ├─ limit: number
│  ├─ spent: number
│  └─ createdAt: timestamp
│
├─ /chats/{chatId}/
│  ├─ id: string
│  ├─ userId: string
│  ├─ message: string
│  ├─ role: string ("user" | "assistant")
│  ├─ timestamp: timestamp
│  └─ provider: string ("gemini", ...)
│
└─ /profile/
   ├─ email: string
   ├─ displayName: string
   ├─ photoUrl: string
   ├─ createdAt: timestamp
   └─ preferences: object
```

### **Local Storage (Hive)**

```dart
// Caching strategy
class LocalStorage {
  // Cache transactions
  final Box<TransactionModel> transactions;
  
  // Cache user preferences
  final Box<UserPreferences> preferences;
  
  // Cache OCR results (temporary)
  final Box<String> ocrCache;
}

// Sync logic
- Upload lên Firestore khi có internet
- Read từ local cache khi offline
- Auto-sync khi online trở lại
```

### **Firebase Storage - Hóa Đơn Ảnh**

```
/receipts/{userId}/{transactionId}/
├─ {timestamp}.jpg (original)
└─ {timestamp}_thumb.jpg (thumbnail)

Metadata:
- Size: < 5MB
- Format: JPEG (90% quality)
- Retention: Cùng kỳ + 3 tháng
```

---

## 📋 Các Model Dữ Liệu

### **1. TransactionModel**

```dart
class TransactionModel {
  final String id;                    // Unique ID
  final String userId;                // User reference
  final double amount;                // VNĐ
  final TransactionType type;         // income | expense
  final String categoryId;            // expense_food, ...
  final DateTime date;                // Ghi nhận ngày/giờ
  final String? note;                 // Mô tả giao dịch
  final String? imageUrl;             // Link hóa đơn (optional)
  final DateTime createdAt;           // Timestamp tạo
}

// Enums
enum TransactionType { income, expense }
enum Category {
  expenseFood,
  expenseTransport,
  expenseShopping,
  // ...
}
```

### **2. CategorySuggestion**

```dart
class CategorySuggestion {
  final String categoryId;      // "expense_food"
  final double confidence;      // 0.0 - 1.0
  final String matchedKeyword;  // "nhà hàng"
}
```

### **3. ChatMessage**

```dart
class ChatMessage {
  final String id;
  final String userId;
  final String content;
  final String role;              // "user" | "assistant"
  final DateTime timestamp;
  final String? provider;         // "gemini"
}
```

### **4. ReceiptData (Temp)**

```dart
class ReceiptData {
  final double amount;
  final String description;
  final DateTime? date;
  final String rawText;          // OCR output
}
```

---

## 🔐 Bảo Mật & Quyền Hạn

### **Firestore Security Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Chats are user-specific
    match /users/{userId}/chats/{chatId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Transactions are user-specific
    match /users/{userId}/transactions/{transId} {
      allow create: if request.auth.uid == userId && 
                       request.resource.data.amount > 0;
      allow read, update, delete: if request.auth.uid == userId;
    }
  }
}
```

---

## 📊 Hiệu Suất & Tối Ưu Hóa

### **Caching Strategy**

| Data | Cache | TTL | Strategy |
|------|-------|-----|----------|
| Transactions | Local (Hive) | Infinite | Sync on change |
| Categories | Memory | Session | Pre-load on startup |
| User Profile | Local + Firestore | 1 hour | Hybrid |
| Chat History | Firestore only | Infinite | Lazy load |
| OCR Results | Temp cache | 30 min | Clear after use |

### **API Call Optimization**

```
OCR Processing:
- Image compression: max 2MP
- Processing time: ~1-3s
- Batch processing: N/A (real-time)

AI Chat:
- Streaming: Enabled
- Batch: Disabled (real-time)
- Rate limit: 100 requests/min (Gemini)

Firestore:
- Batch write: Up to 500 docs
- Read limit: ~1M/month free
- Index: Optimized for common queries
```

---

## 🚀 Các Tính Năng Nâng Cao

### **1. Speech-to-Text**

```dart
// Tính năng ghi âm ghi chú
class SpeechToText {
  Future<String> recognize() async {
    // Tập trung vào tiếng Việt
    // Output: "Ăn cơm tại nhà hàng ABC"
    // → Auto-categorize → expense_food
  }
}
```

### **2. Real-time Notifications**

```dart
// Cảnh báo vượt ngân sách
class NotificationService {
  void notifyBudgetExceeded(String category, double spent, double limit) {
    // "⚠️ Danh mục Ăn uống vượt 15% ngân sách!"
  }
}
```

### **3. Geo-Location Tagging**

```dart
// Ghi nhận địa điểm giao dịch
class GeoLocationService {
  Future<Location> getCurrentLocation() async {
    // Lưu vào transaction data
    // Để phân tích chi tiêu theo khu vực
  }
}
```

---

## 📚 Tài Liệu Tham Khảo

### **External APIs**

| API | Mục đích | Độc lập | Status |
|-----|---------|--------|--------|
| Google ML Kit OCR | Nhận diện chữ | Có (on-device) | Active |
| Google Gemini | AI Chat | Không (API key) | Active |
| Firebase Firestore | Database | Không (Auth) | Active |
| Firebase Storage | Lưu ảnh | Không (Auth) | Active |
| Google Sign-In | Authentication | Không (API key) | Active |

### **Dependencies**

```yaml
# AI & ML
google_mlkit_text_recognition: ^0.13.1
google_generative_ai: ^0.4.7

# Cloud
firebase_core: ^3.15.2
cloud_firestore: ^5.6.5
firebase_storage: ^12.4.4

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# State Management
flutter_riverpod: ^2.6.1

# Utilities
image_picker: ^1.1.2
camera: ^0.11.0
permission_handler: ^11.3.1
```

---

## 🎯 Quick Start - Thêm Giao Dịch từ Hóa Đơn

### **Step 1: Chụp Ảnh**
```
User: Mở app → Tab "Thêm giao dịch" → Click "📷 Chụp hóa đơn"
```

### **Step 2: OCR Processing**
```
App: Google ML Kit OCR → Trích text từ ảnh
```

### **Step 3: Parse Receipt**
```
App: ReceiptParser → Lấy số tiền, mô tả, ngày
```

### **Step 4: Auto-Categorize**
```
App: AutoCategoryService → Gợi ý danh mục (confidence: 0.8)
```

### **Step 5: Review & Save**
```
User: Xem thông tin đã auto-fill → Sửa nếu cần → Click "Lưu"
```

### **Step 6: Upload & Sync**
```
App: 
  1. Upload ảnh → Firebase Storage
  2. Lưu transaction → Firestore
  3. Update UI (Riverpod)
  4. Refresh thống kê
```

---

## ❓ FAQ

**Q: Tại sao phải dùng OCR?**
A: Để người dùng nhanh chóng thêm giao dịch từ hóa đơn mà không cần nhập tay.

**Q: Độ chính xác OCR bao nhiêu?**
A: ~95% với ảnh chất lượng tốt. Khuyên chụp ảnh dưới ánh sáng, tránh che khuất.

**Q: Có thể tắt AI auto-categorize không?**
A: Có, user có thể chọn danh mục thủ công sau khi review OCR result.

**Q: Hóa đơn ảnh có được lưu vĩnh viễn không?**
A: Có, lưu trên Firebase Storage. Có thể xóa thủ công qua "Quản lý ảnh".

**Q: Chatbot có hiểu được lịch sử chat không?**
A: Có, lưu chat history trong Firestore. Load lại khi mở chat screen.

**Q: Hỗ trợ tiếng gì?**
A: Chính: Tiếng Việt. OCR hỗ trợ: Latin script (tiếng Anh, Việt, ...).

**Q: Cần internet để sử dụng OCR không?**
A: Không, OCR chạy on-device. Nhưng cần internet để upload ảnh & lưu Firestore.

---

**Document Version:** 1.0  
**Last Updated:** March 26, 2026  
**Maintained by:** Smart Expense Development Team
