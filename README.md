# Task Manager - Todo App

## 📋 Mô Tả Dự Án

**Task Manager** là một ứng dụng quản lý công việc (Todo App) được xây dựng bằng **Flutter** với giao diện hiện đại, chuyên nghiệp theo Material Design 3. 

Ứng dụng cung cấp các tính năng đầy đủ để quản lý danh sách công việc hàng ngày:
- Thêm công việc mới
- Sửa công việc
-  Xóa công việc
-  Đánh dấu hoàn thành
- Lọc công việc theo trạng thái

---

##  Cấu Trúc Thư Mục

```
lib/
├── main.dart                          # File chính, định nghĩa MyApp & TodoHomePage
├── widgets/
│   └── todo_item_widget.dart         # Widget hiển thị từng item todo
```

### Chi Tiết Cấu Trúc:

| File/Thư Mục | Mô Tả |
|--------------|-------|
| `main.dart` | Chứa hàm `main()`, class `MyApp`, `TodoHomePage`, `_TodoHomePageState`. Xử lý toàn bộ logic chính của ứng dụng |
| `widgets/todo_item_widget.dart` | Chứa `TodoItemWidget` - Widget custom để hiển thị từng task trong danh sách |

---

##  Giải Thích Cấu Trúc Source Code

### **1. File: `main.dart`**

#### **1.1 Class `MyApp` (StatelessWidget)**
```dart
class MyApp extends StatelessWidget
```
- Root widget của ứng dụng
- Cấu hình theme: Material 3, color scheme indigo
- Thiết lập `TodoHomePage` làm home screen

**Thuộc tính theme:**
- `seedColor: Color(0xFF6366F1)` - Màu chính (Indigo)
- `useMaterial3: true` - Sử dụng Material Design 3
- `appBarTheme` - Cấu hình thanh tiêu đề

---

#### **1.2 Model: `Todo`**
```dart
class Todo {
  String id;
  String title;
  bool isCompleted;
  DateTime createdAt;
}
```

**Giải thích:**
- `id`: Định danh duy nhất cho mỗi task (dùng timestamp)
- `title`: Nội dung công việc
- `isCompleted`: Trạng thái hoàn thành (true/false)
- `createdAt`: Thời gian tạo task (mặc định = hiện tại)

---

#### **1.3 Class `TodoHomePage` (StatefulWidget)**
```dart
class TodoHomePage extends StatefulWidget
```
- Widget cha, chứa logic toàn bộ ứng dụng
- Quản lý state của danh sách todo

---

#### **1.4 Class `_TodoHomePageState`**

**Thuộc tính chính:**
```dart
final List<Todo> _todos = [];              // Danh sách all todos
FilterStatus _filterStatus = FilterStatus.all;  // Trạng thái filter hiện tại
final TextEditingController _inputController;   // Controller input
```

**Enum FilterStatus:**
```dart
enum FilterStatus { all, pending, completed }
```
- `all`: Hiển thị tất cả todos
- `pending`: Hiển thị todos chưa hoàn thành
- `completed`: Hiển thị todos đã hoàn thành

---

### **2. Logic Các Phương Thức Chính**

#### **2.1 `_addTodo(String title)` - Thêm Task**
```dart
void _addTodo(String title) {
  // Validation: kiểm tra title không rỗng
  if (title.trim().isEmpty) {
    // Hiển thị snackbar thông báo lỗi
    return;
  }
  
  setState(() {
    _todos.add(Todo(
      id: DateTime.now().toString(),
      title: title,
    ));
  });
  // Đóng dialog sau khi thêm
  Navigator.pop(context);
}
```

**Luồng thực thi:**
1. Kiểm tra nội dung không rỗng
2. Tạo `Todo` mới với id = timestamp hiện tại
3. Thêm vào danh sách `_todos`
4. Gọi `setState()` để cập nhật UI
5. Đóng dialog input

---

