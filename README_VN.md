# 📋 Task Manager - Ứng Dụng Quản Lý Công Việc

## 📖 Giới Thiệu
Task Manager là ứng dụng Flutter giúp bạn quản lý công việc hiệu quả. Ứng dụng cho phép bạn tạo, chỉnh sửa, xóa các task và lọc chúng theo trạng thái hoặc từ khóa tìm kiếm.

---

## 🔄 Luồng Dữ Liệu (Data Flow)

### 1. **Tạo Task (Add Todo)**
```
Người dùng nhập nội dung → Xác thực input → Tạo đối tượng Todo → Lưu vào danh sách _todos → Cập nhật UI
```

**Chi tiết:**
- Người dùng bấm nút "+" để mở dialog nhập task
- Nhập nội dung task (bắt buộc)
- Có thể chọn thời hạn (deadline) và giờ (time)
- Ứng dụng tạo Todo object mới với ID duy nhất = timestamp hiện tại
- Thêm vào danh sách `_todos`
- UI tự động cập nhật

### 2. **Hiển Thị Task (Display)**
```
Danh sách _todos → Áp dụng bộ lọc trạng thái → Áp dụng bộ lọc tìm kiếm → Trả về danh sách đã lọc → Render UI
```

### 3. **Chỉnh Sửa Task (Update Todo)**
```
Chọn task → Mở dialog chỉnh sửa → Cập nhật nội dung, deadline, time → Lưu vào _todos → Cập nhật UI
```

### 4. **Xóa Task (Delete Todo)**
```
Chọn task → Xác nhận xóa → Xóa khỏi danh sách _todos → Cập nhật UI
```

### 5. **Đánh Dấu Hoàn Thành (Toggle Complete)**
```
Người dùng bấm checkbox → Đảo ngược trạng thái isCompleted → Cập nhật UI
```

---

## 💾 Lưu Trữ Dữ Liệu

### **Vị Trí Lưu Trữ: In-Memory (Bộ Nhớ Ứng Dụng)**

Dữ liệu được lưu trong **biến `_todos`** của class `_TodoHomePageState`:

```dart
final List<Todo> _todos = [];
```

**Lưu ý:** 
- ✅ Dữ liệu chỉ tồn tại khi ứng dụng đang chạy
- ⚠️ Khi đóng ứng dụng, dữ liệu sẽ bị mất
- Để lưu dữ liệu vĩnh viễn, cần thêm SQLite hoặc SharedPreferences

---

## 🔍 Các Chức Năng (Features)

### 1. **Tạo Task Mới**
- **Nút:** Nút "+" ở góc dưới phải màn hình
- **Chức năng:** 
  - Nhập nội dung task
  - Chọn thời hạn (deadline)
  - Chọn giờ cụ thể (time)
  - Kiểm tra input (không cho phép rỗng)

### 2. **Chỉnh Sửa Task**
- **Cách truy cập:** Bấm vào biểu tượng sửa (pencil icon) trên mỗi task
- **Chức năng:**
  - Thay đổi nội dung task
  - Cập nhật deadline
  - Cập nhật giờ
  - Lưu thay đổi

### 3. **Xóa Task**
- **Cách truy cập:** Bấm vào biểu tượng xóa (trash icon) trên mỗi task
- **Chức năng:**
  - Hiển thị dialog xác nhận
  - Xóa task khỏi danh sách
  - Hiển thị thông báo thành công

### 4. **Đánh Dấu Hoàn Thành**
- **Cách truy cập:** Bấm vào checkbox (hình tròn) bên trái task
- **Chức năng:**
  - Đánh dấu task là đã hoàn thành
  - Thay đổi màu sắc task
  - Thêm hiệu ứng xuyên ngang (strikethrough)

### 5. **Lọc Theo Trạng Thái**
- **Bộ lọc:**
  - 🔘 **Tất cả (All):** Hiển thị tất cả task
  - 🟡 **Chưa xong (Pending):** Chỉ task chưa hoàn thành (isCompleted = false)
  - 🟢 **Đã xong (Completed):** Chỉ task hoàn thành (isCompleted = true)

**Cách sử dụng:**
- Bấm vào các nút lọc ở top AppBar
- UI tự động cập nhật danh sách task

### 6. **Tìm Kiếm Theo Từ Khóa (Search)**
- **Cách truy cập:** Bấm vào biểu tượng tìm kiếm ở AppBar
- **Chức năng:**
  - Nhập từ khóa tìm kiếm
  - Lọc task theo tiêu đề
  - **Tìm kiếm không phân biệt chữ hoa/thường**
  - Hiển thị lịch sử tìm kiếm (10 lần gần nhất)

### 7. **Lịch Sử Tìm Kiếm**
- **Chức năng:**
  - Lưu lại 10 tìm kiếm gần nhất
  - Bấm vào để nhanh chóng tìm kiếm lại
  - Có nút xóa lịch sử tìm kiếm
  - Tự động xóa nếu vượt quá 10 tìm kiếm

---

## 🔎 Cách Thức Lọc Theo Từ (Search Filter)

### **Phương Thức:**
```dart
List<Todo> _getFilteredTodos() {
  // 1. Lọc theo trạng thái
  // 2. Lọc theo từ khóa tìm kiếm
  // 3. Trả về danh sách đã lọc
}
```

### **Bước Chi Tiết:**