#### **2.2 `_updateTodo(String id, String newTitle)` - Sửa Task**
```dart
void _updateTodo(String id, String newTitle) {
  if (newTitle.trim().isEmpty) {
    // Validation
    return;
  }
  
  setState(() {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index].title = newTitle;  // Cập nhật title
    }
  });
  Navigator.pop(context);
}
```

**Luồng thực thi:**
1. Validation: kiểm tra input không rỗng
2. Tìm index của todo bằng id (`.indexWhere()`)
3. Cập nhật `title` nếu tìm thấy
4. Gọi `setState()` refresh UI
5. Đóng dialog

---

#### **2.3 `_deleteTodo(String id)` - Xóa Task**
```dart
void _deleteTodo(String id) {
  showDialog(
    // Dialog xác nhận
    onConfirm: () {
      setState(() {
        _todos.removeWhere((todo) => todo.id == id);
      });
      // Hiển thị snackbar thành công
    }
  );
}
```

**Luồng thực thi:**
1. Hiển thị **Dialog xác nhận** với 2 nút: "Hủy" / "Xóa"
2. Nếu người dùng nhấn "Xóa":
   - Xóa todo khỏi danh sách bằng `.removeWhere()`
   - Gọi `setState()` cập nhật UI
   - Hiển thị snackbar thông báo thành công
3. Đóng dialog

---

#### **2.4 `_toggleComplete(String id)` - Đánh Dấu Hoàn Thành**
```dart
void _toggleComplete(String id) {
  setState(() {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.isCompleted = !todo.isCompleted;  // Đảo ngược trạng thái
  });
}
```

**Luồng thực thi:**
1. Tìm todo bằng id (`.firstWhere()`)
2. Đảo ngược giá trị `isCompleted` (true → false, false → true)
3. Gọi `setState()` để cập nhật UI ngay lập tức

---

#### **2.5 `_getFilteredTodos()` - Logic Lọc**
```dart
List<Todo> _getFilteredTodos() {
  switch (_filterStatus) {
    case FilterStatus.all:
      return _todos;  // Trả về toàn bộ
    case FilterStatus.pending:
      return _todos.where((todo) => !todo.isCompleted).toList();
    case FilterStatus.completed:
      return _todos.where((todo) => todo.isCompleted).toList();
  }
}
```

**Luồng thực thi:**
1. Kiểm tra `_filterStatus` hiện tại
2. Dùng `.where()` để lọc danh sách theo điều kiện
3. Trả về danh sách filtered

| Status | Điều Kiện | Kết Quả |
|--------|----------|---------|
| `all` | Không lọc | Toàn bộ todos |
| `pending` | `!todo.isCompleted` | Todos chưa hoàn thành |
| `completed` | `todo.isCompleted` | Todos đã hoàn thành |

---

#### **2.6 Dialog Input - `_buildInputDialog()`**
```dart
Widget _buildInputDialog({
  required String title,
  String? initialValue,
  required Function(String) onSave,
})
```

**Cấu trúc:**
- **BottomSheet Modal** - hiển thị từ dưới cùng
- Có TextField để nhập nội dung
- 2 nút: "Hủy" và "Lưu"
- Padding điều chỉnh theo keyboard (`viewInsets.bottom`)

**Dùng để:**
- Thêm task mới (initialValue = null)
- Sửa task (initialValue = todo.title cũ)

---

### **3. UI Build Method - `build()`**

**Cấu trúc giao diện:**
```
Scaffold
├── AppBar (Task Manager)
├── Column
│   ├── Filter Tabs (Tất Cả / Chưa Xong / Đã Xong)
│   └── ListView
│       └── TodoItemWidget × N
└── FloatingActionButton (Thêm Task)
```

**Logic filter tab:**
```dart
_buildFilterChip(
  label: 'Tất Cả',
  isActive: _filterStatus == FilterStatus.all,
  onTap: () => setState(() => _filterStatus = FilterStatus.all),
  count: _todos.length,
)
```