**Bước 1: Lọc theo trạng thái**
```
- Nếu FilterStatus.all → Lấy tất cả _todos
- Nếu FilterStatus.pending → Lấy những task có isCompleted = false
- Nếu FilterStatus.completed → Lấy những task có isCompleted = true
```

**Bước 2: Lọc theo từ khóa**
```
- Nếu _searchQuery không rỗng:
  - Kiểm tra từng task
  - So sánh: todo.title.toLowerCase().contains(_searchQuery.toLowerCase())
  - Chỉ giữ task có tiêu đề chứa từ khóa
```

**Ví dụ:**
- Task: "Mua sắm hàng tạp hóa"
- Search: "mua" → ✅ Tìm thấy (không phân biệt chữ hoa/thường)
- Search: "XÃ" → ❌ Không tìm thấy

### **Kết Hợp 2 Bộ Lọc:**
```
Nếu chọn "Đã xong" và search "mua":
→ Chỉ hiển thị task HOÀN THÀNH có chứa từ "mua"
```

---

## 📤 Dữ Liệu Trả Về (Return Data)

### **Cấu Trúc Todo Object**

```dart
class Todo {
  String id;              // ID duy nhất (timestamp)
  String title;           // Nội dung task
  bool isCompleted;       // Trạng thái hoàn thành (true/false)
  DateTime createdAt;     // Thời gian tạo
  DateTime? deadline;     // Thời hạn (có thể null)
  TimeOfDay? time;        // Giờ cụ thể (có thể null)
}
```

### **Dữ Liệu Trả Về Từ `_getFilteredTodos()`**

```dart
List<Todo> filteredTodos = _getFilteredTodos();

/* Ví dụ trả về:
[
  Todo(
    id: "2026-03-13 10:30:45.123456",
    title: "Mua sắm hàng tạp hóa",
    isCompleted: true,
    createdAt: DateTime(2026, 3, 13),
    deadline: DateTime(2026, 3, 15),
    time: TimeOfDay(hour: 14, minute: 30)
  ),
  Todo(
    id: "2026-03-13 11:00:00.654321",
    title: "Hoàn thành báo cáo",
    isCompleted: false,
    createdAt: DateTime(2026, 3, 13),
    deadline: null,
    time: null
  ),
  // ...
]
*/
```

### **Thông Tin Thêm:**

| Trường | Kiểu | Mô Tả | Ví Dụ |
|--------|------|-------|-------|
| `id` | String | ID duy nhất, tạo từ timestamp | "2026-03-13 10:30:45.123456" |
| `title` | String | Nội dung task | "Mua sắm hàng tạp hóa" |
| `isCompleted` | bool | Đã hoàn thành? | true/false |
| `createdAt` | DateTime | Ngày tạo | 2026-03-13 10:30:45 |
| `deadline` | DateTime? | Thời hạn (tùy chọn) | 2026-03-15 / null |
| `time` | TimeOfDay? | Giờ cụ thể (tùy chọn) | 14:30 / null |

---

## 📊 Tóm Tắt Luồng Dữ Liệu

```
┌─────────────────────────────────────────────────────────┐
│                 NGƯỜI DÙNG                              │
└──────────────────────┬──────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┬──────────────┐
        │              │              │              │
        ▼              ▼              ▼              ▼
    ➕ Thêm      ✏️ Chỉnh Sửa  🗑️ Xóa     ☑️ Hoàn Thành
        │              │              │              │
        └──────────────┼──────────────┴──────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │   DANH SÁCH _todos           │
        │  (Lưu trữ In-Memory)         │
        └──────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
    🔘 Lọc Trạng Thái  🔍 Tìm Kiếm   📊 Hiển Thị
    (All/Pending/     (Theo từ khóa) (Render UI)
     Completed)       (Không phân biệt
                      chữ hoa/thường)
        │              │              │
        └──────────────┼──────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │   DANH SÁCH ĐÃ LỌC           │
        │  (Từ _getFilteredTodos())    │
        └──────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │   HIỂN THỊ LÊN MÀN HÌNH      │
        │  (TodoItemWidget)            │
        └──────────────────────────────┘
```

---

## 🛠️ Công Nghệ Sử Dụng

- **Framework:** Flutter 3.10.7+
- **Ngôn Ngữ:** Dart
- **UI Components:** Material Design 3
- **State Management:** StatefulWidget
- **Storage:** In-Memory (Hiện tại)

---

## 🎨 Giao Diện

- **Màu chính:** Purple (#5B4FFF)
- **Màu phụ:** Green (cho task hoàn thành)
- **Theme:** Material 3 Light Theme
- **Animations:** Scale transition, Color animation

---

## 📝 Ghi Chú

### Cần Cải Thiện:
1. ❌ Dữ liệu không lưu vĩnh viễn → Cần thêm SQLite hoặc SharedPreferences
2. ❌ Không có đồng bộ với cloud → Cần Firebase hoặc backend API
3. ❌ Không có notifikation → Cần thêm notification khi task quá hạn

### Hỗ Trợ:
- 📱 Android, iOS, Web, Windows, macOS, Linux
- 🌐 UI responsive trên mọi kích thước màn hình

---

**Phiên bản:** 1.0.0  
**Cập nhật lần cuối:** 13/03/2026  
**Tác giả:** [Tên của bạn]