**Hiển thị danh sách:**
```dart
ListView.builder(
  itemCount: filteredTodos.length,
  itemBuilder: (context, index) {
    return TodoItemWidget(
      todo: filteredTodos[index],
      onToggle: () => _toggleComplete(filteredTodos[index].id),
      onEdit: () => _showEditDialog(filteredTodos[index]),
      onDelete: () => _deleteTodo(filteredTodos[index].id),
    );
  },
)
```

---

### **4. File: `widgets/todo_item_widget.dart`**

#### **TodoItemWidget - Widget Custom**
```dart
class TodoItemWidget extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
}
```

**Cấu trúc UI từ trái sang phải:**
```
[Checkbox] [Title + Date] [Edit Button] [Delete Button]
```

**Chi tiết:**

| Thành Phần | Mô Tả |
|-----------|-------|
| **Checkbox (Tròn)** | Bấm để toggle hoàn thành, có icon check khi active |
| **Title + Date** | Hiển thị nội dung task, text gạch ngang nếu hoàn thành |
| **Date Format** | "Hôm nay HH:mm" / "Hôm qua" / "DD/MM/YYYY" |
| **Edit Button** | Icon edit (xanh dương), bấm mở dialog sửa |
| **Delete Button** | Icon delete (đỏ), bấm xóa có confirm dialog |

**Styling quando hoàn thành:**
```dart
decoration: todo.isCompleted
    ? TextDecoration.lineThrough  // Gạch ngang
    : TextDecoration.none,
color: todo.isCompleted
    ? Colors.grey.shade500        // Màu mờ
    : Colors.black87,
```

---

## Luồng Dữ Liệu (Data Flow)

```
User Action (bấm nút)
        ↓
Callback được gọi (_addTodo, _toggleComplete, etc.)
        ↓
Cập nhật List<Todo>
        ↓
setState() được gọi
        ↓
build() được gọi lại
        ↓
UI cập nhật với dữ liệu mới
        ↓
_getFilteredTodos() lọc dữ liệu
        ↓
ListView.builder() hiển thị từng TodoItemWidget
```

---

## ⚙️ Cách Chạy Ứng Dụng

### **1. Chuẩn Bị**
```bash
flutter pub get
```

### **2. Chạy trên Emulator/Device**
```bash
flutter run
```

### **3. Build APK (Android)**
```bash
flutter build apk --release
```

---

## 🎨 Giao Diện & Thiết Kế

### **Color Scheme:**
- **Primary**: Indigo (#6366F1) - Màu chính cho AppBar, buttons, active tabs
- **Background**: Trắng (#FFFFFF)
- **Text**: Xám tối (#212121) cho text chính, xám nhạt cho sub-text

### **Typography:**
- **Title Large**: 22sp, Bold - Tiêu đề dialog
- **Title Medium**: 16sp - Tên task
- **Body Small**: 12sp - Ngày tháng

### **Component Style:**
- **Card**: Elevation 2, Border radius 12, Border 1px grey-200
- **Checkbox**: Tròn, border 2px, check icon trắng
- **Filter Chip**: Border radius 20, có badge count
- **FAB**: Extended với icon + text

---

## ✅ Danh Sách Tính Năng

| # | Tính Năng | Trạng Thái |
|---|----------|----------|
| 1 | Thêm task | ✅ Hoàn thành |
| 2 | Sửa task | ✅ Hoàn thành |
| 3 | Xóa task (có confirm) | ✅ Hoàn thành |
| 4 | Đánh dấu hoàn thành | ✅ Hoàn thành |
| 5 | Lọc theo trạng thái | ✅ Hoàn thành |
| 6 | Validation input | ✅ Hoàn thành |
| 7 | Widget riêng (TodoItemWidget) | ✅ Hoàn thành |
| 8 | UI hiện đại (Material 3) | ✅ Hoàn thành |

---

